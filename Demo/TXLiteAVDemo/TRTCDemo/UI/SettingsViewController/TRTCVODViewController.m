#import <mach/mach.h>
#import "ScanQRController.h"
#import "TRTCVODViewController.h"
#import "TXLiveBase.h"
#ifndef UGC_SMART
#import "AppLogMgr.h"
#endif
#import "AFNetworkReachabilityManager.h"
#import "AppDelegate.h"
#import "TXBitrateView.h"
#import "TXPlayerAuthParams.h"
#import "UIImage+Additions.h"
#import "UIView+Additions.h"
#import "AppLocalized.h"
#define TEST_MUTE 0

@interface TRTCVODViewController () <UITextFieldDelegate,
                                     TXVodPlayListener,
#ifndef UGC_SMART
                                     TXVideoCustomProcessDelegate,
#endif
                                     ScanQRDelegate,
                                     TXBitrateViewDelegate>
@end

@implementation TRTCVODViewController {
    BOOL _bHWDec;
    UISlider       *_playProgress;
    UISlider       *_playableProgress;
    UISlider       *_playoutVolumeSlider;
    UILabel        *_playDuration;
    UILabel        *_playStart;
    UILabel        *_volumeLabel;
    UILabel        *_volumeMaxLabel;
    UIButton       *_btnHWDec;

    long long _trackingTouchTS;
    BOOL _startSeek;
    BOOL _videoPause;

    UIImageView    *_loadingImageView;
    BOOL _appIsInterrupt;
    float _sliderValue;
    long long _startPlayTS;
    UIView         *mVideoContainer;
    NSString       *_playUrl;
    UILabel        *_labProgress;
    BOOL _enableCache;
    TXBitrateView  *_bitrateView;
    NSObject       *_trtcCloud;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    int width = [[UIScreen mainScreen] bounds].size.width;
    int height = [[UIScreen mainScreen] bounds].size.height - 400;

    int y = 0;
    if (@available(iOS 11, *)) {
        y += [UIApplication sharedApplication].keyWindow.safeAreaInsets.top;
    }
    self.view.frame = CGRectMake(0, y, width, height);
    [self initUI];
}

- (void)statusBarOrientationChanged:(NSNotification *)note {
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBar.hidden = YES;
}

- (void)initUI {
    HelpBtnUI(点播播放器) for (UIView *view in self.view.subviews) { [view removeFromSuperview]; }
    self.title =TRTCLocalize(@"Demo.TRTC.Live.VodPlayer");
    [self.view setBackgroundImage:[UIImage imageNamed:@"background.jpg"]];
    for (UIView *view in [self.view subviews]) {
        [view removeFromSuperview];
    }
    CGSize size = self.view.size;
    int icon_size = 40;
    _cover = [[UIView alloc] init];
    _cover.frame = CGRectMake(10.0f, 55 + 2 * icon_size, size.width - 20, size.height - 75 - 3 * icon_size);
    _cover.backgroundColor = [UIColor whiteColor];
    _cover.alpha = 0.5;
    _cover.hidden = YES;
    [self.view addSubview:_cover];

    int logheadH = 65;
    CGFloat topOffset = [UIApplication sharedApplication].statusBarFrame.size.height;
    topOffset += self.navigationController.navigationBar.height + 5;
    _statusView = [[UITextView alloc]
                   initWithFrame:CGRectMake(10.0f, 55 + 2 * icon_size, size.width - 20, logheadH)];
    _statusView.backgroundColor = [UIColor clearColor];
    _statusView.alpha = 1;
    _statusView.textColor = [UIColor blackColor];
    _statusView.editable = NO;
    _statusView.hidden = YES;
    [self.view addSubview:_statusView];

    _logViewEvt = [[UITextView alloc]
                   initWithFrame:CGRectMake(10.0f, 55 + 2 * icon_size + logheadH, size.width - 20,
                                            size.height - 75 - 3 * icon_size - logheadH)];
    _logViewEvt.backgroundColor = [UIColor clearColor];
    _logViewEvt.alpha = 1;
    _logViewEvt.textColor = [UIColor blackColor];
    _logViewEvt.editable = NO;
    _logViewEvt.hidden = YES;
    [self.view addSubview:_logViewEvt];
    self.txtRtmpUrl = [[UITextField alloc]
                       initWithFrame:CGRectMake(10, topOffset, size.width - 25 - icon_size, icon_size)];
    [self.txtRtmpUrl setBorderStyle:UITextBorderStyleRoundedRect];
    self.txtRtmpUrl.placeholder = TRTCLocalize(@"Demo.TRTC.Live.VodUrlTip");
    self.txtRtmpUrl.text = @"http://1252463788.vod2.myqcloud.com/95576ef5vodtransgzp1252463788/"
                           @"e1ab85305285890781763144364/v.f20.mp4";
    self.txtRtmpUrl.background = [UIImage imageNamed:@"Input_box"];
    self.txtRtmpUrl.alpha = 0.5;
    self.txtRtmpUrl.autocapitalizationType = UITextAutocorrectionTypeNo;
    self.txtRtmpUrl.delegate = self;
    [self.view addSubview:self.txtRtmpUrl];

    UIButton *btnScan = [UIButton buttonWithType:UIButtonTypeCustom];
    btnScan.frame =
        CGRectMake(size.width - 10 - icon_size, self.txtRtmpUrl.top, icon_size, icon_size);
    [btnScan setImage:[UIImage imageNamed:@"QR_code"] forState:UIControlStateNormal];
    [btnScan addTarget:self
     action:@selector(clickScan:)
     forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnScan];

    int icon_length = 9;

    int icon_gap = (size.width - icon_size * (icon_length - 1)) / icon_length;
    int hh = self.view.height - icon_size - 50;
    if (@available(iOS 11, *)) {
        hh -= [UIApplication sharedApplication].keyWindow.safeAreaInsets.bottom;
    }

    _playStart = [[UILabel alloc] init];
    _playStart.frame = CGRectMake(20, hh, 50, 30);
    [_playStart setText:@"00:00"];
    [_playStart setTextColor:[UIColor whiteColor]];
    _playStart.hidden = YES;
    [self.view addSubview:_playStart];

    _playDuration = [[UILabel alloc] init];
    _playDuration.frame = CGRectMake(self.view.size.width - 70, hh, 50, 30);
    [_playDuration setText:@"00:00"];
    [_playDuration setTextColor:[UIColor whiteColor]];
    _playDuration.hidden = YES;
    [self.view addSubview:_playDuration];

    _playableProgress =
        [[UISlider alloc] initWithFrame:CGRectMake(70, hh - 1, self.view.size.width - 132, 30)];
    _playableProgress.maximumValue = 0;
    _playableProgress.minimumValue = 0;
    _playableProgress.value = 0;
    [_playableProgress setThumbImage:[UIImage imageWithColor:[UIColor clearColor]
                                      size:CGSizeMake(20, 10)]
     forState:UIControlStateNormal];
    [_playableProgress setMaximumTrackTintColor:[UIColor clearColor]];
    _playableProgress.userInteractionEnabled = NO;
    _playableProgress.hidden = YES;

    [self.view addSubview:_playableProgress];

    _playProgress =
        [[UISlider alloc] initWithFrame:CGRectMake(70, hh, self.view.size.width - 140, 30)];
    _playProgress.maximumValue = 0;
    _playProgress.minimumValue = 0;
    _playProgress.value = 0;
    _playProgress.continuous = NO;
    //    _playProgress.maximumTrackTintColor = UIColor.clearColor;
    [_playProgress addTarget:self
     action:@selector(onSeek:)
     forControlEvents:(UIControlEventValueChanged)];
    [_playProgress addTarget:self
     action:@selector(onSeekBegin:)
     forControlEvents:(UIControlEventTouchDown)];
    [_playProgress addTarget:self
     action:@selector(onDrag:)
     forControlEvents:UIControlEventTouchDragInside];
    _playProgress.hidden = YES;

    UIView *thumeView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    thumeView.backgroundColor = UIColor.whiteColor;
    thumeView.layer.cornerRadius = 10;
    UIImage *thumeImage = thumeView.toImage;
    [_playProgress setThumbImage:thumeImage forState:UIControlStateNormal];

    [self.view addSubview:_playProgress];

    _volumeLabel = [[UILabel alloc] init];
    _volumeLabel.frame = CGRectMake(20, hh - 20, 50, 30);
    [_volumeLabel setText:@"0"];
    [_volumeLabel setTextColor:[UIColor whiteColor]];
    [self.view addSubview:_volumeLabel];

    _volumeMaxLabel = [[UILabel alloc] init];
    _volumeMaxLabel.frame = CGRectMake(self.view.size.width - 70, hh - 20, 50, 30);
    [_volumeMaxLabel setText:@"100"];
    [_volumeMaxLabel setTextColor:[UIColor whiteColor]];
    [self.view addSubview:_volumeMaxLabel];

    _playoutVolumeSlider =
        [[UISlider alloc] initWithFrame:CGRectMake(70, hh - 20, self.view.size.width - 140, 30)];
    _playoutVolumeSlider.maximumValue = 100;
    _playoutVolumeSlider.minimumValue = 0;
    _playoutVolumeSlider.value = 100;
    _playoutVolumeSlider.continuous = NO;
    [_playoutVolumeSlider addTarget:self
     action:@selector(onSeek:)
     forControlEvents:(UIControlEventValueChanged)];
    [_playoutVolumeSlider addTarget:self
     action:@selector(onSeekBegin:)
     forControlEvents:(UIControlEventTouchDown)];
    [_playoutVolumeSlider addTarget:self
     action:@selector(onDrag:)
     forControlEvents:UIControlEventTouchDragInside];
    [_playoutVolumeSlider setThumbImage:thumeImage forState:UIControlStateNormal];

    [self.view addSubview:_playoutVolumeSlider];

    int btn_index = 0;
    _play_switch = NO;
    _btnPlay = [self createBottomBtnIndex:btn_index++
                Icon:@"start"
                Action:@selector(clickPlay:)
                Gap:icon_gap
                Size:icon_size];

    _btnClose = [self createBottomBtnIndex:btn_index++
                 Icon:@"close"
                 Action:@selector(clickClose:)
                 Gap:icon_gap
                 Size:icon_size];

    _log_switch = NO;
    [self createBottomBtnIndex:btn_index++
     Icon:@"log"
     Action:@selector(clickLog:)
     Gap:icon_gap
     Size:icon_size];

    _bHWDec = NO;
    _btnHWDec = [self createBottomBtnIndex:btn_index++
                 Icon:@"quick2"
                 Action:@selector(onClickHardware:)
                 Gap:icon_gap
                 Size:icon_size];

    _screenPortrait = NO;
    [self createBottomBtnIndex:btn_index++
     Icon:@"portrait"
     Action:@selector(clickScreenOrientation:)
     Gap:icon_gap
     Size:icon_size];

    _renderFillScreen = NO;
    [self createBottomBtnIndex:btn_index++
     Icon:@"fill"
     Action:@selector(clickRenderMode:)
     Gap:icon_gap
     Size:icon_size];

    [self createBottomBtnIndex:btn_index++
     Icon:@"cache2"
     Action:@selector(cacheEnable:)
     Gap:icon_gap
     Size:icon_size];

    _btnChangeRate = [self createBottomBtnIndex:btn_index++
                      Icon:nil
                      Action:@selector(clickChangeRate:)
                      Gap:icon_gap
                      Size:icon_size];
    [_btnChangeRate setTitle:@"1.0" forState:UIControlStateNormal];
    _txVodPlayer             = [[TXVodPlayer alloc] init];
    _videoPause              = NO;
    _trackingTouchTS         = 0;
    _playStart.hidden        = NO;
    _playDuration.hidden     = NO;
    _playProgress.hidden     = NO;
    _playableProgress.hidden = NO;
    float width = 34;
    float height = 34;
    float offsetX = (self.view.frame.size.width - width) / 2;
    float offsetY = (self.view.frame.size.height - height) / 2;
    NSMutableArray *array =
        [[NSMutableArray alloc] initWithObjects:[UIImage imageNamed:@"loading_image0.png"],
         [UIImage imageNamed:@"loading_image1.png"],
         [UIImage imageNamed:@"loading_image2.png"],
         [UIImage imageNamed:@"loading_image3.png"],
         [UIImage imageNamed:@"loading_image4.png"],
         [UIImage imageNamed:@"loading_image5.png"],
         [UIImage imageNamed:@"loading_image6.png"],
         [UIImage imageNamed:@"loading_image7.png"], nil];
    _loadingImageView =
        [[UIImageView alloc] initWithFrame:CGRectMake(offsetX, offsetY, width, height)];
    _loadingImageView.animationImages = array;
    _loadingImageView.animationDuration = 1;
    _loadingImageView.hidden = YES;
    [self.view addSubview:_loadingImageView];

    CGRect VideoFrame = self.view.bounds;
    mVideoContainer = [[UIView alloc]
                       initWithFrame:CGRectMake(0, 0, VideoFrame.size.width, VideoFrame.size.height)];
    [self.view insertSubview:mVideoContainer atIndex:0];
    mVideoContainer.center = self.view.center;

    _bitrateView = [[TXBitrateView alloc] initWithFrame:CGRectZero];
    _bitrateView.delegate = self;
    [self.view addSubview:_bitrateView];
}

- (void)setEnableAttachVodToTRTC:(BOOL)enable trtcCloud:(NSObject *)trtcCloud {
    _enableAttachToTRTC = enable;

    if (enable && _txVodPlayer) {
        _trtcCloud = trtcCloud;
        [_txVodPlayer attachTRTC:trtcCloud];
        [_txVodPlayer publishVideo];
        [_txVodPlayer publishAudio];
    } else {
        _trtcCloud = nil;
        [_txVodPlayer unpublishVideo];
        [_txVodPlayer unpublishAudio];
        [_txVodPlayer detachTRTC];
    }
}

- (UIButton *)createBottomBtnIndex:(int)index
        Icon:(NSString *)icon
        Action:(SEL)action
        Gap:(int)gap
        Size:(int)size {
    CGFloat y = self.view.height - size - 10;
    if (@available(iOS 11, *)) {
        y -= [UIApplication sharedApplication].keyWindow.safeAreaInsets.bottom;
    }
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake((index + 1) * gap + index * size, y, size, size);
    if (icon) {
        [btn setImage:[UIImage imageNamed:icon] forState:UIControlStateNormal];
    }
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    return btn;
}

- (UIButton *)createBottomBtnIndexEx:(int)index
        Icon:(NSString *)icon
        Action:(SEL)action
        Gap:(int)gap
        Size:(int)size {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake((index + 1) * gap + index * size, self.view.size.height - 2 * (size + 10),
                           size, size);
    [btn setImage:[UIImage imageNamed:icon] forState:UIControlStateNormal];
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    return btn;
}

- (void)onSelectBitrateIndex {
    [_txVodPlayer setBitrateIndex:_bitrateView.selectedIndex];
}

- (void)onAudioSessionEvent:(NSNotification *)notification {
    NSDictionary *info = notification.userInfo;
    AVAudioSessionInterruptionType type =
        [info[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
    if (type == AVAudioSessionInterruptionTypeBegan) {
        if (_play_switch == YES && _appIsInterrupt == NO) {
            _appIsInterrupt = YES;
        }
    } else {
        AVAudioSessionInterruptionOptions options =
            [info[AVAudioSessionInterruptionOptionKey] unsignedIntegerValue];
        if (options == AVAudioSessionInterruptionOptionShouldResume) {
            // 收到该事件不能调用resume，因为此时可能还在后台
            /*
               if (_play_switch == YES && _appIsInterrupt == YES) {
               if ([self isVODType:_playType]) {
               if (!_videoPause) {
               [_txVodPlayer resume];
               }
               }
               _appIsInterrupt = NO;
               }
             */
        }
    }
}

- (void)onAppDidEnterBackGround:(UIApplication *)app {
    if (_play_switch == YES) {
        if (!_videoPause) {
            [_txVodPlayer pause];
        }
    }
}

- (void)onAppWillEnterForeground:(UIApplication *)app {
    if (_play_switch == YES) {
        if (!_videoPause) {
            [_txVodPlayer resume];
        }
    }
}

- (void)onAppDidBecomeActive:(UIApplication *)app {
    if (_play_switch == YES && _appIsInterrupt == YES) {
        if (!_videoPause) {
            [_txVodPlayer resume];
        }
        _appIsInterrupt = NO;
    }
}

- (void)willMoveToParentViewController:(UIViewController *)parent {
    if (parent == nil) {
        [self stopPlay];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
     selector:@selector(onAudioSessionEvent:)
     name:AVAudioSessionInterruptionNotification
     object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
     selector:@selector(onAppDidEnterBackGround:)
     name:UIApplicationDidEnterBackgroundNotification
     object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
     selector:@selector(onAppWillEnterForeground:)
     name:UIApplicationWillEnterForegroundNotification
     object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
     selector:@selector(onAppDidBecomeActive:)
     name:UIApplicationDidBecomeActiveNotification
     object:nil];
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(statusBarOrientationChanged:)
     name:UIApplicationDidChangeStatusBarOrientationNotification
     object:nil];
}

- (void)dealloc {
    [self stopPlay];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma-- example code bellow
- (void)clearLog {
    _tipsMsg = @"";
    _logMsg = @"";
    [_statusView setText:@""];
    [_logViewEvt setText:@""];
    _startTime = [[NSDate date] timeIntervalSince1970] * 1000;
    _lastTime = _startTime;
}

- (BOOL)startPlay {
    NSString *playUrl = self.txtRtmpUrl.text;

    [self clearLog];
    unsigned long long recordTime = [[NSDate date] timeIntervalSince1970] * 1000;
    int mil = recordTime % 1000;
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    format.dateFormat = @"hh:mm:ss";
    NSString *time = [format stringFromDate:[NSDate date]];
    NSString *log = [NSString stringWithFormat:@"[%@.%-3.3d] 点击播放按钮", time, mil];

    NSString *ver = [TXLiveBase getSDKVersionStr];
    _logMsg = [NSString stringWithFormat:@"liteav sdk version: %@\n%@", ver, log];
    [_logViewEvt setText:_logMsg];
    _bitrateView.selectedIndex = 0;
    if (_txVodPlayer != nil) {
        _txVodPlayer.vodDelegate = self;
        if (_config == nil) {
            _config = [[TXVodPlayConfig alloc] init];
        }
        _config.keepLastFrameWhenStop = YES;
        if (_enableCache) {
            _config.cacheFolderPath =
                [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)
                  objectAtIndex:0] stringByAppendingString:@"/txcache"];
            _config.maxCacheItems = 2;
        } else {
            _config.cacheFolderPath = nil;
        }
        _config.maxBufferSize = 5; // 100M缓存
        [_txVodPlayer setConfig:_config];
        _config.progressInterval = 0.1;
        int result = [_txVodPlayer startPlay:playUrl];
        if (result != 0) {
            return NO;
        }
        if (_screenPortrait) {
            [_txVodPlayer setRenderRotation:HOME_ORIENTATION_RIGHT];
        } else {
            [_txVodPlayer setRenderRotation:HOME_ORIENTATION_DOWN];
        }
        if (_renderFillScreen) {
            [_txVodPlayer setRenderMode:RENDER_MODE_FILL_SCREEN];
        } else {
            [_txVodPlayer setRenderMode:RENDER_MODE_FILL_EDGE];
        }
        [self startLoadingAnimation];
        _videoPause = NO;
        [_btnPlay setImage:[UIImage imageNamed:@"suspend"] forState:UIControlStateNormal];
        _play_switch = YES;
        if (_enableAttachToTRTC) {
            [_txVodPlayer attachTRTC:_trtcCloud];
            [_txVodPlayer publishVideo];
            [_txVodPlayer publishAudio];
        }
    }
    [self startLoadingAnimation];
    _startPlayTS = [[NSDate date] timeIntervalSince1970] * 1000;
    _playUrl = playUrl;
    return YES;
}

- (void)stopPlay {
    if (!_enableAttachToTRTC) {
        [_txVodPlayer unpublishVideo];
        [_txVodPlayer unpublishAudio];
        [_txVodPlayer detachTRTC];
    }

    _playUrl = @"";
    [self stopLoadingAnimation];
    if (_txVodPlayer != nil) {
        [_txVodPlayer stopPlay];
    }
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:nil];
}

#pragma- ui event response.
- (void)clickPlay:(UIButton *)sender {
    if (_play_switch == YES) {
        if (_videoPause) {
            [_txVodPlayer resume];
            [sender setImage:[UIImage imageNamed:@"suspend"] forState:UIControlStateNormal];
            [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
        } else {
            [_txVodPlayer pause];
            [sender setImage:[UIImage imageNamed:@"start"] forState:UIControlStateNormal];
            [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
        }
        _videoPause = !_videoPause;
    } else {
        if (![self startPlay]) {
            return;
        }
        [sender setImage:[UIImage imageNamed:@"suspend"] forState:UIControlStateNormal];
        _play_switch = YES;
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    }
}

- (void)clickClose:(UIButton *)sender {
    _play_switch = NO;
    [self stopPlay];
    [_btnPlay setImage:[UIImage imageNamed:@"start"] forState:UIControlStateNormal];
    _playStart.text = @"00:00";
    [_playDuration setText:@"00:00"];
    [_playProgress setValue:0];
    [_playProgress setMaximumValue:0];
    [_playableProgress setValue:0];
    [_playableProgress setMaximumValue:0];
    _labProgress.text = @"";
}

- (void)clickLog:(UIButton *)sender {
    if (_log_switch == YES) {
        _statusView.hidden = YES;
        _logViewEvt.hidden = YES;
        [sender setImage:[UIImage imageNamed:@"log"] forState:UIControlStateNormal];
        _cover.hidden = YES;
        _log_switch = NO;
    } else {
        _statusView.hidden = NO;
        _logViewEvt.hidden = NO;
        [sender setImage:[UIImage imageNamed:@"log2"] forState:UIControlStateNormal];
        _cover.hidden = NO;
        _log_switch = YES;
    }
    [_txVodPlayer snapshot:^(UIImage *img) {
             img = nil;
     }];
}

- (void)clickScreenOrientation:(UIButton *)sender {
    _screenPortrait = !_screenPortrait;
    if (_screenPortrait) {
        [sender setImage:[UIImage imageNamed:@"landscape"] forState:UIControlStateNormal];
        [_txVodPlayer setRenderRotation:HOME_ORIENTATION_RIGHT];
    } else {
        [sender setImage:[UIImage imageNamed:@"portrait"] forState:UIControlStateNormal];
        [_txVodPlayer setRenderRotation:HOME_ORIENTATION_DOWN];
    }
}

- (void)clickRenderMode:(UIButton *)sender {
    _renderFillScreen = !_renderFillScreen;

    if (_renderFillScreen) {
        [sender setImage:[UIImage imageNamed:@"adjust"] forState:UIControlStateNormal];
        [_txVodPlayer setRenderMode:RENDER_MODE_FILL_SCREEN];
    } else {
        [sender setImage:[UIImage imageNamed:@"fill"] forState:UIControlStateNormal];
        [_txVodPlayer setRenderMode:RENDER_MODE_FILL_EDGE];
    }
}

- (void)clickChangeRate:(UIButton *)sender {
    NSString *text = sender.titleLabel.text;
    if ([text isEqualToString:@"1.0"]) {
        [_txVodPlayer setRate:1.3];
        [sender setTitle:@"1.3" forState:UIControlStateNormal];
    } else if ([text isEqualToString:@"1.3"]) {
        [_txVodPlayer setRate:1.8];
        [sender setTitle:@"1.8" forState:UIControlStateNormal];
    } else {
        [_txVodPlayer setRate:1.0];
        [sender setTitle:@"1.0" forState:UIControlStateNormal];
    }
}

- (void)clickMute:(UIButton *)sender {
    if (sender.isSelected) {
        [_txVodPlayer setMute:NO];
        [sender setSelected:NO];
        [sender setImage:[UIImage imageNamed:@"mic"] forState:UIControlStateNormal];
    } else {
        [_txVodPlayer setMute:YES];
        [sender setSelected:YES];
        [sender setImage:[UIImage imageNamed:@"vodplay"] forState:UIControlStateNormal];
    }
}

- (void)onClickHardware:(UIButton *)sender {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0) {
        [self toastTip:TRTCLocalize(@"Demo.TRTC.Live.iosversionbelow")];
        return;
    }

    if (_play_switch == YES) {
        [self stopPlay];
    }

    _txVodPlayer.enableHWAcceleration = !_bHWDec;

    _bHWDec = _txVodPlayer.enableHWAcceleration;

    if (_bHWDec) {
        [sender setImage:[UIImage imageNamed:@"quick"] forState:UIControlStateNormal];
    } else {
        [sender setImage:[UIImage imageNamed:@"quick2"] forState:UIControlStateNormal];
    }

    if (_play_switch == YES) {
        if (_bHWDec) {
            [self toastTip:TRTCLocalize(@"Demo.TRTC.Live.vodHardTip")];
        } else {
            [self toastTip:TRTCLocalize(@"Demo.TRTC.Live.vodSoftTip")];
        }

        [self startPlay];
    }
}

- (void)onHelpBtnClicked:(UIButton *)sender {
    NSURL *helpURL = [NSURL URLWithString:@"https://cloud.tencent.com/document/product/454/12147"];

    UIApplication *myApp = [UIApplication sharedApplication];
    if ([myApp canOpenURL:helpURL]) {
        [myApp openURL:helpURL];
    }
}

- (void)clickScan:(UIButton *)btn {
    ScanQRController *vc = [[ScanQRController alloc] init];
    vc.delegate = self;
    [self.navigationController pushViewController:vc animated:NO];
}

#pragma-- UISlider - play seek
- (void)onSeek:(UISlider *)slider {
    if ([slider isEqual:_playoutVolumeSlider]) {
        [_txVodPlayer setAudioPlayoutVolume:(int)slider.value];
        return;
    }
    [_txVodPlayer seek:_sliderValue];
    _trackingTouchTS = [[NSDate date] timeIntervalSince1970] * 1000;
    _startSeek = NO;
}

- (void)onSeekBegin:(UISlider *)slider {
    if ([slider isEqual:_playoutVolumeSlider]) {
        return;
    }
    _startSeek = YES;
}

- (void)onDrag:(UISlider *)slider {
    if ([slider isEqual:_playoutVolumeSlider]) {
        _volumeLabel.text = [NSString stringWithFormat:@"%d", (int)slider.value];
        return;
    }
    float progress = slider.value;
    int intProgress = progress + 0.5;
    _playStart.text =
        [NSString stringWithFormat:@"%02d:%02d", (int)(intProgress / 60), (int)(intProgress % 60)];
    _sliderValue = slider.value;
}

#pragma-- UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.txtRtmpUrl resignFirstResponder];
    _vCacheStrategy.hidden = YES;
}

#pragma mark-- ScanQRDelegate
- (void)onScanResult:(NSString *)result {
    self.txtRtmpUrl.text = result;
    [self startPlay];
}

- (void)cacheEnable:(id)sender {
    _enableCache = !_enableCache;
    if (_enableCache) {
        [sender setImage:[UIImage imageNamed:@"cache"] forState:UIControlStateNormal];
    } else {
        [sender setImage:[UIImage imageNamed:@"cache2"] forState:UIControlStateNormal];
    }
}
/**
   @method 获取指定宽度width的字符串在UITextView上的高度
   @param textView 待计算的UITextView
   @param width 限制字符串显示区域的宽度
   @result float 返回的高度
 */
- (float)heightForString:(UITextView *)textView andWidth:(float)width {
    CGSize sizeToFit = [textView sizeThatFits:CGSizeMake(width, MAXFLOAT)];
    return sizeToFit.height;
}

- (void)toastTip:(NSString *)toastInfo {
    CGRect frameRC = [[UIScreen mainScreen] bounds];
    frameRC.origin.y = frameRC.size.height - 110;
    frameRC.size.height -= 110;
    __block UITextView *toastView = [[UITextView alloc] init];

    toastView.editable = NO;
    toastView.selectable = NO;

    frameRC.size.height = [self heightForString:toastView andWidth:frameRC.size.width];

    toastView.frame = frameRC;

    toastView.text = toastInfo;
    toastView.backgroundColor = [UIColor whiteColor];
    toastView.alpha = 0.5;

    [self.view addSubview:toastView];

    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC);

    dispatch_after(popTime, dispatch_get_main_queue(), ^() {
        [toastView removeFromSuperview];
        toastView = nil;
    });
}

#pragma## #TXLivePlayListener
- (void)appendLog:(NSString *)evt time:(NSDate *)date mills:(int)mil {
    if (evt == nil) {
        return;
    }
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    format.dateFormat = @"hh:mm:ss";
    NSString *time = [format stringFromDate:date];
    NSString *log = [NSString stringWithFormat:@"[%@.%-3.3d] %@", time, mil, evt];
    if (_logMsg == nil) {
        _logMsg = @"";
    }
    _logMsg = [NSString stringWithFormat:@"%@\n%@", _logMsg, log];
    [_logViewEvt setText:_logMsg];
}

- (void)onPlayEvent:(TXVodPlayer *)player event:(int)EvtID withParam:(NSDictionary *)param {
    NSDictionary *dict = param;

    dispatch_async(dispatch_get_main_queue(), ^{
        if (EvtID == PLAY_EVT_RCV_FIRST_I_FRAME) {
            //            _publishParam = nil;
            [_txVodPlayer setupVideoWidget:mVideoContainer insertIndex:0];
        }

        if (EvtID == PLAY_EVT_VOD_LOADING_END || EvtID == PLAY_EVT_VOD_PLAY_PREPARED) {
            [self stopLoadingAnimation];
        }

        if (EvtID == PLAY_EVT_PLAY_BEGIN) {
            [self stopLoadingAnimation];
#ifndef UGC_SMART
            long long playDelay = [[NSDate date] timeIntervalSince1970] * 1000 - _startPlayTS;
            AppDemoLog(@"AutoMonitor:PlayFirstRender,cost=%lld", playDelay);
#endif
            NSArray *supportedBitrates = [_txVodPlayer supportedBitrates];
            _bitrateView.dataSource = supportedBitrates;
            _bitrateView.center =
                CGPointMake(self.view.width - _bitrateView.width / 2, self.view.height / 2);
        } else if (EvtID == PLAY_EVT_PLAY_PROGRESS) {
            if (_startSeek) {
                return;
            }

            float progress = [dict[EVT_PLAY_PROGRESS] floatValue];
            float duration = [dict[EVT_PLAY_DURATION] floatValue];

            int intProgress = progress + 0.5;
            _playStart.text = [NSString
                               stringWithFormat:@"%02d:%02d", (int)(intProgress / 60), (int)(intProgress % 60)];
            [_playProgress setValue:progress];

            int intDuration = duration + 0.5;
            if (duration > 0 && _playProgress.maximumValue != duration) {
                [_playProgress setMaximumValue:duration];
                [_playableProgress setMaximumValue:duration];
                _playDuration.text = [NSString
                                      stringWithFormat:@"%02d:%02d", (int)(intDuration / 60), (int)(intDuration % 60)];
            }
            [_playableProgress setValue:[dict[EVT_PLAYABLE_DURATION] floatValue]];
            return;
        } else if (EvtID == PLAY_ERR_NET_DISCONNECT || EvtID == PLAY_EVT_PLAY_END ||
                   EvtID == PLAY_ERR_FILE_NOT_FOUND || EvtID == PLAY_ERR_HLS_KEY ||
                   EvtID == PLAY_ERR_GET_PLAYINFO_FAIL) {
            _play_switch = NO;
            [_btnPlay setImage:[UIImage imageNamed:@"start"] forState:UIControlStateNormal];
            [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
            _videoPause = NO;

            if (EvtID == PLAY_ERR_NET_DISCONNECT) {
                NSString *Msg = (NSString *)[dict valueForKey:EVT_MSG];
                [self toastTip:Msg];
            }
            [self stopLoadingAnimation];
        } else if (EvtID == PLAY_EVT_PLAY_LOADING) {
            [self startLoadingAnimation];
        } else if (EvtID == PLAY_EVT_CONNECT_SUCC) {
            BOOL isWifi = [AFNetworkReachabilityManager sharedManager].reachableViaWiFi;
            if (!isWifi) {
                __weak __typeof(self) weakSelf = self;
                [[AFNetworkReachabilityManager sharedManager]
                 setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
                         if (_playUrl.length == 0) {
                         return;
                     }
                         if (status == AFNetworkReachabilityStatusReachableViaWiFi) {
                         UIAlertController *alert =
                             [UIAlertController alertControllerWithTitle:@""
                              message:@"您要切换到Wifi再观看吗?"
                              preferredStyle:UIAlertControllerStyleAlert];
                         [alert addAction:[UIAlertAction actionWithTitle:@"是"
                                           style:UIAlertActionStyleDefault
                                           handler:^(UIAlertAction *_Nonnull action) {
                                                   [alert dismissViewControllerAnimated:YES
                                                    completion:nil];
                                                   [weakSelf startPlay];
                                   }]];
                         [alert addAction:[UIAlertAction actionWithTitle:@"否"
                                           style:UIAlertActionStyleCancel
                                           handler:^(UIAlertAction *_Nonnull action) {
                                                   [alert dismissViewControllerAnimated:YES
                                                    completion:nil];
                                   }]];
                         [weakSelf presentViewController:alert animated:YES completion:nil];
                     }
                 }];
            }
        } else if (EvtID == PLAY_EVT_CHANGE_ROTATION) {
            return;
        }
        long long time = [(NSNumber *)[dict valueForKey:EVT_TIME] longLongValue];
        int mil = time % 1000;
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:time / 1000];
        NSString *Msg = (NSString *)[dict valueForKey:EVT_MSG];
        [self appendLog:Msg time:date mills:mil];
    });
}

- (void)onNetStatus:(TXVodPlayer *)player withParam:(NSDictionary *)param {
    NSDictionary *dict = param;
    dispatch_async(dispatch_get_main_queue(), ^{
        int netspeed = [(NSNumber *)[dict valueForKey:NET_STATUS_NET_SPEED] intValue];
        int vbitrate = [(NSNumber *)[dict valueForKey:NET_STATUS_VIDEO_BITRATE] intValue];
        int abitrate = [(NSNumber *)[dict valueForKey:NET_STATUS_AUDIO_BITRATE] intValue];
        int cachesize = [(NSNumber *)[dict valueForKey:NET_STATUS_VIDEO_CACHE] intValue];
        int dropsize = [(NSNumber *)[dict valueForKey:NET_STATUS_VIDEO_DROP] intValue];
        int jitter = [(NSNumber *)[dict valueForKey:NET_STATUS_NET_JITTER] intValue];
        int fps = [(NSNumber *)[dict valueForKey:NET_STATUS_VIDEO_FPS] intValue];
        int width = [(NSNumber *)[dict valueForKey:NET_STATUS_VIDEO_WIDTH] intValue];
        int height = [(NSNumber *)[dict valueForKey:NET_STATUS_VIDEO_HEIGHT] intValue];
        float cpu_app_usage = [(NSNumber *)[dict valueForKey:NET_STATUS_CPU_USAGE] floatValue];
        float cpu_sys_usage = [(NSNumber *)[dict valueForKey:NET_STATUS_CPU_USAGE_D] floatValue];
        NSString *serverIP = [dict valueForKey:NET_STATUS_SERVER_IP];
        int codecCacheSize = [(NSNumber *)[dict valueForKey:NET_STATUS_AUDIO_CACHE] intValue];
        int nCodecDropCnt = [(NSNumber *)[dict valueForKey:NET_STATUS_AUDIO_DROP] intValue];
        int nCahcedSize = [(NSNumber *)[dict valueForKey:NET_STATUS_VIDEO_CACHE] intValue] / 1000;
        NSString *log = [NSString
                         stringWithFormat:@"CPU:%.1f%%|%.1f%%\tRES:%d*%d\tSPD:%dkb/s\nJITT:%d\tFPS:%d\tARA:%dkb/"
                         @"s\nQUE:%d|%d\tDRP:%d|%d\tVRA:%dkb/s\nSVR:%@\t\tCAH:%d kb",
                         cpu_app_usage * 100, cpu_sys_usage * 100, width, height, netspeed, jitter,
                         fps, abitrate, codecCacheSize, cachesize, nCodecDropCnt, dropsize,
                         vbitrate, serverIP, nCahcedSize];
        [_statusView setText:log];
#ifndef UGC_SMART
        AppDemoLogOnlyFile(
            @"Current status, VideoBitrate:%d, AudioBitrate:%d, FPS:%d, RES:%d*%d, netspeed:%d",
            vbitrate, abitrate, fps, width, height, netspeed);
#endif
    });
}

- (void)startLoadingAnimation {
    if (_loadingImageView != nil) {
        _loadingImageView.hidden = NO;
        [_loadingImageView startAnimating];
    }
}

- (void)stopLoadingAnimation {
    if (_loadingImageView != nil) {
        _loadingImageView.hidden = YES;
        [_loadingImageView stopAnimating];
    }
}

- (BOOL)onPlayerPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    return NO;
}

@end
