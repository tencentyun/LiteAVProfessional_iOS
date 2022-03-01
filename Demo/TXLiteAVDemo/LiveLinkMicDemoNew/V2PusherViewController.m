//
//  V2PusherViewController.m
//  TXLiteAVDemo
//
//  Created by coddyliu on 2020/11/26.
//  Copyright © 2020 Tencent. All rights reserved.
//

#import "V2PusherViewController.h"

#import "AppLocalized.h"
#import "ColorMacro.h"
#import "MBProgressHUD.h"
#import "Masonry.h"
#import "PhotoUtil.h"
#import "V2LiveUtils.h"
#import "V2PusherSettingModel.h"
#import "V2PusherSettingViewController.h"
#import "V2QRGenerateViewController.h"
#import "V2TXLivePusher.h"

#define V2LogSimple()        NSLog(@"[%@ %p %s %d]", NSStringFromClass(self.class), self, __func__, __LINE__);
#define V2Log(_format_, ...) NSLog(@"[%@ %p %s %d] %@", NSStringFromClass(self.class), self, __func__, __LINE__, [NSString stringWithFormat:_format_, ##__VA_ARGS__]);

@interface V2PusherViewController () <V2TXLivePusherObserver, V2PusherSettingViewControllerDelegate, UIGestureRecognizerDelegate>

@property(nonatomic, strong) TXView *                       videoView;
@property(nonatomic, strong) V2TXLivePusher *               pusher;
@property(nonatomic, strong) V2PusherSettingViewController *settingContainer;
@property(nonatomic, strong) V2PusherSettingModel *         pusherVM;
@property(nonatomic, strong) UIProgressView *               volumeProgress;

@end

@implementation V2PusherViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.title = V2Localize(@"V2.Live.LinkMicNew.v2pushstream");
    }
    return self;
}

- (instancetype)initWithUrl:(NSString *)url {
    self = [self init];
    if (self) {
        self.url = url;
        V2Log(@"%@", url);
    }
    return self;
}

- (void)setUrl:(NSString *)url {
    _url                 = url;
    NSDictionary *params = [V2LiveUtils parseURLParametersAndLowercaseKey:url];
    if ([V2LiveUtils isTRTCUrl:url]) {
        self.title = [NSString stringWithFormat:@"%@（%@）", V2Localize(@"V2.Live.LinkMicNew.v2pushstream"), params[@"strroomid"]];
    } else {
        self.title = V2Localize(@"V2.Live.LinkMicNew.v2pushstream");  //[NSString stringWithFormat:@"V2推流（%@_%@）", params[@"strroomid"], params[@"userid"]];
    }
}

- (void)dealloc {
    V2LogSimple()[self.pusherVM saveConfig];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpNavigationBarButtons];
    self.videoView                 = [[TXView alloc] initWithFrame:self.view.bounds];
    self.videoView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.videoView];
    self.view.backgroundColor = [UIColor lightGrayColor];

    self.volumeProgress                   = [[UIProgressView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, 1)];
    self.volumeProgress.progressTintColor = [UIColor yellowColor];
    [self.view addSubview:self.volumeProgress];
    CGFloat leftRightPadding = 0;
    if (@available(iOS 11.0, *)) {
        UIWindow *window = UIApplication.sharedApplication.windows.firstObject;
        leftRightPadding = window.safeAreaInsets.bottom;
    }
    [self.volumeProgress mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view).offset(leftRightPadding);
        make.height.mas_equalTo(@(2));
        make.bottom.equalTo(self.view.mas_bottom).offset(-1);
    }];

    UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap)];
    doubleTapGesture.numberOfTapsRequired    = 2;
    doubleTapGesture.delegate                = self;
    [self.view addGestureRecognizer:doubleTapGesture];

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"rtc_back"] style:UIBarButtonItemStylePlain target:self action:@selector(handleDoubleTap)];
}

- (void)setUpNavigationBarButtons {
    UIBarButtonItem *qrItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"livepusher_qr_code_btn"] style:UIBarButtonItemStylePlain target:self action:@selector(onShowQRCode:)];
    self.navigationItem.rightBarButtonItems = @[ qrItem ];
}

- (V2PusherSettingViewController *)settingContainer {
    if (!self.pusherVM) {
        self.pusherVM = [[V2PusherSettingModel alloc] initWithPusher:self.pusher];
    }
    if (!_settingContainer) {
        _settingContainer             = [[V2PusherSettingViewController alloc] initWithHostVC:self muteVideo:NO muteAudio:NO logView:NO pusherViewModel:self.pusherVM];
        _settingContainer.isStart     = self.pusher.isPushing;
        _settingContainer.frontCamera = YES;
        _settingContainer.delegate    = self;
        _settingContainer.pusher      = self.pusher;
        [self.view addSubview:_settingContainer];
        [_settingContainer mas_makeConstraints:^(MASConstraintMaker *make) {
            make.leading.trailing.equalTo(self.view);
            if (@available(iOS 11.0, *)) {
                make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
                make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
            } else {
                make.top.equalTo(self.view).offset(64);
                make.bottom.equalTo(self.view);
            }
        }];
    }
    return _settingContainer;
}

- (void)releaseSettingContainer {
    if (_settingContainer) {
        [_settingContainer removeFromSuperview];
        _settingContainer = nil;
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

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    V2Log(@"smallPreView:%@", self.smallPreView);
    if (self.smallPreView) {
        [self.pusher setRenderView:self.videoView];
        [self.pusher showDebugView:self.settingContainer.isLogShow];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    V2Log(@"smallPreView:%@", self.smallPreView);
    if (self.smallPreView) {
        [self.pusher setRenderView:self.smallPreView];
        [self.pusher showDebugView:NO];  /// 小窗时不展示日志
    }
}

- (void)handleDoubleTap {
    [self.navigationController popViewControllerAnimated:NO];
}

- (BOOL)muteAudio {
    return self.settingContainer.isAudioMuted;
}

- (BOOL)muteVideo {
    return self.settingContainer.isVideoMuted;
}

- (BOOL)usefrontCamera {
    return self.settingContainer.frontCamera;
}

- (void)setMuteVideo:(BOOL)muteVideo {
    self.settingContainer.isVideoMuted = muteVideo;
}

- (void)setMuteAudio:(BOOL)muteAudio {
    self.settingContainer.isAudioMuted = muteAudio;
}

- (void)setUsefrontCamera:(BOOL)usefrontCamera {
    self.settingContainer.frontCamera = usefrontCamera;
    [self.pusher.getDeviceManager switchCamera:usefrontCamera];
}

- (void)applyConfig {
    /// 弹窗设置页面的状态
    [self.pusherVM applyConfig];
}

- (void)setPusherMode:(V2TXLiveMode)mode {
    self.pusher = [[V2TXLivePusher alloc] initWithLiveMode:mode];
    [self.pusher setObserver:self];
    [self.pusher setAudioQuality:V2TXLiveAudioQualityDefault];
    self.settingContainer.pusher = self.pusher;
    self.pusherVM.pusher         = self.pusher;
}

- (V2TXLiveCode)startPush {
    // 1. 检查摄像头权限
    AVAuthorizationStatus statusVideo = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (statusVideo == AVAuthorizationStatusDenied) {
        // 相机拒绝授权，提示前往设置中心
        [self showText:LivePlayerLocalize(@"LiveLinkMicDemoOld.RoomNew.prompt") withDetailText:LivePlayerLocalize(@"LiveLinkMicDemoOld.MLVBLiveRoom.failedtogetcamerapermission")];
        return V2TXLIVE_WARNING_CAMERA_START_FAILED;
    }
    // 2. 检查麦克风权限
    AVAuthorizationStatus statusAudio = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if (statusAudio == AVAuthorizationStatusDenied) {
        // 麦克风拒绝授权，提示前往设置中心
        [self showText:LivePlayerLocalize(@"LiveLinkMicDemoOld.RoomNew.prompt") withDetailText:LivePlayerLocalize(@"LiveLinkMicDemoOld.MLVBLiveRoom.failedtogetmicrophonepermission")];
        return V2TXLIVE_WARNING_MICROPHONE_START_FAILED;
    }
    
    V2Log(@"smallPreView:%@ url:%@", self.smallPreView, self.url);
    if (!self.view.window && self.smallPreView) {
        [self.pusher setRenderView:self.smallPreView];
    } else {
        [self.pusher setRenderView:self.videoView];
    }
    [self.pusher startCamera:self.usefrontCamera];
    [self.pusher startMicrophone];
    self.settingContainer.isStart = YES;
    V2TXLiveCode result           = [self.pusher startPush:self.url];
    if (result == V2TXLIVE_OK) {
        [self.pusher.getDeviceManager enableCameraAutoFocus:YES];
        [self applyConfig];
    } else {
        if (!self.pusher.isPushing) {
            [self.pusher stopCamera];
            [self.pusher stopMicrophone];
            [self.settingContainer stopPush];
            [self showText:@"推流失败" withDetailText:@"该 streamId 已经存在一个播放器或推流器"];
        } else {
            [self showText:@"已存在一个推流" withDetailText:nil];
        }
    }
    [self.pusherVM applyConfig];
    [UIApplication sharedApplication].idleTimerDisabled = self.pusher.isPushing;
    return result;
}

- (void)stopPush {
    V2Log(@"smallPreView:%@ url:%@", self.smallPreView, self.url);
    [self.pusher stopCamera];
    [self.pusher stopMicrophone];
    [self.pusher stopPush];
    [self.settingContainer stopPush];
    [self releaseSettingContainer];
    if (self.onStatusUpdate) {
        self.onStatusUpdate();
    }
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}

- (IBAction)onShowQRCode:(id)sender {
    if (!self.url || self.url.length == 0) {
        return;
    }

    NSString *    qrUrl  = @"";
    NSDictionary *params = [V2LiveUtils parseURLParametersAndLowercaseKey:self.url];
    if (self.playUrl) {
        qrUrl = self.playUrl;
    } else if ([V2LiveUtils isTRTCUrl:self.url]) {
        qrUrl = [NSString stringWithFormat:@"trtc://cloud.tencent.com/play/%@", params[@"strroomid"]];
    } else {
        /// qrUrl = [NSString stringWithFormat:@"room://cloud.tencent.com/rtc?strroomid=%@&remoteuserid=%@", params[@"strroomid"], params[@"userid"]];
    }
    if ([qrUrl length] == 0) {
        [self showText:@"播放URL不存在" withDetailText:@"通过扫码进行CDN推流，不会生成播放URL，如果需要播放URL，请使用自动生成推流地址。"];
        return;
    }

    V2QRGenerateViewController *qrCodeVC = [[V2QRGenerateViewController alloc] initWithNibName:@"V2QRGenerateViewController" bundle:nil];
    qrCodeVC.modalPresentationStyle      = UIModalPresentationOverFullScreen;
    qrCodeVC.playURL                     = qrUrl;
    [self.navigationController presentViewController:qrCodeVC animated:NO completion:nil];
}

- (void)showText:(NSString *)text withDetailText:(NSString *)detail {
    MBProgressHUD *hud = [MBProgressHUD HUDForView:[UIApplication sharedApplication].delegate.window];
    if (hud == nil) {
        hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].delegate.window animated:NO];
    }
    hud.mode              = MBProgressHUDModeText;
    hud.label.text        = text;
    hud.detailsLabel.text = detail;
    [hud showAnimated:YES];
    [hud hideAnimated:YES afterDelay:1];
}

#pragma mark - V2PusherSettingViewControllerDelegate

- (void)v2PusherSettingVC:(V2PusherSettingViewController *)container didClickLog:(BOOL)isLogShow {
    [self.pusher showDebugView:isLogShow];
}

- (void)v2PusherSettingVCDidClickSwitchCamera:(V2PusherViewController *)container value:(BOOL)frontCamera {
    self.usefrontCamera = frontCamera;
}

- (void)v2PusherSettingVC:(V2PusherSettingViewController *)container didClickMuteAudio:(BOOL)muteAudio {
    self.muteAudio = muteAudio;
}

- (void)v2PusherSettingVC:(V2PusherSettingViewController *)container didClickMuteVideo:(BOOL)muteVideo {
    self.muteVideo = muteVideo;
}

- (void)v2PusherSettingVC:(V2PusherSettingViewController *)container didClickStartVideo:(BOOL)start {
    if (start) {
        [self startPush];
    } else {
        [self stopPush];
    }
}

- (void)v2PusherSettingVCDidClickLocalRotation:(nonnull V2PusherViewController *)container {
}

#pragma mark-- V2TXLivePusherObserver
- (void)onError:(V2TXLiveCode)code message:(NSString *)msg extraInfo:(NSDictionary *)extraInfo {
    V2Log(@"code:%ld, msg:%@, extraInfo:%@", (long)code, msg, extraInfo) if (code == V2TXLIVE_ERROR_REQUEST_TIMEOUT) {
        [self showText:@"进房超时" withDetailText:@"请检查网络状态，然后重试"];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self stopPush];
        });
    }
}

- (void)onWarning:(V2TXLiveCode)code message:(NSString *)msg extraInfo:(NSDictionary *)extraInfo {
    V2Log(@"code:%ld, msg:%@, extraInfo:%@", (long)code, msg, extraInfo)
}

- (void)onCaptureFirstAudioFrame {
    V2Log(@"url:%@", self.url);
}

- (void)onCaptureFirstVideoFrame {
    V2Log(@"url:%@", self.url);
}

- (void)onMicrophoneVolumeUpdate:(NSInteger)volume {
    V2Log(@"volume:%ld", (long)volume)

        if ([NSThread isMainThread]) {
        self.volumeProgress.progress = volume / 100.0;
    }
    else {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.volumeProgress.progress = volume / 100.0;
        });
    }
}

- (void)onStatisticsUpdate:(V2TXLivePusherStatistics *)statistics {
    //    V2Log(@"statistics:%@", statistics)
}

- (void)onPushStatusUpdate:(V2TXLivePushStatus)state message:(NSString *)msg extraInfo:(NSDictionary *)extraInfo {
    if (state == V2TXLivePushStatusDisconnected && self.settingContainer.isStart) {
        [self showText:@"连接已断开" withDetailText:nil];
        [self stopPush];
    }
}

- (void)onSnapshotComplete:(TXImage *)image {
    if (!image) {
        [self showText:V2Localize(@"V2.Live.LinkMicNew.getsnapshotfailed")];
    } else {
        __block CGImageRef cgImage    = nil;
        UIImage *          finalImage = image;
        if (!image.CGImage) {
            CIContext *ciContext = [[CIContext alloc] init];
            cgImage              = [ciContext createCGImage:image.CIImage fromRect:image.CIImage.extent];
            finalImage           = [UIImage imageWithCGImage:cgImage];
        }
        [PhotoUtil saveDataToAlbum:UIImagePNGRepresentation(finalImage)
                        completion:^(BOOL success, NSError *_Nullable error) {
                            if (success) {
                                [self showText:V2Localize(@"V2.Live.LinkMicNew.snapshotsavetoalbum")];
                            } else {
                                [self showText:V2Localize(@"V2.Live.LinkMicNew.snapshotsavefailed")];
                            }
                            if (cgImage) {
                                CGImageRelease(cgImage);
                            }
                        }];
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([touch.view isKindOfClass:[UIButton class]]) {
        return NO;
    }
    return YES;
}

#pragma mark - Util

- (void)showText:(NSString *)text {
    dispatch_async(dispatch_get_main_queue(), ^{
        MBProgressHUD *hud = [MBProgressHUD HUDForView:[UIApplication sharedApplication].delegate.window];
        if (hud == nil) {
            hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].delegate.window animated:NO];
        }
        hud.mode       = MBProgressHUDModeText;
        hud.label.text = text;
        [hud showAnimated:YES];
        [hud hideAnimated:YES afterDelay:1];
    });
}

@end
