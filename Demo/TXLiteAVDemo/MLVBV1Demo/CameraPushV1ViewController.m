/**
 * Module:   CameraPushV1ViewController
 *
 * Function: 使用LiteAVSDK完成rtmp推流
 */

#import "CameraPushV1ViewController.h"
#import "PushSettingV1ViewController.h"
#import "PushMoreSettingV1ViewController.h"
#import "TXLivePush.h"
#import "UIView+Additions.h"
#import "AppDelegate.h"
#import "ScanQRController.h"
#import "AddressBarController.h"
#import "ThemeConfigurator.h"
#import "PushBgmControl.h"
#import "PushLogView.h"
#import "TCHttpUtil.h"
#import "MBProgressHUD.h"
#import "AFNetworkReachabilityManager.h"
#import "CWStatusBarNotification.h"
// 音效设置面板
#import "AudioEffectSettingKit.h"
#import "AppLocalized.h"
#import "NSString+Common.h"
#import "TCUtil.h"

#ifdef ENABLE_CUSTOM_MODE_AUDIO_CAPTURE
#import "CustomAudioFileReader.h"
#define CUSTOM_AUDIO_CAPTURE_SAMPLERATE 48000
#define CUSTOM_AUDIO_CAPTURE_CHANNEL 1
#endif

#define RTMP_PUBLISH_URL    @"LivePusherDemo.CameraPush.pleaseinputthepushstream"

@interface CameraPushV1ViewController () <
TXLivePushListener,
ScanQRDelegate,
BeautyLoadPituDelegate,
PushSettingV1Delegate,
PushMoreSettingV1Delegate,
AddressBarControllerDelegate,
#ifdef ENABLE_CUSTOM_MODE_AUDIO_CAPTURE
CustomAudioFileReaderDelegate,
#endif
PushBgmControlDelegate,
AudioEffectViewDelegate
>
{
    BOOL                                _appIsInActive;
    BOOL                                _appIsBackground;
    BOOL                                _isMute;
    AddressBarController                *_addressBarController;  // 推流地址/二维码扫描 工具栏
    CWStatusBarNotification             *_notification;
    UIView                              *_localView;    // 本地预览
    TCBeautyPanel                       *_beautyPanel;    // 美颜控件
    PushMoreSettingV1ViewController    *_moreSettingVC;  // 更多设置
    PushLogView                         *_logView;        // 显示app日志
    UIButton                            *_btnPush;        // 开始/停止推流
    UIButton                            *_btnCamera;      // 切换前后摄像头
    UIButton                            *_btnBeauty;      // 美颜
    UIButton                            *_btnBgm;         // 背景音乐
    UIButton                            *_btnLog;         // 日志信息
    UIButton                            *_btnSetting;     // 主要设置
    UIButton                            *_btnMoreSetting; // 更多设置
}

@property (nonatomic, strong) TXLivePush                *pusher;
@property (nonatomic, strong) NSString                  *pushUrl;
@property (nonatomic, strong) AudioEffectSettingView    *audioEffectView; // 新BGM面板

@end

@implementation CameraPushV1ViewController

- (instancetype)init {
    if (self = [super init]) {
        _appIsInActive = NO;
        _appIsBackground = NO;
        _isMute = NO;
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
    [PushMoreSettingV1ViewController setDisableVideo:NO];
    
    // 创建推流器
    _pusher = [self createPusher];
    _isMute = [PushMoreSettingV1ViewController isMuteAudio];
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
    [_pusher pausePush];
}

- (void)onAppDidBecomeActive:(NSNotification *)notification {
    _appIsInActive = NO;
    if (!_appIsBackground && !_appIsInActive) {
        if (![PushMoreSettingV1ViewController isDisableVideo]) {
            [_pusher resumePush];
            [_pusher setMute:_isMute];
        }
    }
}

- (void)onAppDidEnterBackGround:(NSNotification *)notification {
    [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        
    }];
    _appIsBackground = YES;
    [_pusher pausePush];
}

- (void)onAppWillEnterForeground:(NSNotification *)notification {
    _appIsBackground = NO;
    if (!_appIsBackground && !_appIsInActive) {
        if (![PushMoreSettingV1ViewController isDisableVideo]) {
            [_pusher resumePush];
            [_pusher setMute:_isMute];
        }
    }
}

- (void)initUI {
    self.title = LivePlayerLocalize(@"LivePusherDemo.CameraPush.rtmppullstream");
    [self.view setBackgroundImage:[UIImage imageNamed:@"background"]];
    
    _notification = [CWStatusBarNotification new];
    _notification.notificationLabelBackgroundColor = [UIColor redColor];
    _notification.notificationLabelTextColor = [UIColor whiteColor];
    
    int buttonCount = 7; // 底部一排按钮的数量
    CGSize size = [[UIScreen mainScreen] bounds].size;
    int ICON_SIZE = size.width / 8;
    
    // 设置推流地址输入、二维码扫描工具栏
    _addressBarController = [[AddressBarController alloc] initWithButtonOption:AddressBarButtonOptionNew | AddressBarButtonOptionQRScan];
    _addressBarController.qrPresentView = self.view;
    CGFloat topOffset = [UIApplication sharedApplication].statusBarFrame.size.height;
    topOffset += (self.navigationController.navigationBar.height + 5);
    if (@available(iOS 11.0, *)) {
        topOffset = [UIApplication sharedApplication].keyWindow.safeAreaInsets.top + 44;
    }
    _addressBarController.view.frame = CGRectMake(10, topOffset, self.view.width-20, ICON_SIZE);
    NSDictionary *dic = @{NSForegroundColorAttributeName:[UIColor blackColor], NSFontAttributeName:[UIFont systemFontOfSize:[NSString isCurrentLanguageEnglish] ? 13 : 15]};
    _addressBarController.view.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:LivePlayerLocalize(RTMP_PUBLISH_URL) attributes:dic];
    _addressBarController.delegate = self;
    [self.view addSubview:_addressBarController.view];
    
    // 右上角Help按钮
    HelpBtnUI(rtmp推流)
    
    // 创建底部的功能按钮
    float startSpace = 6;
    float centerInterVal = (size.width - 2 * startSpace - ICON_SIZE) / (buttonCount - 1);
    float iconY = size.height - ICON_SIZE / 2 - 10;
    if (@available(iOS 11, *)) {
        iconY -= [UIApplication sharedApplication].keyWindow.safeAreaInsets.bottom;
    }
    
    // 在控制按钮下方加入透明视图，防止误触聚焦
    UIView *buttonContainer = [[UIView alloc] initWithFrame:CGRectMake(0, iconY - ICON_SIZE / 2, self.view.frame.size.width, self.view.frame.size.height - (iconY - ICON_SIZE / 2))];
    [self.view addSubview:buttonContainer];
    
    _btnPush = [self createButton:@"start2" action:@selector(clickPush:)
                           center:CGPointMake(startSpace + ICON_SIZE / 2, iconY) size:ICON_SIZE];
    _btnCamera = [self createButton:@"mlvb_camera_front" action:@selector(clickCamera:)
                             center:CGPointMake(startSpace + ICON_SIZE / 2 + centerInterVal * 1, iconY) size:ICON_SIZE];
    _btnBeauty = [self createButton:@"mlvb_beauty" action:@selector(clickBeauty:)
                             center:CGPointMake(startSpace + ICON_SIZE / 2 + centerInterVal * 2, iconY) size:ICON_SIZE];
    _btnBgm = [self createButton:@"music" action:@selector(clickBgm:)
                          center:CGPointMake(startSpace + ICON_SIZE / 2 + centerInterVal * 3, iconY) size:ICON_SIZE];
    _btnLog = [self createButton:@"log2" action:@selector(clickLog:)
                          center:CGPointMake(startSpace + ICON_SIZE / 2 + centerInterVal * 4, iconY) size:ICON_SIZE];
    _btnSetting = [self createButton:@"set" action:@selector(clickSetting:)
                              center:CGPointMake(startSpace + ICON_SIZE / 2 + centerInterVal * 5, iconY) size:ICON_SIZE];
    _btnMoreSetting = [self createButton:@"more_b" action:@selector(clickMoreSetting:)
                                  center:CGPointMake(startSpace + ICON_SIZE / 2 + centerInterVal * 6, iconY) size:ICON_SIZE];
    
    // 美颜控件
    NSUInteger controlHeight = [TCBeautyPanel getHeight];
    UIWindow *keyWindow = UIApplication.sharedApplication.keyWindow;
    CGFloat bottomOffset = 0;
    if (@available(iOS 11, *)) {
        bottomOffset = keyWindow.safeAreaInsets.bottom;
    }
    CGRect frame = CGRectMake(0, self.view.frame.size.height - controlHeight - bottomOffset,
                              self.view.frame.size.width, controlHeight + bottomOffset);
    _beautyPanel = [TCBeautyPanel beautyPanelWithFrame:frame
                                             SDKObject:_pusher];
    _beautyPanel.bottomOffset = bottomOffset;
    [ThemeConfigurator configBeautyPanelTheme:_beautyPanel];
    _beautyPanel.hidden = YES;
    _beautyPanel.pituDelegate = self;
    [self.view addSubview:_beautyPanel];
    [_beautyPanel resetAndApplyValues]; // 美颜设置初始值
    
    // BGM 控件
    _audioEffectView = [[AudioEffectSettingView alloc] initWithType:AudioEffectSettingViewDefault];
    if ([TCUtil getDEBUGSwitch]) {
        [_audioEffectView setIsDebugMode];
    }
    [_audioEffectView setAudioEffectManager:[_pusher getAudioEffectManager]];
    _audioEffectView.delegate = self;
    _audioEffectView.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.8];
    [_audioEffectView hide];
    [self.view addSubview:_audioEffectView];
    // log控件
    _logView = [[PushLogView alloc] initWithFrame:CGRectMake(0, self.view.height * 0.2, self.view.width, self.view.height * 0.7)];
    _logView.backgroundColor = [UIColor.whiteColor colorWithAlphaComponent:0.6];
    _logView.hidden = YES;
    [self.view addSubview:_logView];
    
    
    // 本地视频预览view
    _localView = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view insertSubview:_localView atIndex:0];
    _localView.center = self.view.center;
    
#if TARGET_IPHONE_SIMULATOR
    [self toastTip:LivePlayerLocalize(@"LivePusherDemo.CameraPush.iosemulatordoesnotsupport")];
#endif
}

- (UIButton *)createButton:(NSString *)icon action:(SEL)action center:(CGPoint)center size:(int)size {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.bounds = CGRectMake(0, 0, size, size);
    btn.center = center;
    btn.tag = 0; // 用这个来记录按钮的状态，默认0
    [btn setImage:[UIImage imageNamed:icon] forState:UIControlStateNormal];
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    return btn;
}

// 创建推流器，并使用本地配置初始化它
- (TXLivePush *)createPusher {
    // config初始化
    TXLivePushConfig *config = [[TXLivePushConfig alloc] init];
    config.pauseFps = 10;
    config.pauseTime = 300;
    config.pauseImg = [UIImage imageNamed:@"pause_publish"];
    config.touchFocus = [PushMoreSettingV1ViewController isEnableTouchFocus];
    config.enableZoom = [PushMoreSettingV1ViewController isEnableVideoZoom];
    config.enablePureAudioPush = [PushMoreSettingV1ViewController isEnablePureAudioPush];
    config.enableAudioPreview = [PushSettingV1ViewController getEnableAudioPreview];
    NSInteger audioQuality = [PushSettingV1ViewController getAudioQuality];
    switch (audioQuality) {
        case 2:
            // 音乐音质，采样率48000
            config.audioChannels = 2;
            config.audioSampleRate = AUDIO_SAMPLE_RATE_48000;
            break;
        case 1:
            // 标准音质，采样率48000
            config.audioChannels = 1;
            config.audioSampleRate = AUDIO_SAMPLE_RATE_48000;
            break;
        case 0:
            // 语音音质，采样率16000
            config.audioChannels = 1;
            config.audioSampleRate = AUDIO_SAMPLE_RATE_16000;
            break;
        default:
            break;
    }
    config.frontCamera = _btnCamera.tag == 0 ? YES : NO;
    if ([PushMoreSettingV1ViewController isEnableWaterMark]) {
        config.watermark = [UIImage imageNamed:@"watermark"];
        config.watermarkPos = CGPointMake(10, 10);
    }
    // 推流器初始化
    TXLivePush *pusher = [[TXLivePush alloc] initWithConfig:config];
    [pusher toggleTorch:[PushMoreSettingV1ViewController isOpenTorch]];
    [pusher setMirror:[PushMoreSettingV1ViewController isMirrorVideo]];
    [pusher setMute:[PushMoreSettingV1ViewController isMuteAudio]];
    [pusher setVideoQuality:[PushSettingV1ViewController getVideoQuality] adjustBitrate:[PushSettingV1ViewController getBandWidthAdjust] adjustResolution:NO];
    
#ifdef ENABLE_CUSTOM_MODE_AUDIO_CAPTURE
    config.enableAEC = NO;
    config.customModeType = CUSTOM_MODE_AUDIO_CAPTURE;
    config.audioSampleRate = CUSTOM_AUDIO_CAPTURE_SAMPLERATE;
    config.audioChannels = CUSTOM_AUDIO_CAPTURE_CHANNEL;
#endif
    [self onPushMoreSetting:nil enableHEVC:[PushMoreSettingV1ViewController isEnableHEVC]];
    // 修改软硬编需要在setVideoQuality之后设置config.enableHWAcceleration
    config.enableHWAcceleration = [PushSettingV1ViewController getEnableHWAcceleration];
    
    // 横屏推流需要先设置config.homeOrientation = HOME_ORIENTATION_RIGHT，然后再[pusher setRenderRotation:90]
    config.homeOrientation = ([PushMoreSettingV1ViewController isHorizontalPush] ? HOME_ORIENTATION_RIGHT : HOME_ORIENTATION_DOWN);
    if ([PushMoreSettingV1ViewController isHorizontalPush]) {
        [pusher setRenderRotation:90];
    } else {
        [pusher setRenderRotation:0];
    }
    
    [pusher setLogViewMargin:UIEdgeInsetsMake(120, 10, 60, 10)];
    [pusher showVideoDebugLog:[PushMoreSettingV1ViewController isShowDebugLog]];
    [pusher setEnableClockOverlay:[PushMoreSettingV1ViewController isEnableDelayCheck]];
    
    [pusher setConfig:config];
    
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
        [_logView clear];
        [self.audioEffectView resetBgmSelectItemStatus];
        [_btnPush setImage:[UIImage imageNamed:@"start2"] forState:UIControlStateNormal];
        _btnPush.tag = 0;
        [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    }
}

- (void)clickCamera:(UIButton *)btn {
    btn.enabled = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        btn.enabled = YES;
    });
    if (_btnCamera.tag == 0) {
        [_pusher switchCamera];
        _btnCamera.tag = 1;
        [_btnCamera setImage:[UIImage imageNamed:@"mlvb_camera_back"] forState:UIControlStateNormal];
    } else {
        [_pusher switchCamera];
        _btnCamera.tag = 0;
        [_btnCamera setImage:[UIImage imageNamed:@"mlvb_camera_front"] forState:UIControlStateNormal];
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
        _moreSettingVC = nil;
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
    PushSettingV1ViewController *vc = [[PushSettingV1ViewController alloc] init];
    [vc setDelegate:self];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)clickMoreSetting:(UIButton *)btn {
    if (!_moreSettingVC) {
        _moreSettingVC = [[PushMoreSettingV1ViewController alloc] init];
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
        _moreSettingVC = nil;
    }
}

// 隐藏按钮
- (void)hideToolButtons:(BOOL)hide {
    _btnPush.hidden = hide;
    _btnCamera.hidden = hide;
    _btnBeauty.hidden = hide;
    _btnBgm.hidden = hide;
    _btnLog.hidden = hide;
    _btnSetting.hidden = hide;
    _btnMoreSetting.hidden = hide;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
    _beautyPanel.hidden = YES;
    UITouch *touch = [touches.allObjects lastObject];
    BOOL result = [touch.view isDescendantOfView:_audioEffectView];
    if (!result) {
        [_audioEffectView hide];
    }
    if (![_audioEffectView isShow]) {
        [self hideToolButtons:NO];
    }
}

#pragma mark - 推流逻辑
- (BOOL)startPush {
    NSString *rtmpUrl = _addressBarController.text;
    
    if (!([rtmpUrl hasPrefix:@"rtmp://"])) {
        rtmpUrl = LivePlayerLocalize(RTMP_PUBLISH_URL);
    }
    
    if (!([rtmpUrl hasPrefix:@"rtmp://"])) {
        [self toastTip:LivePlayerLocalize(@"LivePusherDemo.CameraPush.pushstreamaddressisnotvalid")];
        [_logView setPushUrlValid:NO];
        return NO;
    }
    
    [_logView setPushUrlValid:YES];
    
    // 检查摄像头权限
    AVAuthorizationStatus statusVideo = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (statusVideo == AVAuthorizationStatusDenied) {
        [self toastTip:LivePlayerLocalize(@"LiveLinkMicDemoOld.MLVBLiveRoom.failedtogetcamerapermission")];
        return NO;
    }
    
    // 检查麦克风权限
    AVAuthorizationStatus statusAudio = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if (statusAudio == AVAuthorizationStatusDenied) {
        [self toastTip:LivePlayerLocalize(@"LiveLinkMicDemoOld.MLVBLiveRoom.failedtogetmicrophonepermission")];
        return NO;
    }
    
    // 还原设置
    [PushMoreSettingV1ViewController setDisableVideo:NO];
    
    // 设置delegate
    [_pusher setDelegate:self];
    
    // 开启预览
    [_pusher startPreview:_localView];
    
#ifdef ENABLE_CUSTOM_MODE_AUDIO_CAPTURE
    [CustomAudioFileReader sharedInstance].delegate = self;
    [[CustomAudioFileReader sharedInstance] start:CUSTOM_AUDIO_CAPTURE_SAMPLERATE
                                         channels:CUSTOM_AUDIO_CAPTURE_CHANNEL
                                  framLenInSample:1024];
#endif
    
    // 开始推流
    int ret = [_pusher startPush:rtmpUrl];
    if (ret != 0) {
        [self toastTip:[NSString stringWithFormat:@"%@: %d",LivePlayerLocalize(@"LivePusherDemo.CameraPush.thethrusterfailedtostart"), ret]];
        NSLog(@"%@",LivePlayerLocalize(@"LivePusherDemo.CameraPush.thethrusterfailedtostart"));
        return NO;
    }
    // 保存推流地址，其他地方需要
    _pushUrl = rtmpUrl;
    return YES;
}

- (void)stopPush {
    if (_pusher) {
        [_pusher setDelegate:nil];
        [_pusher stopPreview];
        [_pusher stopPush];
    }
#ifdef ENABLE_CUSTOM_MODE_AUDIO_CAPTURE
    [[CustomAudioFileReader sharedInstance] stop];
    [CustomAudioFileReader sharedInstance].delegate = nil;
#endif
}

#pragma mark - HUD
- (void)showInProgressText:(NSString *)text {
    MBProgressHUD *hud = [MBProgressHUD HUDForView:self.view];
    if (hud == nil) {
        hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    }
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.label.text = text;
    hud.userInteractionEnabled = NO;
    [hud showAnimated:YES];
}

- (void)showText:(NSString *)text {
    [self showText:text withDetailText:nil];
}

- (void)showText:(NSString *)text withDetailText:(NSString *)detail {
    MBProgressHUD *hud = [MBProgressHUD HUDForView:self.view];
    hud.mode = MBProgressHUDModeText;
    hud.label.text = text;
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
                [alert addAction:[UIAlertAction actionWithTitle:LivePlayerLocalize(@"LivePlayerDemo.PlayViewController.yes") style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
                    [alert dismissViewControllerAnimated:YES completion:nil];
                    
                    // 先暂停，再重新推流
                    [weakSelf stopPush];
                    [weakSelf startPush];
                }]];
                [alert addAction:[UIAlertAction actionWithTitle:LivePlayerLocalize(@"LivePlayerDemo.PlayViewController.no") style:UIAlertActionStyleCancel handler:^(UIAlertAction *_Nonnull action) {
                    [alert dismissViewControllerAnimated:YES completion:nil];
                }]];
                [weakSelf presentViewController:alert animated:YES completion:nil];
            }
        }];
    }
}

#pragma mark - AddressBarControllerDelegate
// 从业务后台获取推流地址
- (void)addressBarControllerTapCreateURL:(AddressBarController *)controller {
    if (_btnPush.tag == 1) {
        [self clickPush:_btnPush];
    }
    [self showInProgressText:LivePlayerLocalize(@"LivePusherDemo.CameraPush.addressacquisitioninprocess")];
    __weak typeof(self)weakSelf = self;
    [TCHttpUtil asyncSendHttpRequest:@"get_test_pushurl" httpServerAddr:kHttpServerAddr HTTPMethod:@"GET" param:nil handler:^(int result, NSDictionary *resultDict) {
        if (result != 0 || resultDict == nil) {
            [weakSelf showText:LivePlayerLocalize(@"LivePusherDemo.CameraPush.failedtogetpushstreamaddress")];
        } else {
            NSString *pusherUrl = resultDict[@"url_push"];
            NSString *rtmpPlayUrl = resultDict[@"url_play_rtmp"];
            NSString *flvPlayUrl = resultDict[@"url_play_flv"];
            NSString *hlsPlayUrl = resultDict[@"url_play_hls"];
            NSString *accPlayUrl = resultDict[@"url_play_acc"];
            
            controller.text = pusherUrl;
            NSString *(^c)(NSString *x, NSString *y) = ^(NSString *x, NSString *y) {
                return [NSString stringWithFormat:@"%@,%@", x, y];
            };
            NSString *lebUrl = [rtmpPlayUrl stringByReplacingOccurrencesOfString:@"rtmp://" withString:@"webrtc://"];
            controller.qrStrings = @[c(@"rtmp", rtmpPlayUrl),
                                     c(@"flv", flvPlayUrl),
                                     c(@"hls", hlsPlayUrl),
                                     c(LivePlayerLocalize(@"LivePusherDemo.CameraPush.lowlatency"), accPlayUrl),
                                     c(LivePlayerLocalize(@"LivePusherDemo.CameraPush.lebUrl"), lebUrl)];
            NSString *playUrls = LocalizeReplaceFourCharacter(LivePlayerLocalize(@"LivePusherDemo.CameraPush.rtmpaddressxxflvaddressyyhlsaddresszz"), [NSString stringWithFormat:@"%@",rtmpPlayUrl], [NSString stringWithFormat:@"%@",flvPlayUrl], [NSString stringWithFormat:@"%@",hlsPlayUrl], [NSString stringWithFormat:@"%@",accPlayUrl]);
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            pasteboard.string = playUrls;
            
            [weakSelf showText:LivePlayerLocalize(@"LivePusherDemo.CameraPush.getaddresssuccess") withDetailText:LivePlayerLocalize(@"LivePusherDemo.CameraPush.playbackaddresshasbeencopiedtotheclipboard")];
        }
    }];
}

- (void)addressBarControllerTapScanQR:(AddressBarController *)controller {
    if (_btnPush.tag == 1) {
        [self clickPush:_btnPush];
    }
    ScanQRController *vc = [[ScanQRController alloc] init];
    vc.delegate = self;
    [self.navigationController pushViewController:vc animated:NO];
}

#pragma mark - ScanQRDelegate
- (void)onScanResult:(NSString *)result {
    _addressBarController.text = result;
}

#pragma mark - TXLivePushListener
- (void)onPushEvent:(int)evtID withParam:(NSDictionary *)param {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (evtID == PUSH_ERR_NET_DISCONNECT || evtID == PUSH_ERR_INVALID_ADDRESS) {
            // 断开连接时，模拟点击一次关闭推流
            [self clickPush:self->_btnPush];
        } else if (evtID == PUSH_ERR_OPEN_CAMERA_FAIL) {
            [self clickPush:self->_btnPush];
            [self toastTip:LivePlayerLocalize(@"LiveLinkMicDemoOld.MLVBLiveRoom.failedtogetcamerapermission")];
        } else if (evtID == PUSH_EVT_OPEN_CAMERA_SUCC) {
            [self.pusher toggleTorch:[PushMoreSettingV1ViewController isOpenTorch]];
        } else if (evtID == PUSH_ERR_OPEN_MIC_FAIL) {
            [self clickPush:self->_btnPush];
            [self toastTip:LivePlayerLocalize(@"LiveLinkMicDemoOld.MLVBLiveRoom.failedtogetmicrophonepermission")];
        } else if (evtID == PUSH_EVT_CONNECT_SUCC) {
            [self.pusher setMute:[PushMoreSettingV1ViewController isMuteAudio]];
            [self.pusher showVideoDebugLog:[PushMoreSettingV1ViewController isShowDebugLog]];
            [self.pusher setMirror:[PushMoreSettingV1ViewController isMirrorVideo]];
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
                        [alert addAction:[UIAlertAction actionWithTitle:LivePlayerLocalize(@"LivePlayerDemo.PlayViewController.yes") style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
                            [alert dismissViewControllerAnimated:YES completion:nil];
                            
                            // 先暂停，再重新推流
                            [weakSelf.pusher stopPush];
                            [weakSelf.pusher startPush:weakSelf.pushUrl];
                        }]];
                        [alert addAction:[UIAlertAction actionWithTitle:LivePlayerLocalize(@"LivePlayerDemo.PlayViewController.no") style:UIAlertActionStyleCancel handler:^(UIAlertAction *_Nonnull action) {
                            [alert dismissViewControllerAnimated:YES completion:nil];
                        }]];
                        [weakSelf presentViewController:alert animated:YES completion:nil];
                    }
                }];
            }
        } else if (evtID == PUSH_WARNING_NET_BUSY) {
            [self->_notification displayNotificationWithMessage:LivePlayerLocalize(@"LivePusherDemo.CameraPush.currentnetworkenvironmentisnotgood") forDuration:5];
        }
        
        // log
        [self->_logView setPushEvent:evtID withParam:param];
    });
}

- (void)onNetStatus:(NSDictionary *)param {
    // 这里可以上报相关推流信息到业务服务器
    // 比如：码率，分辨率，帧率，cpu使用，缓存等信息
    // 字段请在TXLiveSDKTypeDef.h中定义
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_logView setNetStatus:param];
    });
}

- (void)onSnapshotComplete:(TXImage *)img {
    if (img != nil) {
        __block CGImageRef cgImage = img.CGImage;
        UIImage *finalImage = img;
        if (!cgImage) {
            CIContext *ciContext = [[CIContext alloc] init];
            cgImage = [ciContext createCGImage:img.CIImage fromRect:img.CIImage.extent];
            finalImage = [UIImage imageWithCGImage:cgImage];
        }
        NSArray *images = @[finalImage];
        UIActivityViewController *vc = [[UIActivityViewController alloc] initWithActivityItems:images applicationActivities:nil];
        [self.navigationController presentViewController:vc animated:YES completion:nil];
    }
}

#pragma mark - AudioEffectViewDelegate
-(void)onEffectViewHidden:(BOOL)isHidden {
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
        [self showInProgressText:LocalizeReplaceXX(LivePlayerLocalize(@"LivePusherDemo.CameraPush.loadingxx"), [NSString stringWithFormat:@"%d",(int)(progress * 100)])];
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

#pragma mark - PushSettingV1Delegate
// 是否开启带宽适应
- (void)onPushSetting:(PushSettingV1ViewController *)vc enableBandwidthAdjust:(BOOL)enableBandwidthAdjust {
    [_pusher setVideoQuality:[PushSettingV1ViewController getVideoQuality] adjustBitrate:[PushSettingV1ViewController getBandWidthAdjust] adjustResolution:NO];
}

// 是否开启硬件加速
- (void)onPushSetting:(PushSettingV1ViewController *)vc enableHWAcceleration:(BOOL)enableHWAcceleration {
    TXLivePushConfig *config = _pusher.config;
    config.enableHWAcceleration = enableHWAcceleration;
    [_pusher setConfig:config];
}

// 是否开启耳返
- (void)onPushSetting:(PushSettingV1ViewController *)vc enableAudioPreview:(BOOL)enableAudioPreview {
    TXLivePushConfig *config = _pusher.config;
    config.enableAudioPreview = enableAudioPreview;
    [_pusher setConfig:config];
}

// 画质类型
- (void)onPushSetting:(PushSettingV1ViewController *)vc videoQuality:(TX_Enum_Type_VideoQuality)videoQuality {
    [_pusher setVideoQuality:videoQuality adjustBitrate:[PushSettingV1ViewController getBandWidthAdjust] adjustResolution:NO];
}

- (void)onPushSetting:(PushSettingV1ViewController *)vc audioQuality:(NSInteger)qulity {
    TXLivePushConfig *config = _pusher.config;
    switch (qulity) {
        case 2:
            // 音乐音质，采样率48000
            config.audioChannels = 2;
            config.audioSampleRate = AUDIO_SAMPLE_RATE_48000;
            break;
        case 1:
            // 标准音质，采样率48000
            config.audioChannels = 1;
            config.audioSampleRate = AUDIO_SAMPLE_RATE_48000;
            break;
        case 0:
            // 语音音质，采样率16000
            config.audioChannels = 1;
            config.audioSampleRate = AUDIO_SAMPLE_RATE_16000;
            break;
        default:
            break;
    }
    [_pusher setConfig:config];
}

- (void)onPushSetting:(PushSettingV1ViewController *)vc reverbType:(TXReverbType)reverbType {
    [_pusher setReverbType:reverbType];
}

- (void)onPushSetting:(PushSettingV1ViewController *)vc voiceChangerType:(TXVoiceChangerType)voiceChangerType {
    [_pusher setVoiceChangerType:voiceChangerType];
}

- (void)onPushMoreSetting:(PushMoreSettingV1ViewController *)vc captureFPS:(NSInteger)fps{
    TXLivePushConfig *config = _pusher.config;
    [config setVideoFPS:(int)fps];
    [_pusher setConfig:config];
}

#pragma mark - PushMoreSettingV1Delegate
// 是否开启隐私模式（关闭摄像头，并发送pauseImg图片）
- (void)onPushMoreSetting:(PushMoreSettingV1ViewController *)vc disableVideo:(BOOL)disable {
    if (_pusher.isPublishing) {
        if (disable) {
            [_pusher pausePush];
        } else {
            [_pusher resumePush];
            [_pusher setMute:_isMute];
        }
    }
}

// 是否开启静音模式（发送静音数据，但是不关闭麦克风）
- (void)onPushMoreSetting:(PushMoreSettingV1ViewController *)vc muteAudio:(BOOL)mute {
    [_pusher setMute:mute];
    _isMute = mute;
}

// 是否开启观看端镜像
- (void)onPushMoreSetting:(PushMoreSettingV1ViewController *)vc mirrorVideo:(BOOL)mirror {
    [_pusher setMirror:mirror];
}

// 是否开启后置闪光灯
- (void)onPushMoreSetting:(PushMoreSettingV1ViewController *)vc openTorch:(BOOL)open {
    [_pusher toggleTorch:open];
}

// 是否开启横屏推流
- (void)onPushMoreSetting:(PushMoreSettingV1ViewController *)vc horizontalPush:(BOOL)enable {
    TXLivePushConfig *config = _pusher.config;
    config.homeOrientation = (enable ? HOME_ORIENTATION_RIGHT : HOME_ORIENTATION_DOWN);
    [_pusher setConfig:config];
    
    if (enable) {
        [_pusher setRenderRotation:90];
    } else {
        [_pusher setRenderRotation:0];
    }
}

// 是否开启调试信息
- (void)onPushMoreSetting:(PushMoreSettingV1ViewController *)vc debugLog:(BOOL)show {
    [_pusher showVideoDebugLog:show];
}

// 是否添加图像水印
- (void)onPushMoreSetting:(PushMoreSettingV1ViewController *)vc waterMark:(BOOL)enable {
    TXLivePushConfig *config = _pusher.config;
    if (enable) {
        config.watermark = [UIImage imageNamed:@"watermark"];
        config.watermarkPos = CGPointMake(10, 10);
    } else {
        config.watermark = nil;
        config.watermarkPos = CGPointZero;
    }
    [_pusher setConfig:config];
}

// 延迟测定工具条
- (void)onPushMoreSetting:(PushMoreSettingV1ViewController *)vc delayCheck:(BOOL)enable {
    [_pusher setEnableClockOverlay:enable];
}

// 是否开启手动点击曝光对焦
- (void)onPushMoreSetting:(PushMoreSettingV1ViewController *)vc touchFocus:(BOOL)enable {
    TXLivePushConfig *config = _pusher.config;
    config.touchFocus = enable;
    [_pusher setConfig:config];
}

// 是否开启手势放大预览画面
- (void)onPushMoreSetting:(PushMoreSettingV1ViewController *)vc videoZoom:(BOOL)enable {
    TXLivePushConfig *config = _pusher.config;
    config.enableZoom = enable;
    [_pusher setConfig:config];
}

// 是否开始纯音频推流(直播不支持动态切换)
- (void)onPushMoreSetting:(PushMoreSettingV1ViewController *)vc pureAudioPush:(BOOL)enable {
    TXLivePushConfig *config = _pusher.config;
    config.enablePureAudioPush = enable;
}

// 是否开启清晰度增强
- (void)onPushMoreSetting:(PushMoreSettingV1ViewController *)vc enableSharpnessEnhancement:(BOOL)enable {
    [[_pusher getBeautyManager] enableSharpnessEnhancement:enable];
}

// 是否开启H265编码
- (void)onPushMoreSetting:(id)vc enableHEVC:(BOOL)enable {
    NSDictionary *json = @{
        @"api": @"enableHevcEncode",
        @"params": @{
            @"enable": @(enable)
        }
    };
    NSString *jsonString = [self jsonStringFrom:json];
    [self.pusher callExperimentalAPI:jsonString];
}

// 本地截图
- (void)onPushMoreSettingSnapShot:(PushMoreSettingV1ViewController *)vc {
    __weak typeof(self)weakSelf = self;
    [_pusher snapshot:^(TXImage *img) {
        __strong typeof(weakSelf)strongSelf = weakSelf;
        if (img != nil) {
            NSArray *images = @[img];
            UIActivityViewController *vc = [[UIActivityViewController alloc] initWithActivityItems:images applicationActivities:nil];
            [strongSelf.navigationController presentViewController:vc animated:YES completion:nil];
        }
    }];
}

- (void)onPushMoreSettingSendMessage:(PushMoreSettingV1ViewController *)vc message:(NSString *)message {
    [_pusher sendMessageEx:[message dataUsingEncoding:NSUTF8StringEncoding]];
}

- (NSString *)jsonStringFrom:(NSDictionary *)dict {
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:NULL];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
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

@end
