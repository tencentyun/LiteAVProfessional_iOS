/**
 * Module:   CameraPushViewController
 *
 * Function: 使用LiteAVSDK完成rtmp推流
 */

#import "CameraPushViewController.h"

#import "AFNetworkReachabilityManager.h"
#import "AppDelegate.h"
#import "CWStatusBarNotification.h"
#import "CameraQRCodeView.h"
#import "CameraStartPushViewController.h"
#import "MBProgressHUD.h"
#import "PushBgmControl.h"
#import "PushLogView.h"
#import "PushMoreSettingViewController.h"
#import "PushSettingViewController.h"
#import "ScanQRController.h"
#import "TCHttpUtil.h"
#import "ThemeConfigurator.h"
#import "UIView+Additions.h"
#import "V2TXLivePusher.h"
// 音效设置面板
#import "AudioEffectSettingKit.h"

#import "AppLocalized.h"
#import "NSString+Common.h"
#import "TCUtil.h"

#define RTMP_PUBLISH_URL @"LivePusherDemo.CameraPush.pleaseinputthepushstream"

@interface CameraPushViewController () <V2TXLivePusherObserver, ScanQRDelegate, BeautyLoadPituDelegate, PushSettingDelegate, PushMoreSettingDelegate, PushBgmControlDelegate, AudioEffectViewDelegate> {
    CameraQRCodeView *       _qrCodeView;
    CWStatusBarNotification *_notification;

    UIView *_localView;  // 本地预览
    BOOL    _appIsInActive;
    BOOL    _appIsBackground;
    BOOL    _isMute;

    TCBeautyPanel *                _beautyPanel;    // 美颜控件
    PushMoreSettingViewController *_moreSettingVC;  // 更多设置
    PushLogView *                  _logView;        // 显示app日志

    UIButton *_btnPush;         // 开始/停止推流
    UIButton *_btnCamera;       // 切换前后摄像头
    UIButton *_btnBeauty;       // 美颜
    UIButton *_btnBgm;          // 背景音乐
    UIButton *_btnLog;          // 日志信息
    UIButton *_btnSetting;      // 主要设置
    UIButton *_btnMoreSetting;  // 更多设置
}

@property(nonatomic, strong) V2TXLivePusher             *pusher;
@property(nonatomic, strong) NSString                   *pushUrl;
@property(nonatomic, strong) V2TXLiveVideoEncoderParam  *videoEncoderParam;
@property(nonatomic, strong) AudioEffectSettingView     *audioEffectView;  // 新BGM面板

@end

@implementation CameraPushViewController

- (instancetype)init {
    if (self = [super init]) {
        _appIsInActive   = NO;
        _appIsBackground = NO;
        _isMute          = NO;
    }
    return self;
}

- (void)dealloc {
    [self.audioEffectView resetAudioSetting];
    [self stopPush];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppDidEnterBackGround:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    // 隐私模式设置跟房间走，每次进来重置为关闭状态
    [PushMoreSettingViewController setDisableVideo:NO];
    
    // 创建推流器
    _pusher = [self createPusher];
    _isMute = [PushMoreSettingViewController isMuteAudio];
    // 界面布局
    [self initUI];
    if (@available(iOS 13.0, *)) {
        self.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.navigationController setNavigationBarHidden:NO animated:NO];
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self.navigationController setNavigationBarHidden:YES animated:NO];
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)onAppWillResignActive:(NSNotification *)notification {
    _appIsInActive = YES;
    [_pusher startVirtualCamera:[UIImage imageNamed:@"pause_publish"]];
}

- (void)onAppDidBecomeActive:(NSNotification *)notification {
    _appIsInActive = NO;
    if (!_appIsBackground && !_appIsInActive) {
        if (![PushMoreSettingViewController isDisableVideo]) {
            [_pusher stopVirtualCamera];
            [self pauseAudio:_isMute];
        }
    }
}

- (void)onAppDidEnterBackGround:(NSNotification *)notification {
    __weak typeof(self) weakSelf = self;
    [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            [strongSelf.pusher startVirtualCamera:[UIImage imageNamed:@"background"]];
        }
    }];
    _appIsBackground = YES;
    [_pusher startVirtualCamera:[UIImage imageNamed:@"pause_publish"]];
}

- (void)onAppWillEnterForeground:(NSNotification *)notification {
    _appIsBackground = NO;
    if (!_appIsBackground && !_appIsInActive) {
        if (![PushMoreSettingViewController isDisableVideo]) {
            [_pusher stopVirtualCamera];
            [self pauseAudio:_isMute];
        }
    }
}

- (void)pauseAudio:(BOOL)isMute {
    if (isMute) {
        [_pusher pauseAudio];
    } else {
        [_pusher resumeAudio];
    }
}

- (void)initUI {
    [self.view setBackgroundImage:[UIImage imageNamed:@"background"]];

    _notification                                  = [CWStatusBarNotification new];
    _notification.notificationLabelBackgroundColor = [UIColor redColor];
    _notification.notificationLabelTextColor       = [UIColor whiteColor];

    int    buttonCount = 7;  // 底部一排按钮的数量
    CGSize size        = [[UIScreen mainScreen] bounds].size;
    int    ICON_SIZE   = size.width / 8;

    _qrCodeView = [[CameraQRCodeView alloc] initWithFrame:self.view.bounds];
    [_qrCodeView loadStreamData:self.streamURLDictionary];
    _qrCodeView.alpha = 0;
    [self.view addSubview:_qrCodeView];

    [self createRightNavigationItem];

    // 创建底部的功能按钮
    float startSpace     = 6;
    float centerInterVal = (size.width - 2 * startSpace - ICON_SIZE) / (buttonCount - 1);
    float iconY          = size.height - ICON_SIZE / 2 - 10;
    if (@available(iOS 11, *)) {
        iconY -= [UIApplication sharedApplication].keyWindow.safeAreaInsets.bottom;
    }

    // 在控制按钮下方加入透明视图，防止误触聚焦
    UIView *buttonContainer = [[UIView alloc] initWithFrame:CGRectMake(0, iconY - ICON_SIZE / 2, self.view.frame.size.width, self.view.frame.size.height - (iconY - ICON_SIZE / 2))];
    [self.view addSubview:buttonContainer];

    _btnPush        = [self createButton:@"start2" action:@selector(clickPush:) center:CGPointMake(startSpace + ICON_SIZE / 2, iconY) size:ICON_SIZE];
    _btnCamera      = [self createButton:@"mlvb_camera_front" action:@selector(clickCamera:) center:CGPointMake(startSpace + ICON_SIZE / 2 + centerInterVal * 1, iconY) size:ICON_SIZE];
    _btnBeauty      = [self createButton:@"mlvb_beauty" action:@selector(clickBeauty:) center:CGPointMake(startSpace + ICON_SIZE / 2 + centerInterVal * 2, iconY) size:ICON_SIZE];
    _btnBgm         = [self createButton:@"music" action:@selector(clickBgm:) center:CGPointMake(startSpace + ICON_SIZE / 2 + centerInterVal * 3, iconY) size:ICON_SIZE];
    _btnLog         = [self createButton:@"log2" action:@selector(clickLog:) center:CGPointMake(startSpace + ICON_SIZE / 2 + centerInterVal * 4, iconY) size:ICON_SIZE];
    _btnSetting     = [self createButton:@"set" action:@selector(clickSetting:) center:CGPointMake(startSpace + ICON_SIZE / 2 + centerInterVal * 5, iconY) size:ICON_SIZE];
    _btnMoreSetting = [self createButton:@"more_b" action:@selector(clickMoreSetting:) center:CGPointMake(startSpace + ICON_SIZE / 2 + centerInterVal * 6, iconY) size:ICON_SIZE];

    // 美颜控件
    NSUInteger controlHeight = [TCBeautyPanel getHeight];
    UIWindow * keyWindow     = UIApplication.sharedApplication.keyWindow;
    CGFloat    bottomOffset  = 0;
    if (@available(iOS 11, *)) {
        bottomOffset = keyWindow.safeAreaInsets.bottom;
    }
    CGRect frame              = CGRectMake(0, self.view.frame.size.height - controlHeight - bottomOffset, self.view.frame.size.width, controlHeight + bottomOffset);
    _beautyPanel              = [TCBeautyPanel beautyPanelWithFrame:frame SDKObject:_pusher];
    _beautyPanel.bottomOffset = bottomOffset;
    [ThemeConfigurator configBeautyPanelTheme:_beautyPanel];
    _beautyPanel.hidden       = YES;
    _beautyPanel.pituDelegate = self;
    [self.view addSubview:_beautyPanel];
    [_beautyPanel resetAndApplyValues];  // 美颜设置初始值

    // BGM 控件
    _audioEffectView = [[AudioEffectSettingView alloc] initWithType:AudioEffectSettingViewDefault];
    if ([TCUtil getDEBUGSwitch]) {
        [_audioEffectView setIsDebugMode];
    }
    [_audioEffectView setAudioEffectManager:[_pusher getAudioEffectManager]];
    _audioEffectView.delegate        = self;
    _audioEffectView.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.8];
    [_audioEffectView hide];
    [self.view addSubview:_audioEffectView];

    // log控件
    _logView                 = [[PushLogView alloc] initWithFrame:CGRectMake(0, self.view.height * 0.2, self.view.width, self.view.height * 0.7)];
    _logView.backgroundColor = [UIColor.whiteColor colorWithAlphaComponent:0.6];
    _logView.hidden          = YES;
    [self.view addSubview:_logView];

    // 本地视频预览view
    _localView = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view insertSubview:_localView atIndex:0];
    _localView.center = self.view.center;

#if TARGET_IPHONE_SIMULATOR
    [self toastTip:LivePlayerLocalize(@"LivePusherDemo.CameraPush.iosemulatordoesnotsupport")];
#endif
}

- (void)createRightNavigationItem {
    UIButton *helpbtn = [UIButton buttonWithType:UIButtonTypeCustom];
    helpbtn.tag       = Help_rtmp推流;
    [helpbtn setFrame:CGRectMake(0, 0, 30, 30)];
    [helpbtn setBackgroundImage:[UIImage imageNamed:@"help_small"] forState:UIControlStateNormal];
    [helpbtn addTarget:[[UIApplication sharedApplication] delegate] action:@selector(clickHelp:) forControlEvents:UIControlEventTouchUpInside];
    [helpbtn sizeToFit];
    UIBarButtonItem *helpItem = [[UIBarButtonItem alloc] initWithCustomView:helpbtn];

    UIButton *qrScanBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [qrScanBtn setFrame:CGRectMake(0, 0, 30, 30)];
    [qrScanBtn setBackgroundImage:[UIImage imageNamed:@"qrcode"] forState:UIControlStateNormal];
    [qrScanBtn addTarget:self action:@selector(qrScanBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *qrScanItem = [[UIBarButtonItem alloc] initWithCustomView:qrScanBtn];

    self.navigationItem.rightBarButtonItems = @[ qrScanItem, helpItem ];
}

- (UIButton *)createButton:(NSString *)icon action:(SEL)action center:(CGPoint)center size:(int)size {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.bounds    = CGRectMake(0, 0, size, size);
    btn.center    = center;
    btn.tag       = 0;  // 用这个来记录按钮的状态，默认0
    [btn setImage:[UIImage imageNamed:icon] forState:UIControlStateNormal];
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    return btn;
}

// 创建推流器，并使用本地配置初始化它
- (V2TXLivePusher *)createPusher {
    // 推流器初始化
    NSInteger pushType     = [[self.streamURLDictionary valueForKey:kPUSH_TYPE] integerValue];
    self.title             = pushType == 0 ? LivePlayerLocalize(@"LivePusherDemo.CameraPush.rtmppullstream") : LivePlayerLocalize(@"LivePusherDemo.CameraPush.rtcpullstream");
    V2TXLivePusher *pusher = [[V2TXLivePusher alloc] initWithLiveMode:pushType == 0 ? V2TXLiveMode_RTMP : V2TXLiveMode_RTC];
    [pusher.getDeviceManager enableCameraTorch:[PushMoreSettingViewController isOpenTorch]];
    [pusher.getDeviceManager enableCameraAutoFocus:![PushMoreSettingViewController isEnableTouchFocus]];
    [pusher setEncoderMirror:[PushMoreSettingViewController isMirrorVideo]];
    [pusher.getAudioEffectManager enableVoiceEarMonitor:[PushSettingViewController getEnableAudioPreview]];
    [self pauseAudio:[PushMoreSettingViewController isMuteAudio]];
    self.videoEncoderParam = [[V2TXLiveVideoEncoderParam alloc] initWith:[PushSettingViewController getVideoQuality]];
    self.videoEncoderParam.videoResolutionMode = [PushMoreSettingViewController isEnableResolutionLandscap] ? V2TXLiveVideoResolutionModeLandscape : V2TXLiveVideoResolutionModePortrait;
    [pusher setVideoQuality:self.videoEncoderParam];
    [pusher setRenderRotation:V2TXLiveRotation0];
    [pusher setProperty:@"setDebugViewMargin" value:@{@"top" : @(120), @"left" : @(10), @"bottom" : @(60), @"right" : @(10)}];
    [pusher showDebugView:[PushMoreSettingViewController isShowDebugLog]];
    NSInteger audioQuality = [PushSettingViewController getAudioQuality];
    [pusher setAudioQuality:audioQuality];
    if ([PushMoreSettingViewController isEnableWaterMark]) {
        [pusher setWatermark:[UIImage imageNamed:@"watermark"] x:0.05 y:0.05 scale:1];
    }
    return pusher;
}

#pragma mark - 控件响应函数
- (void)clickPush:(UIButton *)btn {
    if (_btnPush.tag == 0) {
        if (![self startPush]) {
            return;
        }
        [_btnPush setImage:[UIImage imageNamed:@"stop2"] forState:UIControlStateNormal];
        _btnPush.tag = 1;
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];

    } else {
        [self stopPush];
        [self resetPushUI];
    }
}

- (void)clickCamera:(UIButton *)btn {
    btn.enabled = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        btn.enabled = YES;
    });
    if (_btnCamera.tag == 0) {
        [_pusher.getDeviceManager switchCamera:NO];
        _btnCamera.tag = 1;
        [_btnCamera setImage:[UIImage imageNamed:@"mlvb_camera_back"] forState:UIControlStateNormal];
    } else {
        [_pusher.getDeviceManager switchCamera:YES];
        _btnCamera.tag = 0;
        [_btnCamera setImage:[UIImage imageNamed:@"mlvb_camera_front"] forState:UIControlStateNormal];
        [_moreSettingVC updateOpenTorch:false];
    }
}

- (void)clickBeauty:(UIButton *)btn {
    _beautyPanel.hidden = NO;
    [self hideToolButtons:YES];
    if (_moreSettingVC) {
        [_moreSettingVC willMoveToParentViewController:self];
        [_moreSettingVC.view removeFromSuperview];
        [_moreSettingVC removeFromParentViewController];
        _moreSettingVC.delegate = nil;
        _moreSettingVC          = nil;
    }
}

- (void)clickBgm:(UIButton *)btn {
    [_audioEffectView show];
    if (_moreSettingVC) {
        [_moreSettingVC willMoveToParentViewController:self];
        [_moreSettingVC.view removeFromSuperview];
        [_moreSettingVC removeFromParentViewController];

        [_moreSettingVC setDelegate:nil];
        _moreSettingVC = nil;
    }
}

- (void)clickLog:(UIButton *)btn {
    _logView.hidden = !_logView.hidden;
}

- (void)clickSetting:(UIButton *)btn {
    PushSettingViewController *vc = [[PushSettingViewController alloc] init];
    vc.pusher                     = _pusher;
    [vc setDelegate:self];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)clickMoreSetting:(UIButton *)btn {
    if (!_moreSettingVC) {
        _moreSettingVC          = [[PushMoreSettingViewController alloc] init];
        _moreSettingVC.pusher = self.pusher;
        _moreSettingVC.delegate = self;

        [self addChildViewController:_moreSettingVC];
        _moreSettingVC.view.frame = CGRectMake(0, self.view.height * 0.2, self.view.width, self.view.height * 0.7);

        [self.view addSubview:_moreSettingVC.view];
        [_moreSettingVC didMoveToParentViewController:self];
    } else {
        [_moreSettingVC willMoveToParentViewController:self];
        [_moreSettingVC.view removeFromSuperview];
        [_moreSettingVC removeFromParentViewController];
        _moreSettingVC.delegate = nil;
        _moreSettingVC          = nil;
    }
}

- (void)qrScanBtnClick:(UIButton *)sender {
    [_qrCodeView show];
}

// 隐藏按钮
- (void)hideToolButtons:(BOOL)hide {
    _btnPush.hidden        = hide;
    _btnCamera.hidden      = hide;
    _btnBeauty.hidden      = hide;
    _btnBgm.hidden         = hide;
    _btnLog.hidden         = hide;
    _btnSetting.hidden     = hide;
    _btnMoreSetting.hidden = hide;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
    _beautyPanel.hidden = YES;
    UITouch *touch      = [touches.allObjects lastObject];
    BOOL     result     = [touch.view isDescendantOfView:_audioEffectView];
    if (!result) {
        [_audioEffectView hide];
    }
    if (![_audioEffectView isShow]) {
        [self hideToolButtons:NO];
    }
}

#pragma mark - 推流逻辑

- (BOOL)startPush {
    NSString *pushURL = [self.streamURLDictionary objectForKey:kPUSH_URL];
    if (![pushURL hasPrefix:@"rtmp://"] && ![pushURL hasPrefix:@"trtc://"]) {
        pushURL = LivePlayerLocalize(RTMP_PUBLISH_URL);
        [self toastTip:LivePlayerLocalize(@"LivePusherDemo.CameraPush.pushstreamaddressisnotvalid")];
        [_logView setPushUrlValid:NO];
        return NO;
    }

    [_logView setPushUrlValid:YES];

    // 设置delegate
    [_pusher setObserver:self];

    // 开启预览
    [_pusher setRenderView:_localView];
    [_pusher startCamera:_btnCamera.tag == 0];
    [_pusher startMicrophone];
    [self pauseAudio:_isMute];
    if ([PushMoreSettingViewController isDisableVideo]) {
        [_pusher startVirtualCamera:[UIImage imageNamed:@"pause_publish"]];
    } else {
        [_pusher stopVirtualCamera];
    }
    // 开始推流
    V2TXLiveCode ret = [_pusher startPush:pushURL];
    if (ret != V2TXLIVE_OK) {
        [self toastTip:[NSString stringWithFormat:@"%@: %ld", LivePlayerLocalize(@"LivePusherDemo.CameraPush.thethrusterfailedtostart"), (long)ret]];
        NSLog(@"%@", LivePlayerLocalize(@"LivePusherDemo.CameraPush.thethrusterfailedtostart"));
        return NO;
    }

    // 保存推流地址，其他地方需要
    _pushUrl = pushURL;

    return YES;
}

- (void)stopPush {
    if (_pusher) {
        [_pusher setObserver:nil];
        [_pusher setRenderView:nil];
        [_pusher stopPush];
    }
}

#pragma mark - HUD
- (void)showInProgressText:(NSString *)text {
    MBProgressHUD *hud = [MBProgressHUD HUDForView:self.view];
    if (hud == nil) {
        hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    }
    hud.mode                   = MBProgressHUDModeIndeterminate;
    hud.label.text             = text;
    hud.userInteractionEnabled = NO;
    [hud showAnimated:YES];
}

- (void)showText:(NSString *)text {
    [self showText:text withDetailText:nil];
}

- (void)showText:(NSString *)text withDetailText:(NSString *)detail {
    MBProgressHUD *hud    = [MBProgressHUD HUDForView:self.view];
    hud.mode              = MBProgressHUDModeText;
    hud.label.text        = text;
    hud.detailsLabel.text = detail;
    [hud showAnimated:YES];
    [hud hideAnimated:YES afterDelay:2];
}

- (void)showText:(NSString *)text withDetailText:(NSString *)detail onView:(UIView *)view {
    MBProgressHUD *hud = [MBProgressHUD HUDForView:view];
    if (hud == nil) {
        hud = [MBProgressHUD showHUDAddedTo:view animated:NO];
    }
    hud.mode              = MBProgressHUDModeText;
    hud.label.text        = text;
    hud.detailsLabel.text = detail;
    [hud showAnimated:YES];
    [hud hideAnimated:YES afterDelay:2];
}

- (void)onCloseHUD:(id)sender {
    [[MBProgressHUD HUDForView:self.view] hideAnimated:YES];
}

- (void)checkNet {
    BOOL isWifi = [AFNetworkReachabilityManager sharedManager].reachableViaWiFi;
    if (!isWifi) {
        __weak __typeof(self) weakSelf = self;
        [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            if (weakSelf.pushUrl.length == 0) {
                return;
            }
            if (status == AFNetworkReachabilityStatusReachableViaWiFi) {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@""
                                                                               message:LivePlayerLocalize(@"LivePusherDemo.CameraPush.changetowifipushstream")
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:LivePlayerLocalize(@"LivePlayerDemo.PlayViewController.yes")
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction *_Nonnull action) {
                                                            [alert dismissViewControllerAnimated:YES completion:nil];

                                                            // 先暂停，再重新推流
                                                            [weakSelf stopPush];
                                                            [weakSelf startPush];
                                                        }]];
                [alert addAction:[UIAlertAction actionWithTitle:LivePlayerLocalize(@"LivePlayerDemo.PlayViewController.no")
                                                          style:UIAlertActionStyleCancel
                                                        handler:^(UIAlertAction *_Nonnull action) {
                                                            [alert dismissViewControllerAnimated:YES completion:nil];
                                                        }]];
                [weakSelf presentViewController:alert animated:YES completion:nil];
            }
        }];
    }
}

#pragma mark - V2TXLivePusherObserver

- (void)onError:(V2TXLiveCode)code message:(NSString *)msg extraInfo:(NSDictionary *)extraInfo {
    long errorCode = (long)code;
    if (errorCode == V2TXLIVE_WARNING_MICROPHONE_NO_PERMISSION || errorCode == V2TXLIVE_WARNING_MICROPHONE_START_FAILED) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self toastTip:LivePlayerLocalize(@"LiveLinkMicDemoOld.MLVBLiveRoom.failedtogetmicrophonepermission")];
        });
    }
    if (errorCode == V2TXLIVE_WARNING_CAMERA_NO_PERMISSION || errorCode == V2TXLIVE_WARNING_CAMERA_START_FAILED) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self toastTip:LivePlayerLocalize(@"LiveLinkMicDemoOld.MLVBLiveRoom.failedtogetcamerapermission")];
        });
    }
    if (errorCode == V2TXLIVE_ERROR_REQUEST_TIMEOUT) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self toastTip:LivePlayerLocalize(@"LiveLinkMicDemoOld.MLVBLiveRoom.networktimeout")];
        });
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self stopPush];
        [self resetPushUI];
    });
}

- (void)onWarning:(V2TXLiveCode)code message:(NSString *)msg extraInfo:(NSDictionary *)extraInfo {
    NSLog(@"code:%ld, msg:%@, extraInfo:%@", (long)code, msg, extraInfo);
    long warningCode = (long)code;
    if (warningCode == V2TXLIVE_WARNING_MICROPHONE_NO_PERMISSION || warningCode == V2TXLIVE_WARNING_MICROPHONE_START_FAILED) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self toastTip:LivePlayerLocalize(@"LiveLinkMicDemoOld.MLVBLiveRoom.failedtogetmicrophonepermission")];
        });
    }
    if (warningCode == V2TXLIVE_WARNING_CAMERA_NO_PERMISSION || warningCode == V2TXLIVE_WARNING_CAMERA_START_FAILED) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self toastTip:LivePlayerLocalize(@"LiveLinkMicDemoOld.MLVBLiveRoom.failedtogetcamerapermission")];
        });
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self stopPush];
        [self resetPushUI];
    });
}

- (void)resetPushUI {
    [_logView clear];
    [self.audioEffectView resetBgmSelectItemStatus];
    [_btnPush setImage:[UIImage imageNamed:@"start2"] forState:UIControlStateNormal];
    _btnPush.tag = 0;
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
}

- (void)onCaptureFirstAudioFrame {
    NSLog(@"onCaptureFirstAudioFrame");
}

- (void)onCaptureFirstVideoFrame {
    NSLog(@"onCaptureFirstVideoFrame");
    [_pusher.getDeviceManager enableCameraTorch:[PushMoreSettingViewController isOpenTorch]];
}

- (void)onMicrophoneVolumeUpdate:(NSInteger)volume {
    NSLog(@"volume:%ld", (long)volume);
}

- (void)onStatisticsUpdate:(V2TXLivePusherStatistics *)statistics {
    // 这里可以上报相关推流信息到业务服务器
    // 比如：码率，分辨率，帧率，cpu使用，缓存等信息
    // 字段请在TXLiveSDKTypeDef.h中定义
    NSDictionary *param = @{
        @"CPU_USAGE" : @(statistics.systemCpu / 100.0),
        @"CPU_USAGE_DEVICE" : @(statistics.appCpu / 100.0),
        @"VIDEO_FPS" : @(statistics.fps),
        @"VIDEO_WIDTH" : @(statistics.width),
        @"VIDEO_HEIGHT" : @(statistics.height),
        @"VIDEO_BITRATE" : @(statistics.videoBitrate),
        @"AUDIO_BITRATE" : @(statistics.audioBitrate)
    };
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_logView setNetStatus:param];
    });
}

- (void)onPushStatusUpdate:(V2TXLivePushStatus)state message:(NSString *)msg extraInfo:(NSDictionary *)extraInfo {
    if (state == V2TXLivePushStatusDisconnected) {
        [self clickPush:self->_btnPush];
    } else if (state == V2TXLivePushStatusConnectSuccess) {
        [self checkNet];
    }
}

- (void)onSnapshotComplete:(TXImage *)img {
    if (img != nil) {
        __block CGImageRef cgImage    = img.CGImage;
        UIImage *          finalImage = img;
        if (!cgImage) {
            CIContext *ciContext = [[CIContext alloc] init];
            cgImage              = [ciContext createCGImage:img.CIImage fromRect:img.CIImage.extent];
            finalImage           = [UIImage imageWithCGImage:cgImage];
        }
        NSArray *                 images = @[ finalImage ];
        UIActivityViewController *vc     = [[UIActivityViewController alloc] initWithActivityItems:images applicationActivities:nil];
        [self.navigationController presentViewController:vc animated:YES completion:nil];
    }
}

#pragma mark - AudioEffectViewDelegate
- (void)onEffectViewHidden:(BOOL)isHidden {
    [self hideToolButtons:!isHidden];
}

#pragma mark - BeautyLoadPituDelegate

- (void)onLoadPituStart {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showInProgressText:LivePlayerLocalize(@"LivePusherDemo.CameraPush.startloadingassets")];
    });
}

- (void)onLoadPituProgress:(CGFloat)progress {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showInProgressText:LocalizeReplaceXX(LivePlayerLocalize(@"LivePusherDemo.CameraPush.loadingxx"), [NSString stringWithFormat:@"%d", (int)(progress * 100)])];
    });
}

- (void)onLoadPituFinished {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showText:LivePlayerLocalize(@"LivePusherDemo.CameraPush.assetsloadsuccess")];
    });
}

- (void)onLoadPituFailed {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showText:LivePlayerLocalize(@"LivePusherDemo.CameraPush.assetsloadfailed")];
    });
}

#pragma mark - PushSettingDelegate
// 是否开启耳返
- (void)onPushSetting:(PushSettingViewController *)vc enableAudioPreview:(BOOL)enableAudioPreview {
    [_pusher.getAudioEffectManager enableVoiceEarMonitor:enableAudioPreview];
}

// 画质类型
- (void)onPushSetting:(PushSettingViewController *)vc videoQuality:(V2TXLiveVideoResolution)videoQuality {
    self.videoEncoderParam.videoResolution = videoQuality;
    [_pusher setVideoQuality:self.videoEncoderParam];
}

- (void)onPushSetting:(PushSettingViewController *)vc audioQuality:(V2TXLiveAudioQuality)qulity {
    [_pusher setAudioQuality:qulity];
}

- (void)onPushSetting:(PushSettingViewController *)vc seiMessagePayloadType:(int)payloadType data:(NSData *)data {
    V2TXLiveCode result = [_pusher sendSeiMessage:payloadType data:data];
    NSLog(@"[Pusher] onPushSetting seiMessage, payloadType: %d data: %@ ret: %ld", payloadType, data, (long)result);
    if (result == V2TXLIVE_OK) {
        [self showText:LivePlayerLocalize(@"LivePusherDemo.CameraPush.seimessagesendsuccess") withDetailText:nil onView:vc.view];
    } else {
        [self showText:LivePlayerLocalize(@"LivePusherDemo.CameraPush.seimessagesendfailed") withDetailText:nil onView:vc.view];
    }
}

#pragma mark - PushMoreSettingDelegate
// 是否开启隐私模式（停止上行摄像头数据，并发送pauseImg图片）
- (void)onPushMoreSetting:(PushMoreSettingViewController *)vc disableVideo:(BOOL)disable {
    if (_pusher.isPushing) {
        if (disable) {
            [_pusher startVirtualCamera:[UIImage imageNamed:@"pause_publish"]];
        } else {
            [_pusher stopVirtualCamera];
            [self pauseAudio:_isMute];
        }
    }
}

// 是否开启静音模式（发送静音数据，但是不关闭麦克风）
- (void)onPushMoreSetting:(PushMoreSettingViewController *)vc muteAudio:(BOOL)mute {
    [self pauseAudio:mute];
    _isMute = mute;
}

// 是否开启观看端镜像
- (void)onPushMoreSetting:(PushMoreSettingViewController *)vc mirrorVideo:(BOOL)mirror {
    [_pusher setEncoderMirror:mirror];
}

// 是否开启后置闪光灯
- (void)onPushMoreSetting:(PushMoreSettingViewController *)vc openTorch:(BOOL)open {
    [_pusher.getDeviceManager enableCameraTorch:open];
}

// 是否开启调试信息
- (void)onPushMoreSetting:(PushMoreSettingViewController *)vc debugLog:(BOOL)show {
    [_pusher showDebugView:show];
}

// 是否添加图像水印
- (void)onPushMoreSetting:(PushMoreSettingViewController *)vc waterMark:(BOOL)enable {
    if (enable) {
        [_pusher setWatermark:[UIImage imageNamed:@"watermark"] x:0.03 y:0.015 scale:1];
    } else {
        [_pusher setWatermark:nil x:0.03 y:0.015 scale:1];
    }
}

// 是否开启手动点击曝光对焦
- (void)onPushMoreSetting:(PushMoreSettingViewController *)vc touchFocus:(BOOL)enable {
    [_pusher.getDeviceManager enableCameraAutoFocus:!enable];
}

// 是否开启横屏推流
- (void)onPushMoreSetting:(PushMoreSettingViewController *)vc resolutionLandscap:(BOOL)enable {
    self.videoEncoderParam.videoResolutionMode = enable ? V2TXLiveVideoResolutionModeLandscape : V2TXLiveVideoResolutionModePortrait;
    [_pusher setVideoQuality:self.videoEncoderParam];
}

// 本地截图
- (void)onPushMoreSettingSnapShot:(PushMoreSettingViewController *)vc {
    [_pusher snapshot];
}

// 弹框提示
- (void)onPushMoreSetting:(PushMoreSettingViewController *)vc alertTips:(NSString *)text {
    [self showText:text withDetailText:@"" onView:vc.view];
}

#pragma mark - 辅助函数

/**
 * @method 获取指定宽度width的字符串在UITextView上的高度
 * @param textView 待计算的UITextView
 * @param width 限制字符串显示区域的宽度
 * @return 返回的高度
 */
- (float)heightForString:(UITextView *)textView andWidth:(float)width {
    CGSize sizeToFit = [textView sizeThatFits:CGSizeMake(width, MAXFLOAT)];
    return sizeToFit.height;
}

- (void)toastTip:(NSString *)toastInfo {
    CGRect frameRC   = [[UIScreen mainScreen] bounds];
    frameRC.origin.y = frameRC.size.height - 110;
    frameRC.size.height -= 110;
    __block UITextView *toastView = [[UITextView alloc] init];

    toastView.editable   = NO;
    toastView.selectable = NO;

    frameRC.size.height = [self heightForString:toastView andWidth:frameRC.size.width];

    toastView.frame = frameRC;

    toastView.text            = toastInfo;
    toastView.backgroundColor = [UIColor whiteColor];
    toastView.alpha           = 0.5;

    [self.view addSubview:toastView];

    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC);

    dispatch_after(popTime, dispatch_get_main_queue(), ^() {
        [toastView removeFromSuperview];
        toastView = nil;
    });
}

@end
