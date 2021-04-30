
#import <Foundation/Foundation.h>
#import "VideoPreviewViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "MBProgressHUD.h"
#import "SmallButton.h"
#import "PhotoUtil.h"
#import "AppLocalized.h"

#define BUTTON_PREVIEW_SIZE         65
#define BUTTON_CONTROL_SIZE         40

@interface VideoPreviewViewController()<TXVodPlayListener>
{
    UIView *                        _videoPreview;
    UIButton *                      _btnStartPreview;
    UILabel*                        _progressTipLabel;
    UISlider *                      _sdPreviewSlider;
    
    int                             _recordType;
    UIImage *                       _coverImage;
    BOOL                            _previewing;
    BOOL                            _startPlay;
    
    BOOL                            _navigationBarHidden;
    BOOL                            _statusBarHidden;
    BOOL                            _showEditButton;
    
    NSString*                       _videoPath;
    TXVodPlayer*                    _vodPlayer;
    TX_Enum_Type_RenderMode         _renderMode;
}
@end


@implementation VideoPreviewViewController

- (instancetype)initWithCoverImage:(UIImage *)coverImage
                         videoPath:(NSString*)videoPath
                        renderMode:(TX_Enum_Type_RenderMode)renderMode
                    showEditButton:(BOOL)showEditButton;
{
    if (self = [super init])
    {
        _coverImage = coverImage;
        _videoPath =  videoPath;
        _renderMode = renderMode;
        _showEditButton = showEditButton;
        _previewing   = NO;
        _startPlay    = NO;
        
        _vodPlayer = [[TXVodPlayer alloc] init];
        _vodPlayer.vodDelegate = self;
        _vodPlayer.config.playerType = PLAYER_AVPLAYER;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppDidEnterBackGround:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAudioSessionEvent:) name:AVAudioSessionInterruptionNotification object:nil];
    }
    return self;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    [self initPreviewUI];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _navigationBarHidden = self.navigationController.navigationBar.hidden;
    [self.navigationController setNavigationBarHidden:YES animated:NO];
//    [UIApplication sharedApplication].statusBarHidden = YES;
    
    if (_previewing)
    {
        [self startVideoPreview:NO];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    self.navigationController.navigationBar.hidden = _navigationBarHidden;
//    [UIApplication sharedApplication].statusBarHidden = NO;
    
    [self stopVideoPreview:YES];
}

-(void)dealloc{
    [_vodPlayer removeVideoWidget];
    [_vodPlayer stopPlay];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)onAppDidEnterBackGround:(UIApplication*)app
{
    [self stopVideoPreview:NO];
}

- (void)onAppWillEnterForeground:(UIApplication*)app
{
    if (_previewing)
    {
        [self startVideoPreview:NO];
    }
}

- (void)onAudioSessionEvent:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    AVAudioSessionInterruptionType type = [info[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
    if (type == AVAudioSessionInterruptionTypeBegan) {
        if (_previewing) {
            [self onBtnPreviewStartClicked];
        }
    }
}

-(void)startVideoPreview:(BOOL) startPlay
{
    if(startPlay == YES){
        [_vodPlayer setupVideoWidget:_videoPreview insertIndex:0];
        [_vodPlayer startPlay:_videoPath];
        [_vodPlayer setRenderMode:_renderMode];
    }else{
        [_vodPlayer resume];
    }
    
}

-(void)stopVideoPreview:(BOOL) stopPlay
{
    
    if(stopPlay == YES) {
        [_vodPlayer stopPlay];
        _sdPreviewSlider.value = 0;
        _sdPreviewSlider.enabled = NO;
        _startPlay = NO;
        [_btnStartPreview setImage:[UIImage imageNamed:@"startpreview"] forState:UIControlStateNormal];
        [_btnStartPreview setImage:[UIImage imageNamed:@"startpreview_press"] forState:UIControlStateSelected];
    }else {
        [_vodPlayer pause];
    }
}

#pragma mark ---- Video Preview ----
-(void)initPreviewUI
{
    //[_livePlayer setRenderMode:RENDER_MODE_FILL_EDGE];
    self.title = UGCLocalize(@"UGCKit.Preview.videoplayback");
    self.navigationItem.hidesBackButton = YES;
    CGFloat top = [UIApplication sharedApplication].statusBarFrame.size.height + 5;
    
    UIImageView * coverImageView = [[UIImageView alloc] initWithFrame:self.view.frame];
    coverImageView.backgroundColor = UIColor.blackColor;
    if(_renderMode == RENDER_MODE_FILL_EDGE){
        coverImageView.contentMode = UIViewContentModeScaleAspectFit;
    }else{
        coverImageView.contentMode = UIViewContentModeScaleAspectFill;
    }
    coverImageView.image = _coverImage;
    [self.view addSubview:coverImageView];
    
    _videoPreview = [[UIView alloc] initWithFrame:self.view.frame];
    [self.view addSubview: _videoPreview];
    
    _btnStartPreview = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, BUTTON_PREVIEW_SIZE, BUTTON_PREVIEW_SIZE)];
    _btnStartPreview.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2);
    [_btnStartPreview setImage:[UIImage imageNamed:@"startpreview"] forState:UIControlStateNormal];
    [_btnStartPreview setImage:[UIImage imageNamed:@"startpreview_press"] forState:UIControlStateSelected];
    [_btnStartPreview addTarget:self action:@selector(onBtnPreviewStartClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnStartPreview];
    
    UIButton *btnPop = [[SmallButton alloc] initWithFrame:CGRectMake(10, top, BUTTON_CONTROL_SIZE, BUTTON_CONTROL_SIZE)];
    [btnPop setImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
    [btnPop addTarget:self action:@selector(onBtnPopBack) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnPop];
    
    CGFloat bottom = self.view.frame.size.height;
    if (@available(iOS 11, *)) {
        bottom -= [UIApplication sharedApplication].keyWindow.safeAreaInsets.bottom;
    }
    _sdPreviewSlider = [[UISlider alloc] init];
    _sdPreviewSlider.frame = CGRectMake(0, 0, self.view.frame.size.width - 40, 60);
    _sdPreviewSlider.center = CGPointMake(self.view.frame.size.width / 2, bottom - 80);
    [_sdPreviewSlider setThumbImage:[UIImage imageNamed:@"slider"] forState:UIControlStateNormal];
    [_sdPreviewSlider setMinimumTrackImage:[UIImage imageNamed:@"green"] forState:UIControlStateNormal];
    [_sdPreviewSlider setMaximumTrackImage:[UIImage imageNamed:@"gray"] forState:UIControlStateNormal];
    [_sdPreviewSlider addTarget:self action:@selector(onDragEnd:) forControlEvents:UIControlEventTouchUpInside];
    [_sdPreviewSlider addTarget:self action:@selector(onDragStart:) forControlEvents:UIControlEventTouchDown];
    _sdPreviewSlider.enabled = NO;
    [self.view addSubview:_sdPreviewSlider];
    
    _progressTipLabel = [UILabel new];
    _progressTipLabel.textAlignment = NSTextAlignmentRight;
    _progressTipLabel.textColor = UIColor.whiteColor;
    _progressTipLabel.font = [UIFont systemFontOfSize:10];
    _progressTipLabel.frame = CGRectMake(self.view.frame.size.width - 120, bottom - 100, 100, 10);
    _progressTipLabel.text = @"00:00/00:00";
    [self.view addSubview:_progressTipLabel];

    UIButton *btnDelete = [[SmallButton alloc] initWithFrame:CGRectMake(0, 0, BUTTON_CONTROL_SIZE, BUTTON_CONTROL_SIZE)];
    btnDelete.center = CGPointMake(self.view.frame.size.width / 4, bottom - BUTTON_CONTROL_SIZE - 5);
    [btnDelete setImage:[UIImage imageNamed:@"delete"] forState:UIControlStateNormal];
    [btnDelete setImage:[UIImage imageNamed:@"delete_press"] forState:UIControlStateSelected];
    [btnDelete addTarget:self action:@selector(onBtnDeleteClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnDelete];

#ifndef UGC_SMART
    if (_showEditButton) {
        UIButton *btnEdit = [[SmallButton alloc] initWithFrame:CGRectMake(0, 0, BUTTON_CONTROL_SIZE, BUTTON_CONTROL_SIZE)];
        btnEdit.center = CGPointMake(self.view.frame.size.width / 2, bottom - BUTTON_CONTROL_SIZE - 5);
        [btnEdit setImage:[UIImage imageNamed:@"edit"] forState:UIControlStateNormal];
        [btnEdit setImage:[UIImage imageNamed:@"edit_press"] forState:UIControlStateSelected];
        [btnEdit addTarget:self action:@selector(onBtnDownEditClicked) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btnEdit];
    }
#endif

    UIButton *btnDownload = [[SmallButton alloc] initWithFrame:CGRectMake(0, 0, BUTTON_CONTROL_SIZE, BUTTON_CONTROL_SIZE)];
    btnDownload.center = CGPointMake(self.view.frame.size.width * 3 / 4, bottom - BUTTON_CONTROL_SIZE - 5);
    [btnDownload setImage:[UIImage imageNamed:@"download"] forState:UIControlStateNormal];
    [btnDownload setImage:[UIImage imageNamed:@"download_press"] forState:UIControlStateSelected];
    [btnDownload addTarget:self action:@selector(onBtnDownloadClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnDownload];
}

-(void)onBtnPopBack
{
    [self _goBack];
}

-(void)onBtnPreviewStartClicked
{
    _sdPreviewSlider.enabled = YES;
    if (!_startPlay) {
        [self startVideoPreview:YES];
        _startPlay = YES;
    }
    _previewing = !_previewing;
    
    if (_previewing)
    {
        [self startVideoPreview:NO];
        [_btnStartPreview setImage:[UIImage imageNamed:@"pausepreview"] forState:UIControlStateNormal];
        [_btnStartPreview setImage:[UIImage imageNamed:@"pausepreview_press"] forState:UIControlStateSelected];
    }
    else
    {
        [self stopVideoPreview:NO];
        [_btnStartPreview setImage:[UIImage imageNamed:@"startpreview"] forState:UIControlStateNormal];
        [_btnStartPreview setImage:[UIImage imageNamed:@"startpreview_press"] forState:UIControlStateSelected];
    }
}

-(void)onBtnDownEditClicked
{
    if (self.onTapEdit) {
        self.onTapEdit(self);
    }
}

-(void)onBtnDownloadClicked
{
    [PhotoUtil saveAssetToAlbum:[NSURL fileURLWithPath:_videoPath]
                          completion:^(BOOL success, NSError * _Nullable error) {
        if (!success) {
            NSLog(@"save video fail:%@", error);
        }
    }];
    [self _goBack];
}

-(void)onBtnDeleteClicked
{
    [[NSFileManager defaultManager] removeItemAtPath:_videoPath error:nil];
    [self _goBack];
}

- (void)_goBack {
    UINavigationController *nav = self.navigationController;
    if (nav.presentingViewController) {
        [nav.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    } else {
        [nav popToRootViewControllerAnimated:YES];
    }
}

-(void)onBtnShareClicked
{
    //    TCVideoPublishController *vc = [[TCVideoPublishController alloc] init:[TXUGCRecord shareInstance] recordType:_recordType RecordResult:_recordResult TCLiveInfo:_liveInfo];
    //    [self.navigationController pushViewController:vc animated:YES];
    
    //    TCVideoEditViewController *vc = [[TCVideoEditViewController alloc] init];
    //    [vc setVideoPath:_recordResult.videoPath];
    //    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onDragStart:(UISlider*)sender
{
    NSLog(@"onDragStart:%f", sender.value);
}

- (void)onDragEnd:(UISlider*)sender
{
    NSLog(@"onDragEnd:%f", sender.value);
    if (_sdPreviewSlider.maximumValue > 5.0) {
        [_vodPlayer seek:sender.value];
    }
}

#pragma mark - TXLivePlayListener

-(void) onPlayEvent:(TXVodPlayer *)player event:(int)EvtID withParam:(NSDictionary*)param
{
    NSDictionary* dict = param;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (EvtID == PLAY_EVT_PLAY_PROGRESS) {
            float progress = [dict[EVT_PLAY_PROGRESS] floatValue];
            [_sdPreviewSlider setValue:progress];
            
            float duration = [dict[EVT_PLAY_DURATION] floatValue];
            if (duration > 0 && _sdPreviewSlider.maximumValue != duration) {
                _sdPreviewSlider.minimumValue = 0;
                _sdPreviewSlider.maximumValue = duration;
            }
            NSString* progressTips = [NSString stringWithFormat:@"%02d:%02d/%02d:%02d", (int)progress / 60, (int)progress % 60, (int)duration / 60, (int)duration % 60];
            _progressTipLabel.text = progressTips;
            return ;
        } else if(EvtID == PLAY_EVT_PLAY_END) {
            [_sdPreviewSlider setValue:0];
            //           [self stopVideoPreview:YES];
            //           [self startVideoPreview:YES];
            //           [_livePlayer startPlay:_videoPath type:PLAY_TYPE_LOCAL_VIDEO];
            [_vodPlayer resume];
            
            [_btnStartPreview setImage:[UIImage imageNamed:@"pausepreview"] forState:UIControlStateNormal];
            [_btnStartPreview setImage:[UIImage imageNamed:@"pausepreview_press"] forState:UIControlStateSelected];
            //[_livePlayer startPlay:_videoPath type:PLAY_TYPE_LOCAL_VIDEO];
            _progressTipLabel.text = @"00:00/00:00";
        }
    });
}

/**
 * 网络状态通知
 *
 * @param player 点播对象
 * @param param 参见TXLiveSDKTypeDef.h
 */
-(void) onNetStatus:(TXVodPlayer *)player withParam:(NSDictionary*)param
{
    
}

@end


