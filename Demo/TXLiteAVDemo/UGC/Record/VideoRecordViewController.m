
#import <Foundation/Foundation.h>
#import "VideoRecordViewController.h"
//#import "TCVideoPublishController.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MPMediaPickerController.h>
#import "TXColor.h"
#import "UIView+Additions.h"
#import "BeautySettingPanel.h"
#import "VideoRecordProcessView.h"
#import "MBProgressHUD.h"
#import "SmallButton.h"
#import "RecordSideButtonGroup.h"

#ifndef UGC_SMART
#import "VideoRecordMusicView.h"
typedef NS_ENUM(NSInteger,SpeedMode)
{
    SpeedMode_VerySlow,
    SpeedMode_Slow,
    SpeedMode_Standard,
    SpeedMode_Quick,
    SpeedMode_VeryQuick,
};
#endif

#define BUTTON_RECORD_SIZE          75
#define BUTTON_CONTROL_SIZE         32
#define BUTTON_MASK_HEIGHT          170
#define BUTTON_PROGRESS_HEIGHT      3
#define BUTTON_SPEED_WIDTH          45
#define BUTTON_SPEED_HEIGHT         15
#define BUTTON_SPEED_INTERVAL       30
#define BUTTON_SPEED_COUNT          5
#define MAX_RECORD_TIME             60
#define MIN_RECORD_TIME             5
#define RightSideButtonLabelColor   UIColor.whiteColor

@implementation RecordMusicInfo

@end

@interface VideoRecordViewController()<
TXUGCRecordListener
,BeautyLoadPituDelegate
,BeautySettingPanelDelegate
#ifndef UGC_SMART
,TXVideoCustomProcessDelegate
,MPMediaPickerControllerDelegate
,VideoRecordMusicViewDelegate
#endif
>
{
    BOOL                            _cameraFront;
    BOOL                            _cameraPreviewing;
    BOOL                            _videoRecording;
    BOOL                            _isPaused;
    BOOL                            _isFlash;
    RecordSideButtonGroup          *_btnRatioGroup;
    UIView *                        _bottomMask;
    UIView *                        _videoRecordView;
    UIButton *                      _btnDelete;
    UIButton *                      _btnStartRecord;
    UIButton *                      _btnFlash;
    UIButton *                      _btnCamera;
    UIButton *                      _btnBeauty;
#ifndef UGC_SMART
    UIButton *                      _btnMusic;
#endif
    UIButton *                      _btnTorch;
    UIButton *                      _btnDone;
    UILabel *                       _recordTimeLabel;
    UISegmentedControl *            _speedOptionControl;
    CGFloat                         _currentRecordTime;
    
    BeautySettingPanel*             _vBeauty;
    
    BOOL                            _navigationBarHidden;
    BOOL                            _statusBarHidden;
    BOOL                            _appForeground;
    
    UIDeviceOrientation             _deviceOrientation;// 未初始化
    
    AVAsset*                        _BGMAsset;
    double                          _BGMDuration;
    
    VideoRecordProcessView *        _progressView;
#ifndef UGC_SMART
    VideoRecordMusicView *          _musicView;
    SpeedMode                       _speedMode;
#endif
    VideoRecordConfig*              _videoConfig;
    TXVideoAspectRatio              _aspectRatio;
    BOOL                            _isBackDelete;
    BOOL                            _bgmRecording;
    BOOL                            _bgmLoop;
    int                             _deleteCount;
    float                           _zoom;
    
    CGFloat                         _bgmBeginTime;
    BOOL                            _receiveBGMProgress;
    
    MBProgressHUD*                  _hub;
}
@end

@implementation VideoRecordViewController

-(instancetype)initWithConfigure:(VideoRecordConfig*)configure;
{
    self = [super init];
    if (self)
    {
        _videoConfig = configure;
        _cameraFront = YES;
        _cameraPreviewing = NO;
        _videoRecording = NO;
        _bgmRecording = NO;
        _bgmLoop = YES;
        _receiveBGMProgress = YES;
#ifndef UGC_SMART
        _speedMode = SpeedMode_Standard;
#endif
        _zoom        = 1.0;
        _bgmBeginTime = 0;
        _currentRecordTime = 0;

#ifndef UGC_SMART
       _speedMode = SpeedMode_Standard;
#endif
        _aspectRatio = configure.videoRatio;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onAudioSessionEvent:)
                                                     name:AVAudioSessionInterruptionNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarOrientationChanged:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.blackColor;
    [self initUI];
    [self initBeautyUI];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _navigationBarHidden = self.navigationController.navigationBar.hidden;
    self.navigationController.navigationBar.hidden = YES;
    
    // 禁用返回手势
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
    
    if (_cameraPreviewing == NO) {
        [self startCameraPreview];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.hidden = _navigationBarHidden;
    
    // 开启返回手势
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    }
}

-(void)onBtnPopClicked
{
    [self stopCameraPreview];
    [self stopVideoRecord];
    [TXUGCRecord shareInstance].recordDelegate = nil;
    [[TXUGCRecord shareInstance].partsManager deleteAllParts];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - NSNotificationHandler
-(void)onAudioSessionEvent:(NSNotification*)notification
{
    NSDictionary *info = notification.userInfo;
    AVAudioSessionInterruptionType type = [info[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
    if (type == AVAudioSessionInterruptionTypeBegan) {
        // 在10.3及以上的系统上，分享跳其它app后再回来会收到AVAudioSessionInterruptionWasSuspendedKey的通知，不处理这个事件。
        if ([info objectForKey:@"AVAudioSessionInterruptionWasSuspendedKey"]) {
            return;
        }
        if (!_isPaused && _videoRecording)
            [self onBtnRecordStartClicked];
    }
}

- (void)onAppWillResignActive:(UIApplication*)app
{
    [[[TXUGCRecord shareInstance] getBeautyManager] setMotionMute:YES];

    if (!_isPaused && _videoRecording)
        [self onBtnRecordStartClicked];
    
    if (!_vBeauty.hidden) {
        [self onBtnBeautyClicked];
    }
    
}

- (void)onAppDidBecomeActive:(UIApplication*)app
{
    _appForeground = YES;
    [[[TXUGCRecord shareInstance] getBeautyManager] setMotionMute:NO];
}

#pragma mark ---- Common UI ----
-(void)initUI
{
    self.title = @"";
    _videoRecordView = [[UIView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:_videoRecordView];
    
    UIPinchGestureRecognizer* pinchGensture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    [_videoRecordView addGestureRecognizer:pinchGensture];
    
    CGFloat top = [UIApplication sharedApplication].statusBarFrame.size.height + 25;
    CGFloat centerY = top + BUTTON_CONTROL_SIZE / 2;
    // 30 + BUTTON_CONTROL_SIZE / 2 - 5
    UIButton *btnPop = [SmallButton buttonWithType:UIButtonTypeCustom];
    btnPop.bounds = CGRectMake(0, 0, BUTTON_CONTROL_SIZE, BUTTON_CONTROL_SIZE);
    btnPop.center = CGPointMake(17, centerY);
    [btnPop setImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
    [btnPop addTarget:self action:@selector(onBtnPopClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnPop];

    UIButton *btnRatio169 = [SmallButton buttonWithType:UIButtonTypeCustom];
    [btnRatio169 setImage:[UIImage imageNamed:@"169"] forState:UIControlStateNormal];
    [btnRatio169 setImage:[UIImage imageNamed:@"169_hover"] forState:UIControlStateHighlighted];
    btnRatio169.tag = VIDEO_ASPECT_RATIO_9_16;

    UIButton *btnRatio916 = [SmallButton buttonWithType:UIButtonTypeCustom];
    [btnRatio916 setImage:[UIImage imageNamed:@"916"] forState:UIControlStateNormal];
    [btnRatio916 setImage:[UIImage imageNamed:@"916_hover"] forState:UIControlStateHighlighted];
    btnRatio916.tag = VIDEO_ASPECT_RATIO_16_9;

    UIButton *btnRatio11 = [SmallButton buttonWithType:UIButtonTypeCustom];
    [btnRatio11 setImage:[UIImage imageNamed:@"11"] forState:UIControlStateNormal];
    [btnRatio11 setImage:[UIImage imageNamed:@"11_hover"] forState:UIControlStateHighlighted];
    btnRatio11.tag = VIDEO_ASPECT_RATIO_1_1;

    UIButton *btnRatio43 = [SmallButton buttonWithType:UIButtonTypeCustom];
    [btnRatio43 setImage:[UIImage imageNamed:@"43"] forState:UIControlStateNormal];
    [btnRatio43 setImage:[UIImage imageNamed:@"43_hover"] forState:UIControlStateHighlighted];
    btnRatio43.tag = VIDEO_ASPECT_RATIO_3_4;

    UIButton *btnRatio34 = [SmallButton buttonWithType:UIButtonTypeCustom];
    [btnRatio34 setImage:[UIImage imageNamed:@"34"] forState:UIControlStateNormal];
    [btnRatio34 setImage:[UIImage imageNamed:@"34_hover"] forState:UIControlStateHighlighted];
    btnRatio34.tag = VIDEO_ASPECT_RATIO_4_3;

    _btnRatioGroup = [[RecordSideButtonGroup alloc] initWithButtons:@[btnRatio43, btnRatio34, btnRatio11, btnRatio916, btnRatio169]
                                                         buttonSize:CGSizeMake(BUTTON_CONTROL_SIZE, BUTTON_CONTROL_SIZE)
                                                            spacing:30];
    [_btnRatioGroup addTarget:self action:@selector(onBtnRatioClicked:) forControlEvents:UIControlEventValueChanged];
    CGRect frame = _btnRatioGroup.frame;
    frame.size = _btnRatioGroup.intrinsicContentSize;
    frame.origin = CGPointMake(CGRectGetWidth(self.view.bounds) - CGRectGetWidth(frame) - 20, top);
    _btnRatioGroup.frame = frame;
    [self.view addSubview:_btnRatioGroup];
    [_btnRatioGroup.buttons enumerateObjectsUsingBlock:^(UIButton * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.tag == _videoConfig.videoRatio) {
            _btnRatioGroup.selectedIndex = idx;
            *stop = YES;
        }
    }];

    CGFloat x = CGRectGetWidth(self.view.bounds) - 20 - BUTTON_CONTROL_SIZE;
    UILabel *ratioLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, _btnRatioGroup.bottom + 5, BUTTON_CONTROL_SIZE, 11)];
    ratioLabel.text = @"屏比";
    ratioLabel.textColor = RightSideButtonLabelColor;
    ratioLabel.font = [UIFont systemFontOfSize:12];
    ratioLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:ratioLabel];
    
    _btnBeauty = [SmallButton buttonWithType:UIButtonTypeCustom];
    _btnBeauty.frame = CGRectMake(x, _btnRatioGroup.top + 72, BUTTON_CONTROL_SIZE, BUTTON_CONTROL_SIZE);
    [_btnBeauty setImage:[UIImage imageNamed:@"beauty_record"] forState:UIControlStateNormal];
    [_btnBeauty setImage:[UIImage imageNamed:@"beauty_hover"] forState:UIControlStateHighlighted];
    [_btnBeauty addTarget:self action:@selector(onBtnBeautyClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnBeauty];
    
    UILabel *beautyLabel = [[UILabel alloc] initWithFrame:CGRectMake(_btnBeauty.x, _btnBeauty.bottom + 10, BUTTON_CONTROL_SIZE, 11)];
    beautyLabel.text = @"美颜";
    beautyLabel.textColor = RightSideButtonLabelColor;
    beautyLabel.font = [UIFont systemFontOfSize:12];
    beautyLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:beautyLabel];
    
#ifndef UGC_SMART
    _btnMusic = [SmallButton buttonWithType:UIButtonTypeCustom];
    _btnMusic.frame = CGRectOffset(_btnBeauty.frame, 0, 72);
    [_btnMusic setImage:[UIImage imageNamed:@"backMusic"] forState:UIControlStateNormal];
    [_btnMusic setImage:[UIImage imageNamed:@"backMusic_hover"] forState:UIControlStateHighlighted];
    [_btnMusic addTarget:self action:@selector(onBtnMusicClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnMusic];
    
    UILabel *musicLabel = [[UILabel alloc] initWithFrame:CGRectMake(_btnMusic.x, _btnMusic.bottom + 10, BUTTON_CONTROL_SIZE, 11)];
    musicLabel.text = @"音乐";
    musicLabel.textColor = RightSideButtonLabelColor;
    musicLabel.font = [UIFont systemFontOfSize:12];
    musicLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:musicLabel];
    
    _musicView = [[VideoRecordMusicView alloc] initWithFrame:CGRectMake(0, self.view.bottom - 260, self.view.width, 260)];
    _musicView.delegate = self;
    _musicView.hidden = YES;
    [self.view addSubview:_musicView];
#endif
    
    _bottomMask = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - BUTTON_MASK_HEIGHT, self.view.frame.size.width, BUTTON_MASK_HEIGHT)];
    [_bottomMask setBackgroundColor:UIColor.blackColor];
    [_bottomMask setAlpha:0.3];
    [self.view addSubview:_bottomMask];
    
    _btnStartRecord = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, BUTTON_RECORD_SIZE, BUTTON_RECORD_SIZE)];
    _btnStartRecord.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height - BUTTON_RECORD_SIZE + 10);
    [_btnStartRecord setImage:[UIImage imageNamed:@"start_record"] forState:UIControlStateNormal];
    [_btnStartRecord setBackgroundImage:[UIImage imageNamed:@"start_ring"] forState:UIControlStateNormal];
    [_btnStartRecord addTarget:self action:@selector(onBtnRecordStartClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnStartRecord];
    
    _btnFlash = [UIButton buttonWithType:UIButtonTypeCustom];
    _btnFlash.bounds = CGRectMake(0, 0, BUTTON_CONTROL_SIZE, BUTTON_CONTROL_SIZE);
    _btnFlash.center = CGPointMake(25 + BUTTON_CONTROL_SIZE / 2, _btnStartRecord.center.y);
    if (_cameraFront) {
        [_btnFlash setImage:[UIImage imageNamed:@"openFlash_disable"] forState:UIControlStateNormal];
        _btnFlash.enabled = NO;
    }else{
        [_btnFlash setImage:[UIImage imageNamed:@"closeFlash"] forState:UIControlStateNormal];
        [_btnFlash setImage:[UIImage imageNamed:@"closeFlash_hover"] forState:UIControlStateHighlighted];
        _btnFlash.enabled = YES;
    }
    [_btnFlash addTarget:self action:@selector(onBtnFlashClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnFlash];
    
    _btnCamera = [UIButton buttonWithType:UIButtonTypeCustom];
    _btnCamera.bounds = CGRectMake(0, 0, BUTTON_CONTROL_SIZE, BUTTON_CONTROL_SIZE);
    _btnCamera.center = CGPointMake(_btnFlash.right + 25 + BUTTON_CONTROL_SIZE / 2, _btnStartRecord.center.y);
    //    _btnCamera.frame = CGRectOffset(_btnMusic.frame, 0, 72);
    [_btnCamera setImage:[UIImage imageNamed:@"camera_record"] forState:UIControlStateNormal];
    [_btnCamera setImage:[UIImage imageNamed:@"camera_hover"] forState:UIControlStateHighlighted];
    [_btnCamera addTarget:self action:@selector(onBtnCameraClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnCamera];
    
    _btnDone = [UIButton buttonWithType:UIButtonTypeCustom];
    _btnDone.bounds = CGRectMake(0, 0, BUTTON_CONTROL_SIZE, BUTTON_CONTROL_SIZE);
    _btnDone.center = CGPointMake(CGRectGetWidth(self.view.bounds) - 25 - BUTTON_CONTROL_SIZE / 2 , _btnStartRecord.center.y);
    [_btnDone setImage:[UIImage imageNamed:@"confirm_disable"] forState:UIControlStateNormal];
    [_btnDone setTitleColor:UIColor.brownColor forState:UIControlStateNormal];
    [_btnDone addTarget:self action:@selector(onBtnDoneClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnDone];
    _btnDone.enabled = NO;
    
    _btnDelete = [UIButton buttonWithType:UIButtonTypeCustom];
    _btnDelete.bounds = CGRectMake(0, 0, BUTTON_CONTROL_SIZE, BUTTON_CONTROL_SIZE);
    _btnDelete.center = CGPointMake(_btnDone.left - 25 - BUTTON_CONTROL_SIZE / 2, _btnStartRecord.center.y);
    [_btnDelete setImage:[UIImage imageNamed:@"backDelete"] forState:UIControlStateNormal];
    [_btnDelete setImage:[UIImage imageNamed:@"backDelete_hover"] forState:UIControlStateHighlighted];
    [_btnDelete addTarget:self action:@selector(onBtnDeleteClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnDelete];
    
    _progressView = [[VideoRecordProcessView alloc] initWithFrame:CGRectMake(0,_bottomMask.y - BUTTON_PROGRESS_HEIGHT + 0.5, self.view.frame.size.width, BUTTON_PROGRESS_HEIGHT)];
    _progressView.backgroundColor = [UIColor blackColor];
    _progressView.alpha = 0.4;
    [self.view addSubview:_progressView];
    
    _recordTimeLabel = [[UILabel alloc]init];
    _recordTimeLabel.frame = CGRectMake(0, 0, 100, 100);
    [_recordTimeLabel setText:@"00:00"];
    _recordTimeLabel.font = [UIFont systemFontOfSize:10];
    _recordTimeLabel.textColor = [UIColor whiteColor];
    _recordTimeLabel.textAlignment = NSTextAlignmentLeft;
    [_recordTimeLabel sizeToFit];
    _recordTimeLabel.center = CGPointMake(CGRectGetMaxX(_progressView.frame) - _recordTimeLabel.frame.size.width / 2, _progressView.frame.origin.y - _recordTimeLabel.frame.size.height);
    [self.view addSubview:_recordTimeLabel];
#ifndef UGC_SMART
    [self createSpeedControl];
    
    UIPanGestureRecognizer* panGensture = [[UIPanGestureRecognizer alloc] initWithTarget:self action: @selector (handlePanSlide:)];
    [self.view addGestureRecognizer:panGensture];
    //    UISwipeGestureRecognizer* swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    //    [self.view addGestureRecognizer:swipeGesture];
    //    [panGensture requireGestureRecognizerToFail:swipeGesture];
#endif
}

#ifndef UGC_SMART
//加速录制
-(void)createSpeedControl
{
    NSMutableArray *items = [[NSMutableArray alloc] initWithCapacity:BUTTON_SPEED_COUNT];
    for(int i = 0 ; i < BUTTON_SPEED_COUNT ; i ++) {
        [items addObject:[self getSpeedText:i]];
    }
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:items];
    _speedOptionControl = segmentedControl;
    segmentedControl.selectedSegmentIndex = SpeedMode_Standard;
    segmentedControl.frame = CGRectMake(0, self.view.bounds.size.height - 146 - BUTTON_SPEED_HEIGHT, self.view.bounds.size.width, BUTTON_SPEED_HEIGHT);
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(1, segmentedControl.frame.size.height), NO, 0.0);
    UIImage *blank = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [segmentedControl setDividerImage:blank forLeftSegmentState:UIControlStateNormal rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [segmentedControl setBackgroundImage:blank forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    
    [segmentedControl addTarget:self action:@selector(onSpeedChanged:) forControlEvents:UIControlEventValueChanged];
    [segmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName: UIColor.whiteColor,
                                               NSFontAttributeName: [UIFont systemFontOfSize:15]}
                                    forState:UIControlStateNormal];
    [segmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName: TXColor.cyan,
                                               NSFontAttributeName: [UIFont fontWithName:@"Helvetica-Bold" size:15]}
                                    forState:UIControlStateSelected];
    [self.view addSubview:segmentedControl];
}

-(NSString *)getSpeedText:(SpeedMode)speedMode
{
    NSString *text = nil;
    switch (speedMode) {
        case SpeedMode_VerySlow:
            text = @"极慢";
            break;
        case SpeedMode_Slow:
            text = @"慢";
            break;
        case SpeedMode_Standard:
            text = @"标准";
            break;
        case SpeedMode_Quick:
            text = @"快";
            break;
        case SpeedMode_VeryQuick:
            text = @"极快";
            break;
        default:
            break;
    }
    return text;
}

#endif

- (void)handlePinch:(UIPinchGestureRecognizer*)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan || recognizer.state == UIGestureRecognizerStateChanged) {
        [[TXUGCRecord shareInstance] setZoom:MIN(MAX(1.0, _zoom * recognizer.scale),5.0)];
    }else if (recognizer.state == UIGestureRecognizerStateEnded){
        _zoom = MIN(MAX(1.0, _zoom * recognizer.scale),5.0);
        recognizer.scale = 1;
    }
}

-(void)onBtnRatioClicked:(RecordSideButtonGroup *)sender
{
    _aspectRatio = sender.buttons[sender.selectedIndex].tag;
    [[TXUGCRecord shareInstance] setAspectRatio:_aspectRatio];
}

#ifndef UGC_SMART
- (void)onBtnMusicClicked
{
    _musicView.hidden = !_musicView.hidden;
    _vBeauty.hidden = YES;
    [self hideBottomView:!_musicView.hidden];
}

- (void)onSpeedChanged:(UISegmentedControl *)segmentedControl
{
    _speedMode = segmentedControl.selectedSegmentIndex;
}

-(void)setSpeedRate{
    switch (_speedMode) {
        case SpeedMode_VerySlow:
            [[TXUGCRecord shareInstance] setRecordSpeed:VIDEO_RECORD_SPEED_SLOWEST];
            break;
        case SpeedMode_Slow:
            [[TXUGCRecord shareInstance] setRecordSpeed:VIDEO_RECORD_SPEED_SLOW];
            break;
        case SpeedMode_Standard:
            [[TXUGCRecord shareInstance] setRecordSpeed:VIDEO_RECORD_SPEED_NOMAL];
            break;
        case SpeedMode_Quick:
            [[TXUGCRecord shareInstance] setRecordSpeed:VIDEO_RECORD_SPEED_FAST];
            break;
        case SpeedMode_VeryQuick:
            [[TXUGCRecord shareInstance] setRecordSpeed:VIDEO_RECORD_SPEED_FASTEST];
            break;
        default:
            break;
    }
}
#endif

-(void)onBtnFlashClicked
{
    if (_isFlash) {
        [_btnFlash setImage:[UIImage imageNamed:@"closeFlash"] forState:UIControlStateNormal];
        [_btnFlash setImage:[UIImage imageNamed:@"closeFlash_hover"] forState:UIControlStateHighlighted];
    }else{
        [_btnFlash setImage:[UIImage imageNamed:@"openFlash"] forState:UIControlStateNormal];
        [_btnFlash setImage:[UIImage imageNamed:@"openFlash_hover"] forState:UIControlStateHighlighted];
    }
    _isFlash = !_isFlash;
    [[TXUGCRecord shareInstance] toggleTorch:_isFlash];
}

-(void)onBtnDeleteClicked
{
    if (_videoRecording && !_isPaused) {
        [self onBtnRecordStartClicked];
    }
    if (0 == _deleteCount) {
        [_progressView prepareDeletePart];
    }else{
        [_progressView comfirmDeletePart];
        [[TXUGCRecord shareInstance].partsManager deleteLastPart];
        _isBackDelete = YES;
#ifndef UGC_SMART
        if ([TXUGCRecord shareInstance].partsManager.getVideoPathList.count ==0) {
            [[TXUGCRecord shareInstance] setRecordSpeed:VIDEO_RECORD_SPEED_NOMAL];
        }
#endif
    }
    if (2 == ++ _deleteCount) {
        _deleteCount = 0;
    }
}

-(void)onBtnRecordStartClicked
{
    if (!_videoRecording)
    {
        [self startVideoRecord];
    }
    else
    {
        if (_isPaused) {
#ifndef UGC_SMART
            [self setSpeedRate];
            
            if (_bgmRecording) {
                [self resumeBGM];
            }else{
                [self playBGM:_bgmBeginTime];
                _bgmRecording = YES;
            }
#endif
            [[TXUGCRecord shareInstance] resumeRecord];
            
            [_btnStartRecord setImage:[UIImage imageNamed:@"pause_record"] forState:UIControlStateNormal];
            [_btnStartRecord setBackgroundImage:[UIImage imageNamed:@"pause_ring"] forState:UIControlStateNormal];
            _btnStartRecord.bounds = CGRectMake(0, 0, BUTTON_RECORD_SIZE * 0.85, BUTTON_RECORD_SIZE * 0.85);
            
            if (_deleteCount == 1) {
                [_progressView cancelDelete];
                _deleteCount = 0;
            }
#ifndef UGC_SMART_btnStartRecord
            _speedOptionControl.hidden = YES;
#endif
            _isPaused = NO;
        }
        else {
            _btnDelete.enabled = NO;
            [[TXUGCRecord shareInstance] pauseRecord:^{
                _btnDelete.enabled = YES;
            }];
            [_progressView pause];
            _isPaused = YES;
            
            [_btnStartRecord setImage:[UIImage imageNamed:@"start_record"] forState:UIControlStateNormal];
            [_btnStartRecord setBackgroundImage:[UIImage imageNamed:@"start_ring"] forState:UIControlStateNormal];
            _btnStartRecord.bounds = CGRectMake(0, 0, BUTTON_RECORD_SIZE, BUTTON_RECORD_SIZE);
#ifndef UGC_SMART
            [self pauseBGM];
            _speedOptionControl.hidden = NO;
#endif         
        }
    }
}

- (void)onBtnDoneClicked
{
    if (!_videoRecording)
        return;
    
    [self stopVideoRecord];
}

- (void)_addWatermark:(TXUGCCustomConfig *)param {
    CGFloat videoWidth, videoHeight;
    switch (param.videoResolution) {
        case VIDEO_RESOLUTION_360_640:
            videoWidth = 360;
            videoHeight = 640;
            break;
        case VIDEO_RESOLUTION_540_960:
            videoWidth = 540;
            videoHeight = 960;
            break;
        case VIDEO_RESOLUTION_720_1280:
            videoWidth = 720;
            videoHeight = 1280;
            break;
        case VIDEO_RESOLUTION_1080_1920:
            videoWidth = 1080;
            videoHeight = 1920;
            break;
    }
    UIImage *cloud = [UIImage imageNamed:@"tcloud_symbol"];
    CGFloat imageWidth;
    if (videoWidth > videoHeight) {
        imageWidth = 0.08*videoHeight;
    } else {
        imageWidth = 0.08*videoWidth;
    }
    CGFloat imageHeight = imageWidth / cloud.size.width * cloud.size.height;

    NSDictionary *textAttribute = @{NSFontAttributeName:[UIFont boldSystemFontOfSize:imageHeight],
                                    NSForegroundColorAttributeName:[UIColor whiteColor]};
    CGSize textSize = [@"腾讯云" sizeWithAttributes:textAttribute];
    CGSize canvasSize = CGSizeMake(ceil(imageWidth + textSize.width), ceil(MAX(imageHeight,textSize.height) + imageWidth* 0.05));
    UIGraphicsBeginImageContext(canvasSize);
    [cloud drawInRect:CGRectMake(0, (canvasSize.height - imageHeight) / 2, imageWidth, imageHeight)];
    [@"腾讯云" drawAtPoint:CGPointMake(imageWidth*1.05, (canvasSize.height - textSize.height) / 2)
         withAttributes:textAttribute];
    UIImage *waterimage = UIGraphicsGetImageFromCurrentImageContext(); //[UIImage imageNamed:@"watermark"];
    UIGraphicsEndImageContext();

    [[TXUGCRecord shareInstance] setWaterMark:waterimage normalizationFrame:CGRectMake(0.01, 0.01, canvasSize.width / videoWidth, 0)];
}

-(void)startCameraPreview
{
    
    if (_cameraPreviewing == NO)
    {
        //简单设置
        //        TXUGCSimpleConfig * param = [[TXUGCSimpleConfig alloc] init];
        //        param.videoQuality = VIDEO_QUALITY_MEDIUM;
        //        [[TXUGCRecord shareInstance] startCameraSimple:param preview:_videoRecordView];
        //自定义设置
        
        TXUGCCustomConfig * param = [[TXUGCCustomConfig alloc] init];
        param.videoResolution =  _videoConfig.videoResolution;
        param.videoFPS = _videoConfig.fps;
        param.videoBitratePIN = _videoConfig.bps;
        param.GOP = _videoConfig.gop;
        param.enableAEC = _videoConfig.enableAEC;
        param.minDuration = MIN_RECORD_TIME;
        param.maxDuration = MAX_RECORD_TIME;
        [[TXUGCRecord shareInstance] startCameraCustom:param preview:_videoRecordView];
        [[TXUGCRecord shareInstance] setAspectRatio: _aspectRatio];
        [[TXUGCRecord shareInstance] setVideoRenderMode:VIDEO_RENDER_MODE_ADJUST_RESOLUTION];
        //[[TXUGCRecord shareInstance] setZoom:2.5];
#ifndef UGC_SMART
        [TXUGCRecord shareInstance].videoProcessDelegate = self;
//        [self _addWatermark:param];
#endif
        [_vBeauty resetValues];
        _cameraPreviewing = YES;
    }
    
}


/* 各种情况下的横竖屏推流 参数设置
 //activity竖屏模式，竖屏推流
 [[TXUGCRecord shareInstance] setHomeOrientation:VIDEO_HOME_ORIENTATION_DOWN];
 [[TXUGCRecord shareInstance] setRenderRotation:0];
 
 //activity竖屏模式，home在右横屏推流
 [[TXUGCRecord shareInstance] setHomeOrientation:VIDOE_HOME_ORIENTATION_RIGHT];
 [[TXUGCRecord shareInstance] setRenderRotation:90];
 
 //activity竖屏模式，home在左横屏推流
 [[TXUGCRecord shareInstance] setHomeOrientation:VIDEO_HOME_ORIENTATION_LEFT];
 [[TXUGCRecord shareInstance] setRenderRotation:270];
 
 //activity横屏模式，home在右横屏推流 注意：渲染view要跟着activity旋转
 [[TXUGCRecord shareInstance] setHomeOrientation:VIDOE_HOME_ORIENTATION_RIGHT];
 [[TXUGCRecord shareInstance] setRenderRotation:0];
 
 //activity横屏模式，home在左横屏推流 注意：渲染view要跟着activity旋转
 [[TXUGCRecord shareInstance] setHomeOrientation:VIDEO_HOME_ORIENTATION_LEFT];
 [[TXUGCRecord shareInstance] setRenderRotation:0];
 */

- (void)statusBarOrientationChanged:(NSNotification *)note  {
    switch ([[UIDevice currentDevice] orientation]) {
        case UIDeviceOrientationPortrait:        //activity竖屏模式，竖屏录制
        {
            if (_deviceOrientation != UIDeviceOrientationPortrait) {
                
                [[TXUGCRecord shareInstance] setHomeOrientation:VIDEO_HOME_ORIENTATION_DOWN];
                [[TXUGCRecord shareInstance] setRenderRotation:0];
            }
        }
            break;
        case UIDeviceOrientationLandscapeLeft:   //activity横屏模式，home在右横屏录制 注意：渲染view要跟着activity旋转
        {
            if (_deviceOrientation != UIDeviceOrientationLandscapeLeft) {
                [[TXUGCRecord shareInstance] setHomeOrientation:VIDOE_HOME_ORIENTATION_RIGHT];
                [[TXUGCRecord shareInstance] setRenderRotation:0];
            }
            
        }
            break;
        case UIDeviceOrientationLandscapeRight:   //activity横屏模式，home在左横屏录制 注意：渲染view要跟着activity旋转
        {
            if (_deviceOrientation != UIDeviceOrientationLandscapeRight) {
                
                [[TXUGCRecord shareInstance] setHomeOrientation:VIDEO_HOME_ORIENTATION_LEFT];
                [[TXUGCRecord shareInstance] setRenderRotation:0];
            }
        }
            break;
        default:
            break;
    }
}


-(void)stopCameraPreview
{
    if (_cameraPreviewing == YES)
    {
        [[TXUGCRecord shareInstance] stopCameraPreview];
#ifndef UGC_SMART
        [TXUGCRecord shareInstance].videoProcessDelegate = nil;
#endif
        _cameraPreviewing = NO;
    }
}

-(void)startVideoRecord
{
    [self refreshRecordTime:0];
    [self startCameraPreview];
#ifndef UGC_SMART
    [self setSpeedRate];
#endif
    [TXUGCRecord shareInstance].recordDelegate = self;
    int result = [[TXUGCRecord shareInstance] startRecord];
    //自定义目录
    //    int result = [[TXUGCRecord shareInstance] startRecord:[NSTemporaryDirectory() stringByAppendingPathComponent:@"outRecord.mp4"] videoPartsFolder:NSTemporaryDirectory()coverPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"outRecord.jpg"]];
    if(0 != result)
    {
        if(-3 == result) [self alert:@"启动录制失败" msg:@"请检查摄像头权限是否打开"];
        else if(-4 == result) [self alert:@"启动录制失败" msg:@"请检查麦克风权限是否打开"];
        else if(-5 == result) [self alert:@"启动录制失败" msg:@"licence 验证失败"];
    }else{
#ifndef UGC_SMART
        //如果设置了BGM，播放BGM
        [self playBGM:_bgmBeginTime];
#endif
        
        //初始化录制状态
        _bgmRecording = YES;
        _videoRecording = YES;
        _isPaused = NO;
        
        //录制过程中不能切换分辨率
        _btnRatioGroup.enabled = NO;

#ifndef UGC_SMART
        _speedOptionControl.hidden = YES;
#endif
        [_btnStartRecord setImage:[UIImage imageNamed:@"pause_record"] forState:UIControlStateNormal];
        [_btnStartRecord setBackgroundImage:[UIImage imageNamed:@"pause_ring"] forState:UIControlStateNormal];
        _btnStartRecord.bounds = CGRectMake(0, 0, BUTTON_RECORD_SIZE * 0.85, BUTTON_RECORD_SIZE * 0.85);
    }
}

-(void)alert:(NSString *)title msg:(NSString *)msg
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:msg delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
    [alert show];
}

-(void)stopVideoRecord
{
    [[TXUGCRecord shareInstance] stopRecord];
    [self resetVideoUI];
}

-(void)resetVideoUI
{
    [_progressView deleteAllPart];
    [_btnStartRecord setImage:[UIImage imageNamed:@"start_record"] forState:UIControlStateNormal];
    [_btnStartRecord setBackgroundImage:[UIImage imageNamed:@"start_ring"] forState:UIControlStateNormal];
    _btnStartRecord.bounds = CGRectMake(0, 0, BUTTON_RECORD_SIZE, BUTTON_RECORD_SIZE);
    
#ifndef UGC_SMART
    [self resetSpeedBtn];
    [_musicView resetUI];
    _btnMusic.enabled = YES;
#endif

    _btnRatioGroup.enabled = YES;
    _isPaused = NO;
    _videoRecording = NO;
}

#ifndef UGC_SMART
-(void)resetSpeedBtn{
    _speedOptionControl.hidden = NO;
    _speedOptionControl.selectedSegmentIndex = SpeedMode_Standard;
    _speedMode = SpeedMode_Standard;
}
#endif

-(void)onBtnCameraClicked
{
    _cameraFront = !_cameraFront;
    [[TXUGCRecord shareInstance] switchCamera:_cameraFront];
    if (_cameraFront) {
        [_btnFlash setImage:[UIImage imageNamed:@"openFlash_disable"] forState:UIControlStateNormal];
        _btnFlash.enabled = NO;
    }else{
        if (_isFlash) {
            [_btnFlash setImage:[UIImage imageNamed:@"openFlash"] forState:UIControlStateNormal];
            [_btnFlash setImage:[UIImage imageNamed:@"openFlash_hover"] forState:UIControlStateHighlighted];
        }else{
            [_btnFlash setImage:[UIImage imageNamed:@"closeFlash"] forState:UIControlStateNormal];
            [_btnFlash setImage:[UIImage imageNamed:@"closeFlash_hover"] forState:UIControlStateHighlighted];
        }
        _btnFlash.enabled = YES;
    }
    [[TXUGCRecord shareInstance] toggleTorch:_isFlash];
}

-(void)onBtnBeautyClicked
{
    _vBeauty.hidden = !_vBeauty.hidden;
#ifndef UGC_SMART
    _musicView.hidden = YES;
#endif
    [self hideBottomView:!_vBeauty.hidden];
}

- (void)hideBottomView:(BOOL)bHide
{
    if (_videoRecording && !_isPaused) {
        _speedOptionControl.hidden = YES;
    }else{
        _speedOptionControl.hidden = bHide;
    }
    _btnFlash.hidden = bHide;
    _btnCamera.hidden = bHide;
    _btnStartRecord.hidden = bHide;
    _btnDelete.hidden = bHide;
    _btnDone.hidden = bHide;
    _progressView.hidden = bHide;
    _recordTimeLabel.hidden = bHide;
    _bottomMask.hidden = bHide;
}

- (void) touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint _touchPoint = [touch locationInView:self.view];
    if (!_vBeauty.hidden) {
        if (NO == CGRectContainsPoint(_vBeauty.frame, _touchPoint))
        {
            [self onBtnBeautyClicked];
        }
    }
#ifndef UGC_SMART    
    if (!_musicView.hidden) {
        if (NO == CGRectContainsPoint(_musicView.frame, _touchPoint))
        {
            [self onBtnMusicClicked];
        }
    }
#endif
}

#ifndef UGC_SMART
// UGC_Smart无背景音、P图
#pragma mark - VideoRecordMusicViewDelegate
-(void)onBtnMusicSelected
{
    MPMediaPickerController *mpc = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeAnyAudio];
    if ([mpc respondsToSelector:@selector(setShowsItemsWithProtectedAssets:)]) {
        mpc.showsItemsWithProtectedAssets = NO;
    }
    mpc.delegate = self;
    mpc.editing = YES;
    mpc.allowsPickingMultipleItems = NO;
    [self presentViewController:mpc animated:YES completion:nil];
    [self onBtnMusicClicked];
}


-(void)onBtnMusicStoped
{
    _BGMAsset = nil;
    _bgmRecording = NO;
    [[TXUGCRecord shareInstance] stopBGM];
    [[TXUGCRecord shareInstance] setBGMAsset:nil];
    if (!_musicView.hidden) {
        [self onBtnMusicClicked];
    }
}

-(void)onBtnMusicLoop:(BOOL)isLoop
{
    _bgmLoop = isLoop;
    [[TXUGCRecord shareInstance] setBGMLoop:isLoop];
}

-(void)onBGMValueChange:(UISlider *)slider
{
    [[TXUGCRecord shareInstance] setBGMVolume:slider.value];
}

-(void)onVoiceValueChange:(UISlider *)slider
{
    [[TXUGCRecord shareInstance] setMicVolume:slider.value];
}

-(void)onBGMPlayBeginChange
{
    _receiveBGMProgress = NO;
}

-(void)onBGMPlayChange:(UISlider *)slider
{
    [self playBGM:slider.value];
    _receiveBGMProgress = YES;
}

-(void)selectEffect:(NSInteger)index
{
    [[TXUGCRecord shareInstance] setReverbType:index];
}

-(void)selectEffect2:(NSInteger)index
{
    [[TXUGCRecord shareInstance] setVoiceChangerType:index];
}

#pragma mark - 背景音乐
#pragma mark - MPMediaPickerControllerDelegate
- (void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection
{
    NSArray *items = mediaItemCollection.items;
    MPMediaItem *songItem = [items objectAtIndex:0];
    NSURL *url = [songItem valueForProperty:MPMediaItemPropertyAssetURL];
    AVAsset *songAsset = [AVAsset assetWithURL:url];
    if (songAsset != nil) {
        [self setBGM:songAsset];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

//点击取消时回调
- (void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)resetBGM {
    _BGMAsset = nil;
    _bgmBeginTime = 0;
    _bgmRecording = YES;
    [[TXUGCRecord shareInstance] setBGMAsset:nil];
    [_musicView setBGMDuration:0];
}

-(void)setBGM:(AVAsset *)asset
{
    _BGMAsset = asset;
    _BGMDuration =  [[TXUGCRecord shareInstance] setBGMAsset:_BGMAsset];
    [_musicView setBGMDuration:_BGMDuration];
    
    //试听音乐这里要把RecordSpeed 设置为VIDEO_RECORD_SPEED_NOMAL，否则音乐可能会出现加速或则慢速播现象
    [[TXUGCRecord shareInstance] setRecordSpeed:VIDEO_RECORD_SPEED_NOMAL];
    
    _bgmRecording = NO;
    if (_cameraPreviewing) {
        [self playBGM:0];
    }
}

-(void)playBGM:(CGFloat)beginTime{
    if (_BGMAsset != nil) {
        [[TXUGCRecord shareInstance] setBGMLoop:_bgmLoop];
        [[TXUGCRecord shareInstance] playBGMFromTime:beginTime toTime:_BGMDuration withBeginNotify:^(NSInteger errCode) {
            
        } withProgressNotify:^(NSInteger progressMS, NSInteger durationMS) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (_receiveBGMProgress) {
                    [_musicView setBGMPlayTime:progressMS / 1000.0];
                }
            });
        } andCompleteNotify:^(NSInteger errCode) {
            
        }];
        _bgmBeginTime = beginTime;
    }
}

-(void)pauseBGM{
    if (_BGMAsset != nil) {
        [[TXUGCRecord shareInstance] pauseBGM];
    }
}

- (void)resumeBGM
{
    if (_BGMAsset != nil) {
        [[TXUGCRecord shareInstance] resumeBGM];
    }
}

#pragma mark - P图下载处理
#pragma mark - BeautyLoadPituDelegate
- (void)onLoadPituStart
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _hub = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        _hub.mode = MBProgressHUDModeText;
        _hub.label.text = @"开始加载资源";
    });
}
- (void)onLoadPituProgress:(CGFloat)progress
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _hub.label.text = [NSString stringWithFormat:@"正在加载资源%d %%",(int)(progress * 100)];
    });
}
- (void)onLoadPituFinished
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _hub.label.text = @"资源加载成功";
        [_hub hideAnimated:YES afterDelay:1];
    });
}
- (void)onLoadPituFailed
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _hub.label.text = @"资源加载失败";
        [_hub hideAnimated:YES afterDelay:1];
    });
}
#endif

#pragma mark - BeautySettingPanelDelegate
- (void)onSetFilter:(UIImage*)filterImage
{
    [[TXUGCRecord shareInstance] setFilter:filterImage];
    //    NSString * path = [[NSBundle mainBundle] pathForResource:@"FilterResource" ofType:@"bundle"];
    //    if (path != nil) {
    //        NSString *path1 = [path stringByAppendingPathComponent:@"white.png"];
    //        UIImage *image1 = [UIImage imageWithContentsOfFile:path1];
    //
    //        NSString *path2 = [path stringByAppendingPathComponent:@"weimei.png"];
    //        UIImage *image2 = [UIImage imageWithContentsOfFile:path2];
    //        [[TXUGCRecord shareInstance] setFilter1:nil filter2:image2 leftRadio:0.5];
    //    }
}

- (void)onSetMixLevel:(float)mixLevel{
    [[TXUGCRecord shareInstance] setSpecialRatio:mixLevel / 10.0];
}

- (void)onSetBeautyStyle:(NSUInteger)beautyStyle beautyLevel:(float)beautyLevel whitenessLevel:(float)whitenessLevel ruddinessLevel:(float)ruddinessLevel{
    TXBeautyManager *manager = [[TXUGCRecord shareInstance] getBeautyManager];
    [manager setBeautyStyle:(TXBeautyStyle)beautyStyle];
    [manager setBeautyLevel:beautyLevel];
    [manager setWhitenessLevel:whitenessLevel];
    [manager setRuddyLevel:ruddinessLevel];
}

#ifndef UGC_SMART
- (void)onSetGreenScreenFile:(NSURL *)file
{
    [[TXUGCRecord shareInstance] setGreenScreenFile:file];
}

- (void)onSelectMotionTmpl:(NSString *)tmplName inDir:(NSString *)tmplDir
{
    [[[TXUGCRecord shareInstance] getBeautyManager] setMotionTmpl:tmplName inDir:tmplDir];
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    if (![super respondsToSelector:aSelector]) {
        return [[[TXUGCRecord shareInstance] getBeautyManager] respondsToSelector:aSelector];
    }
    return YES;
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    return [[TXUGCRecord shareInstance] getBeautyManager];
}

#endif

#pragma mark ---- Video Beauty UI ----
-(void)initBeautyUI
{
    NSUInteger controlHeight = [BeautySettingPanel getHeight];
    _vBeauty = [[BeautySettingPanel alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - controlHeight, self.view.frame.size.width, controlHeight)];
    _vBeauty.hidden = YES;
    _vBeauty.delegate = self;
    _vBeauty.pituDelegate = self;
    [self.view addSubview:_vBeauty];
}

-(void)refreshRecordTime:(float)second
{
    _currentRecordTime = second;
    [_progressView update:_currentRecordTime / MAX_RECORD_TIME];
    NSInteger min = (int)_currentRecordTime / 60;
    NSInteger sec = (int)_currentRecordTime % 60;
    
    [_recordTimeLabel setText:[NSString stringWithFormat:@"%02ld:%02ld", (long)min, (long)sec]];
    [_recordTimeLabel sizeToFit];
}

#pragma mark ---- VideoRecordListener ----
-(void) onRecordProgress:(NSInteger)milliSecond;
{
    [self refreshRecordTime: milliSecond / 1000.0];

    if (milliSecond / 1000 >= MIN_RECORD_TIME) {
        [_btnDone setImage:[UIImage imageNamed:@"confirm"] forState:UIControlStateNormal];
        [_btnDone setImage:[UIImage imageNamed:@"confirm_hover"] forState:UIControlStateHighlighted];
        _btnDone.enabled = YES;
    }else{
        [_btnDone setImage:[UIImage imageNamed:@"confirm_disable"] forState:UIControlStateNormal];
        _btnDone.enabled = NO;
    }
#ifndef UGC_SMART
    _btnMusic.enabled = (milliSecond == 0);
#endif
}

-(void) onRecordComplete:(TXUGCRecordResult*)result;
{
    if (result.retCode == UGC_RECORD_RESULT_OK) {
        if (self.onRecordCompleted) {
            self.onRecordCompleted(result);
        }
        [self stopCameraPreview];
    }
    else if(result.retCode == UGC_RECORD_RESULT_OK_BEYOND_MAXDURATION){
        if (self.onRecordCompleted) {
            self.onRecordCompleted(result);
        }
        [self stopCameraPreview];
        [self stopVideoRecord];
    }
    else if(result.retCode == UGC_RECORD_RESULT_OK_INTERRUPT){
        [self toastTip:@"录制被打断"];
    }
    else if(result.retCode == UGC_RECORD_RESULT_OK_UNREACH_MINDURATION){
        [self toastTip:@"至少要录够5秒"];
    }
    else if(result.retCode == UGC_RECORD_RESULT_FAILED){
        [self toastTip:@"视频录制失败"];
    }

    //分片不再使用的时候请主动删除，否则分片会一直存在本地，导致内存占用越来越大，下次startRecord时候，SDK也会默认加载当前分片
    [[TXUGCRecord shareInstance].partsManager deleteAllParts];
#ifndef UGC_SMART
    [self resetBGM];
#endif
    [self refreshRecordTime:0];
}

#pragma mark - Misc Methods

- (float) heightForString:(UITextView *)textView andWidth:(float)width{
    CGSize sizeToFit = [textView sizeThatFits:CGSizeMake(width, MAXFLOAT)];
    return sizeToFit.height;
}

- (void) toastTip:(NSString*)toastInfo
{
    CGRect frameRC = [[UIScreen mainScreen] bounds];
    frameRC.origin.y = frameRC.size.height - 100;
    frameRC.size.height -= 100;
    __block UITextView * toastView = [[UITextView alloc] init];

    toastView.editable = NO;
    toastView.selectable = NO;

    frameRC.size.height = [toastView sizeThatFits:CGSizeMake(frameRC.size.width, MAXFLOAT)].height;

    toastView.frame = frameRC;

    toastView.text = toastInfo;
    toastView.backgroundColor = [UIColor whiteColor];
    toastView.alpha = 0.5;

    [self.view addSubview:toastView];

    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC);

    dispatch_after(popTime, dispatch_get_main_queue(), ^(){
        [toastView removeFromSuperview];
        toastView = nil;
    });
}
#ifndef UGC_SMART
#pragma mark - gesture handler
- (void)handlePanSlide:(UIPanGestureRecognizer*)recognizer
{
    CGPoint translation = [recognizer translationInView:self.view.superview];
    [recognizer velocityInView:self.view];
    CGPoint speed = [recognizer velocityInView:self.view];

    //    NSLog(@"pan center:(%.2f)", translation.x);
    //    NSLog(@"pan speed:(%.2f)", speed.x);

    float ratio = translation.x / self.view.frame.size.width;
    float leftRatio = ratio;
    NSInteger index = [_vBeauty currentFilterIndex];
    UIImage* curFilterImage = [_vBeauty filterImageByIndex:index];
    UIImage* filterImage1 = nil;
    UIImage* filterImage2 = nil;
    CGFloat filter1Level = 0.f;
    CGFloat filter2Level = 0.f;
    if (leftRatio > 0) {
        filterImage1 = [_vBeauty filterImageByIndex:index - 1];
        filter1Level = [_vBeauty filterMixLevelByIndex:index - 1] / 10;
        filterImage2 = curFilterImage;
        filter2Level = [_vBeauty filterMixLevelByIndex:index] / 10;
    }
    else {
        filterImage1 = curFilterImage;
        filter1Level = [_vBeauty filterMixLevelByIndex:index] / 10;
        filterImage2 = [_vBeauty filterImageByIndex:index + 1];
        filter2Level = [_vBeauty filterMixLevelByIndex:index + 1] / 10;
        leftRatio = 1 + leftRatio;
    }

    if (recognizer.state == UIGestureRecognizerStateChanged) {
        [[TXUGCRecord shareInstance] setFilter:filterImage1 leftIntensity:filter1Level rightFilter:filterImage2 rightIntensity:filter2Level leftRatio:leftRatio];
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded) {
        BOOL isDependRadio = fabs(speed.x) < 500; //x方向的速度
        [self animateFromFilter1:filterImage1 filter2:filterImage2 filter1MixLevel:filter1Level filter2MixLevel:filter2Level leftRadio:leftRatio speed:speed.x completion:^{
            if (!isDependRadio) {
                if (speed.x < 0) {
                    _vBeauty.currentFilterIndex = index + 1;
                }
                else {
                    _vBeauty.currentFilterIndex = index - 1;
                }
            }
            else {
                if (ratio > 0.5) {   //过半或者速度>500就切换
                    _vBeauty.currentFilterIndex = index - 1;
                }
                else if  (ratio < -0.5) {
                    _vBeauty.currentFilterIndex = index + 1;
                }
            }

            UILabel* filterTipLabel = [UILabel new];
            filterTipLabel.text = [_vBeauty currentFilterName];
            filterTipLabel.font = [UIFont systemFontOfSize:30];
            filterTipLabel.textColor = UIColor.whiteColor;
            filterTipLabel.alpha = 0.1;
            [filterTipLabel sizeToFit];
            filterTipLabel.center = CGPointMake(self.view.size.width / 2, self.view.size.height / 3);
            [self.view addSubview:filterTipLabel];

            [UIView animateWithDuration:0.25 animations:^{
                filterTipLabel.alpha = 1;
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.25 delay:0.25 options:UIViewAnimationOptionCurveLinear animations:^{
                    filterTipLabel.alpha = 0.1;
                } completion:^(BOOL finished) {
                    [filterTipLabel removeFromSuperview];
                }];
            }];
        }];
    }
}

- (void)animateFromFilter1:(UIImage*)filter1Image filter2:(UIImage*)filter2Image filter1MixLevel:(CGFloat)filter1MixLevel filter2MixLevel:(CGFloat)filter2MixLevel leftRadio:(CGFloat)leftRadio speed:(CGFloat)speed completion:(void(^)())completion
{
    if (leftRadio <= 0 || leftRadio >= 1) {
        completion();
        return;
    }

    static float delta = 1.f / 12;

    BOOL isDependRadio = fabs(speed) < 500;
    if (isDependRadio) {
        if (leftRadio < 0.5) {
            leftRadio -= delta;
        }
        else {
            leftRadio += delta;
        }
    }
    else {
        if (speed > 0) {
            leftRadio += delta;
        }
        else
            leftRadio -= delta;
    }

    [[TXUGCRecord shareInstance] setFilter:filter1Image leftIntensity:filter1MixLevel rightFilter:filter2Image rightIntensity:filter2MixLevel leftRatio:leftRadio];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.f / 30 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self animateFromFilter1:filter1Image filter2:filter2Image filter1MixLevel:filter1MixLevel filter2MixLevel:filter2MixLevel leftRadio:leftRadio speed:speed completion:completion];
    });
}

#pragma mark - TXVideoCustomProcessDelegate
- (GLuint)onPreProcessTexture:(GLuint)texture width:(CGFloat)width height:(CGFloat)height
{
    static int i = 0;
    if (i++ % 100 == 0) {
        NSLog(@"onPreProcessTexture width:%f height:%f", width, height);
    }

    return texture;
}

- (void)onTextureDestoryed
{
    NSLog(@"onTextureDestoryed");
}

- (void)onDetectFacePoints:(NSArray *)points
{
    static int i = 0;
    if (i++ % 100 == 0) {
        NSLog(@"onDetectFacePoints.count:%lu", points.count);
    }
}
#endif

@end
