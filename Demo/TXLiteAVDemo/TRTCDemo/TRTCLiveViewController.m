//
//  TRTCLiveViewController.m
//  TXLiteAVDemo
//
//  Created by bluedang on 2021/5/17.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "TRTCLiveViewController.h"
#import "TRTCVideoView.h"
#import "TRTCVideoViewLayout.h"
#import "ThemeConfigurator.h"
#import "TRTCFeatureContainerViewController.h"
#import "TRTCRemoteUserListViewController.h"

#import <TCBeautyPanel/TCBeautyPanel.h>
#import <AudioEffectSettingKit/AudioEffectSettingKit.h>

#import "Masonry.h"
#import "MBProgressHUD.h"
#import "UIView+CustomAutoLayout.h"
#import "UIView+Additions.h"

#import "AppDelegate.h"
#import "AppLocalized.h"

@interface TRTCLiveViewController () <TRTCVideoViewDelegate,
                                      BeautyLoadPituDelegate,
                                      AudioEffectViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *settingsContainerView;
@property (weak, nonatomic) IBOutlet TCBeautyPanel *beautyPanel;
@property (weak, nonatomic) IBOutlet UIStackView *toastStackView;


@property (strong, nonatomic) AudioEffectSettingView *audioEffectView;

@property (strong, nonatomic) UIViewController *currentEmbeddedVC;
@property (strong, nonatomic) TRTCFeatureContainerViewController *settingsVC;
@property (strong, nonatomic) TRTCRemoteUserListViewController *userListVC;

@end

@implementation TRTCLiveViewController

+ (instancetype)initWithTRTCCloudManager:(TRTCCloudManager*)cloudManager {
    TRTCLiveViewController *liveVC = [[TRTCLiveViewController alloc] initWithNibName:@"TRTCLiveViewController" bundle:nil];
    liveVC.cloudManager = cloudManager;

    [cloudManager setDelegate:liveVC];
    return liveVC;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupLogBtn];
    [self setupMainView];
    [self setupBeautyPanel];
    [self setupAudioEffect];
    [self setupLiveUI];
    
    [self toastTip:TRTCLocalize(@"Demo.TRTC.enterRoom")];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    //音乐 layouat
    CGFloat bottomOffset = 0;
    if (@available(iOS 11, *)) {
        bottomOffset = UIApplication.sharedApplication.keyWindow.safeAreaInsets.bottom;
    }

    [self.audioEffectView sizeWith:CGSizeMake(self.view.width, 526 + bottomOffset)];
    [self.audioEffectView alignParentTopWithMargin:self.view.height - self.audioEffectView.height];
    [self.audioEffectView alignParentLeftWithMargin:0];
}

- (void)setupLiveUI {
    self.title = self.cloudManager.roomId;
    
    [self.cdnBtn setHidden:true];
    
    [self.switchRoleBtn setImage:[UIImage imageNamed:@"linkmic_start"] forState:UIControlStateNormal];
    [self.switchRoleBtn setImage:[UIImage imageNamed:@"linkmic_stop"] forState:UIControlStateSelected];

    [self.switchCamBtn setImage:[UIImage imageNamed:@"camera_b"] forState:UIControlStateNormal];
    [self.switchCamBtn setImage:[UIImage imageNamed:@"camera_b2"] forState:UIControlStateSelected];

    [self.closeCamBtn setImage:[UIImage imageNamed:@"muteVideo"] forState:UIControlStateNormal];
    [self.closeCamBtn setImage:[UIImage imageNamed:@"unmuteVideo"] forState:UIControlStateSelected];

    [self.muteMic setImage:[UIImage imageNamed:@"mute_b"] forState:UIControlStateNormal];
    [self.muteMic setImage:[UIImage imageNamed:@"mute_b2"] forState:UIControlStateSelected];
    
    self.switchRoleBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.muteMic.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.stackLogBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.switchCamBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.closeCamBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.beautyBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.audioEffectBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.settingsBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.userControlBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;
}

- (void)dealloc {
    [self.audioEffectView resetAudioSetting];
    [self.cloudManager stopLive];
}

- (void)setupMainView {
    self.localPreView = [[TRTCVideoView alloc] init];
    self.localPreView.delegate = self;
}

- (void)setupAnchorCloudManager {
    [self.cloudManager switchRole:TRTCRoleAnchor];
    self.mainViewUserId = self.cloudManager.userId;

    [self.cloudManager addMainVideoView:self.localPreView userId:self.mainViewUserId];
    [self.cloudManager setLocalPreView:self.localPreView];
    [self.localPreView setUserId:self.cloudManager.userId];
    [self.cloudManager updateStreamMix];
    [self.cloudManager setLogEnable:self.cloudManager.logEnable];
    self.logBtn.selected = self.cloudManager.logEnable;
}

- (void)setupAudienceCloudManager {
    for (TRTCVideoView* view in [self.cloudManager.viewDic allValues]) {
        if ([view.userId isEqualToString:self.cloudManager.userId]) {
            continue;
        }
        self.mainViewUserId = view.userId;
        break;
    }

    [self.cloudManager switchRole:TRTCRoleAudience];
    [self.cloudManager removeMainView:self.cloudManager.userId];
    [self.cloudManager setLocalPreView:nil];
    [self.cloudManager closeStreamMix];
    
    [self layoutViews];
}

- (void)setupBeautyPanel {
    [self.cloudManager configBeautyPanel:self.beautyPanel];
    [ThemeConfigurator configBeautyPanelTheme:self.beautyPanel];
    self.beautyPanel.pituDelegate = self;
    [self.beautyPanel resetAndApplyValues];
}

- (void)setupAudioEffect {
    self.audioEffectView = [[AudioEffectSettingView alloc] initWithType:AudioEffectSettingViewCustom];
    self.audioEffectView.delegate = self;
    
    [self.view addSubview:self.audioEffectView];
    [self.cloudManager configAudioEffectPanel:self.audioEffectView];
}

- (void)setupLogBtn {
    [self.stackLogBtn setHidden:true];
    
    _logBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_logBtn setBackgroundImage:[UIImage imageNamed:@"log_b"] forState:UIControlStateSelected];
    [_logBtn setBackgroundImage:[UIImage imageNamed:@"log_b2"] forState:UIControlStateNormal];
    [_stackLogBtn setImage:[UIImage imageNamed:@"log_b"] forState:UIControlStateSelected];
    [_stackLogBtn setImage:[UIImage imageNamed:@"log_b2"] forState:UIControlStateNormal];
    
    [_logBtn addTarget:self action:@selector(onLogBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [_logBtn sizeToFit];
    [_logBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(40);
        make.height.mas_equalTo(40);
    }];
    
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithCustomView:_logBtn];
    self.navigationItem.rightBarButtonItems = @[rightItem];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}

- (void)layoutViews {
    @autoreleasepool {
        NSMutableArray *views = @[].mutableCopy;
        if (!self.cloudManager.viewDic[self.mainViewUserId]) { return; }
        [views addObject:self.cloudManager.viewDic[self.mainViewUserId]];
        
        for (NSString *userId in [self.cloudManager.viewDic allKeys]) {
            if ([userId isEqualToString:self.mainViewUserId]) {
                continue;
            }
            [views addObject:self.cloudManager.viewDic[userId]];
        }
        
        [TRTCVideoViewLayout layout:views atMainView:self.holderView];
    }
}

- (void)toggleEmbedVC:(UIViewController *)vc {
    if (self.currentEmbeddedVC != vc) {
        [self embedChildVC:vc];
    } else {
        [self unembedChildVC:vc];
    }
}

- (void)embedChildVC:(UIViewController*)vc {
    if (self.currentEmbeddedVC) {
        [self unembedChildVC:vc];
    }
    
    UINavigationController *naviVC = [[UINavigationController alloc] initWithRootViewController:vc];
    [self addChildViewController:naviVC];
    [self.settingsContainerView addSubview:naviVC.view];
    [naviVC.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.settingsContainerView);
    }];
    [naviVC didMoveToParentViewController:self];
    
    self.settingsContainerView.hidden = NO;
    self.currentEmbeddedVC = vc;
}

- (void)unembedChildVC:(UIViewController*)vc {
    if (!vc) { return; }
    [vc.navigationController willMoveToParentViewController:nil];
    [vc.navigationController.view removeFromSuperview];
    [vc.navigationController removeFromParentViewController];
    
    self.currentEmbeddedVC = nil;
    self.settingsContainerView.hidden = YES;
}

- (void)toastTip:(NSString *)toastInfo, ... {
    va_list args;
    va_start(args, toastInfo);
    NSString *log = [[NSString alloc] initWithFormat:toastInfo arguments:args];
    va_end(args);
    __block UITextView *toastView = [[UITextView alloc] init];
    
    toastView.userInteractionEnabled = NO;
    toastView.scrollEnabled = NO;
    toastView.text = log;
    toastView.backgroundColor = [UIColor whiteColor];
    toastView.alpha = 0.5;

    [self.toastStackView addArrangedSubview:toastView];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [toastView removeFromSuperview];
    });
}

#pragma mark - Actinos

- (IBAction)onLogBtnClick:(UIButton*)button {
    button.selected = !button.selected;
    [self.cloudManager setLogEnable:button.selected];
}

- (IBAction)onSwitchRoleBtnClick:(UIButton*)button {
    button.selected = !button.selected;

}

- (IBAction)onSwitchCamBtnClick:(UIButton*)button {
    button.selected = !button.selected;
    [self.cloudManager switchCam];
}

- (IBAction)onCloseCamBtnClick:(UIButton*)button {
    button.selected = !button.selected;
    [self.cloudManager setCamEnable:!button.selected];
}

- (IBAction)onMuteMicBtnClick:(UIButton*)button {
    button.selected = !button.selected;
    [self.cloudManager setMicEnable:!button.selected];
}

- (IBAction)onBeautyBtnClick:(UIButton*)button {
    button.selected = !button.selected;
    [self.beautyPanel setHidden:!button.selected];
}

- (IBAction)onAudioEffectBtnClick:(UIButton*)button {
    [self.audioEffectView show];
}

- (IBAction)onSettingsBtnClick:(UIButton*)button {
    if (!self.settingsVC) {
        self.settingsVC = [[TRTCFeatureContainerViewController alloc] init];
        self.settingsVC.trtcCloudManager = self.cloudManager;
    }
    [self toggleEmbedVC:self.settingsVC];
}

- (IBAction)onUserListBtnClick:(UIButton*)button {
    if (!self.userListVC) {
        self.userListVC = [[TRTCRemoteUserListViewController alloc] init];
        self.userListVC.trtcCloudManager = self.cloudManager;
    }
    [self toggleEmbedVC:self.userListVC];
}

#pragma mark - TRTCCloudManagerDelegate delegate

- (void)onUserVideoAvailable:(NSString*)userId available:(bool)available {
    if (!available) {
        if (![userId isEqualToString:self.mainViewUserId]) {
            return;
        }
        self.mainViewUserId = self.cloudManager.userId;
    } else {
        [self.cloudManager.viewDic[userId] setDelegate:self];
    }
    
    [self layoutViews];
}

- (void)onEnterRoom:(NSInteger)result {
    if (result >= 0) {
        [self toastTip:[NSString stringWithFormat:@"[%@]%@[roomId:%@]: elapsed[%@ ms]",
                        self.cloudManager.userId,
                        TRTCLocalize(@"Demo.TRTC.Live.enterRoomSuccess"),
                        self.cloudManager.roomId,
                        @(result)]];
    } else {
        [self toastTip:[NSString stringWithFormat:@"%@: [%ld]", TRTCLocalize(@"Demo.TRTC.Live.enterRoomFail"), (long)result]];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)onExitRoom:(NSInteger)reason {
    NSString *msg = [NSString stringWithFormat:@"%@[roomId:%@]: reason[%ld]",
                     TRTCLocalize(@"Demo.TRTC.Live.leaveRoom"),
                     self.cloudManager.roomId,  (long)reason];
    [self toastTip:msg];
}

- (void)onRecvSEIMsg:(NSString *)userId message:(NSData *)message {
    NSString *msg = [[NSString alloc] initWithData:message encoding:NSUTF8StringEncoding];
    [self toastTip:[NSString stringWithFormat:@"%@: %@", userId, msg]];
}

- (void)onConnectOtherRoom:(NSString *)userId errCode:(TXLiteAVError)errCode errMsg:(NSString *)errMsg {
    [self toastTip:[NSString stringWithFormat:@"PK result: %@(%d) userId: %@", errMsg, errCode, userId]];
    [self unembedChildVC:self.settingsVC];
}

- (void)onWarning:(TXLiteAVWarning)warningCode warningMsg:(NSString *)warningMsg extInfo:(NSDictionary *)extInfo {
    [self toastTip:@"WARNING: %@, %@", @(warningCode), warningMsg];
}

- (void)onError:(TXLiteAVError)errCode errMsg:(NSString *)errMsg extInfo:(NSDictionary *)extInfo {
    // 有些手机在后台时无法启动音频，这种情况下，TRTC会在恢复到前台后尝试重启音频，不应调用exitRoom。

    BOOL isStartingRecordInBackgroundError =
        errCode == ERR_MIC_START_FAIL &&
        [UIApplication sharedApplication].applicationState != UIApplicationStateActive;
    BOOL isHEVCHardwareDecoderFailed = errCode == ERR_HEVC_DECODE_FAIL;
    if (!isStartingRecordInBackgroundError && !isHEVCHardwareDecoderFailed) {
        NSString *msg = [NSString stringWithFormat:@"%@: %@ [%d]", TRTCLocalize(@"Demo.TRTC.Live.error"), errMsg, errCode];
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"TRTC OnError"
                                                                                 message:msg
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:TRTCLocalize(@"Demo.TRTC.Live.ok")
                                                            style:UIAlertActionStyleDefault
                                                          handler:nil]];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

#pragma mark - TRTCRemoteViewDelegate delegate

- (void)onViewTap:(TRTCVideoView *)view {
    if ([self.mainViewUserId isEqualToString:view.userId]) {
        return;
    }
    
    self.mainViewUserId = view.userId;
    
    [self layoutViews];
}

#pragma mark - HUD
- (void)showInProgressText:(NSString *)text
{
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

#pragma mark - AudioEffectView delegate

- (void)onEffectViewHidden:(BOOL)isHidden {
    if (isHidden) {
//        [self addGestureRecognizer:_tap];
    }
}

@end
