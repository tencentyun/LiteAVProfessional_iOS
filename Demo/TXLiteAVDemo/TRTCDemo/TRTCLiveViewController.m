//
//  TRTCLiveViewController.m
//  TXLiteAVDemo
//
//  Created by bluedang on 2021/5/17.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "TRTCLiveViewController.h"
#import "PhotoUtil.h"
#import "AudioEffectSettingKit.h"
#import <BeautySettingKit/TCBeautyPanel.h>

#import "AppDelegate.h"
#import "AppLocalized.h"
#import "MBProgressHUD.h"
#import "Masonry.h"
#import "TRTCFeatureContainerViewController.h"
#import "TRTCRemoteUserListViewController.h"
#import "TRTCRenderViewKeyManager.h"
#ifndef DISABLE_VOD
#import "TRTCVODViewController.h"
#endif
#import "TRTCVideoView.h"
#import "TRTCVideoViewLayout.h"
#import "ThemeConfigurator.h"
#import "UIView+Additions.h"
#import "UIView+CustomAutoLayout.h"
#import "TCUtil.h"
#import "TRTCEffectSettingsViewController.h"
#import "TRTCCloud.h"
#import "TRTCEffectManager.h"
#import "LrcParser.h"
#import "LrcTableViewCell.h"
#import "TRTCChorusManager.h"
#import "TRTCEffectSettingContainerVC.h"

@interface TRTCLiveViewController () <TRTCVideoViewDelegate, BeautyLoadPituDelegate, AudioEffectViewDelegate, TRTCChorusDelegate, UITableViewDelegate, UITableViewDataSource>

@property(weak, nonatomic) IBOutlet UIView *settingsContainerView;
@property(weak, nonatomic) IBOutlet TCBeautyPanel *beautyPanel;
@property(weak, nonatomic) IBOutlet UIStackView *toastStackView;

@property(strong, nonatomic) AudioEffectSettingView *audioEffectView;

@property(strong, nonatomic) UIViewController *                  currentEmbeddedVC;
@property(strong, nonatomic) TRTCFeatureContainerViewController *settingsVC;
@property(strong, nonatomic) TRTCRemoteUserListViewController *  userListVC;
@property(strong, nonatomic) TRTCAudioRecordManager *            recordManager;
@property(strong, nonatomic) TRTCRenderViewKeymanager *          renderViewKeymanager;
#ifndef DISABLE_VOD
@property(strong, nonatomic) TRTCVODViewController *             vodVC;  // 点播控制器
#endif

//合唱相关
@property (weak, nonatomic) IBOutlet UITableView *lrcView; //歌词显示
@property (strong,nonatomic) LrcParser *lrcContent;
@property (assign) NSInteger currentLrcRow;
@property (strong, nonatomic) TRTCChorusManager *chorusManager; //合唱业务管理类
@property (nonatomic, strong) UIImageView *cdnImageView;

@end

@implementation TRTCLiveViewController

- (UIImageView *)cdnImageView {
    if (!_cdnImageView) {
        _cdnImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cdnLogo"]];
        [_cdnImageView setHidden: YES];
    }
    return _cdnImageView;
}

+ (instancetype)initWithTRTCCloudManager:(TRTCCloudManager *)cloudManager {
    TRTCLiveViewController *liveVC = [[TRTCLiveViewController alloc] initWithNibName:@"TRTCLiveViewController" bundle:nil];
    liveVC.cloudManager = cloudManager;
    
    [cloudManager setDelegate:liveVC];
    return liveVC;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.recordManager        = [[TRTCAudioRecordManager alloc] initWithTrtc:[TRTCCloud sharedInstance]];
    self.renderViewKeymanager = [[TRTCRenderViewKeymanager alloc] init];
    [self setupMainView];
    [self setupBeautyPanel];
    [self setupAudioEffect];
    [self setupLiveUI];
    [self setupLogBtn];
    [self toastTip:TRTCLocalize(@"Demo.TRTC.enterRoom")];
#ifndef DISABLE_VOD
    self.vodVC = nil;
#endif
    if (![TCUtil getDEBUGSwitch]) {
        [self.featureBtnStackView removeArrangedSubview:self.audioEffectSettingBtn];
        [self.audioEffectSettingBtn removeFromSuperview];
        _audioEffectSettingBtn = nil;
    }
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
    if (self.cloudManager.role == TRTCRoleAudience) {
        if (!self.cdnImageView.superview) {
            return;
        }
        CGFloat topMargin = (bottomOffset > 0 ? 52 : 20) + ((44 - self.cdnImageView.bounds.size.height) * 0.5);
        [self.cdnImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.view.mas_right).offset(-20);
            make.top.equalTo(self.view.mas_top).offset(topMargin);
        }];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.chorusManager stopCdnPlay];
    [self.chorusManager stopCdnPush];
    self.chorusManager = nil;
}

- (void)setupChorus {
    if (self.cloudManager.enableChorus) {
        [self.chorusPlay setHidden:false];
        [self.lrcView registerNib:[UINib nibWithNibName:@"LrcTableViewCell" bundle:nil] forCellReuseIdentifier:@"LrcTableViewCell"];
        [self.lrcView setHidden:NO];
        [self.lrcView setBackgroundView:nil];
        [self.lrcView setBackgroundView:[[UIView alloc] init]];
        self.lrcView.backgroundView.backgroundColor = [UIColor clearColor];
        self.lrcView.backgroundColor = [UIColor clearColor];
        self.lrcView.delegate = self;
        self.lrcView.dataSource = self;
        self.lrcContent = [[LrcParser alloc] init];
        [self.lrcContent parseLrc:kChorusMusicName];
        [self.lrcView reloadData];
        [self.cloudManager setVideoEnabled:NO];
        self.chorusManager = [[TRTCChorusManager alloc] init];
        self.chorusManager.delegate = self;
        if (self.cloudManager.chrousUri.length > 0 && self.cloudManager.role == TRTCRoleAnchor) {
           [self.chorusManager startCdnPush:self.cloudManager.chrousUri];
        }
    } else {
        [self.lrcView setHidden:YES];
        [self.chorusPlay setHidden:YES];
        [self.cloudManager resetTRTCClouldDelegate];
    }

    if (self.cloudManager.role == TRTCRoleAudience) {
        [self.switchRoleBtn setHidden:self.cloudManager.enableChorus];
        [self.chorusPlay setHidden:!self.cloudManager.enableChorus];
        [self.cdnBtn setHidden:self.cloudManager.enableChorus];
        [self.view addSubview:self.cdnImageView];
    }
}

- (void)setupLiveUI {
    self.title = self.cloudManager.roomId;
    
    [self.cdnBtn setHidden:true];
    [self.chorusPlay setHidden:true];
    
    [self.switchRoleBtn setImage:[UIImage imageNamed:@"linkmic_start"] forState:UIControlStateNormal];
    [self.switchRoleBtn setImage:[UIImage imageNamed:@"linkmic_stop"]
                        forState:UIControlStateSelected];
    
    [self.switchCamBtn setImage:[UIImage imageNamed:@"camera_b"] forState:UIControlStateNormal];
    [self.switchCamBtn setImage:[UIImage imageNamed:@"camera_b2"] forState:UIControlStateSelected];
    
    if(self.cloudManager.isFrontCam){
        self.switchCamBtn.selected = NO;
    } else {
        self.switchCamBtn.selected = YES;
    }
    
    [self.closeCamBtn setImage:[UIImage imageNamed:@"muteVideo"] forState:UIControlStateNormal];
    [self.closeCamBtn setImage:[UIImage imageNamed:@"unmuteVideo"] forState:UIControlStateSelected];
    
    [self.muteMic setImage:[UIImage imageNamed:@"mute_b"] forState:UIControlStateNormal];
    [self.muteMic setImage:[UIImage imageNamed:@"mute_b2"] forState:UIControlStateSelected];
    
    self.chorusPlay.imageView.contentMode     = UIViewContentModeScaleAspectFit;
    self.switchRoleBtn.imageView.contentMode  = UIViewContentModeScaleAspectFit;
    self.muteMic.imageView.contentMode        = UIViewContentModeScaleAspectFit;
    self.stackLogBtn.imageView.contentMode    = UIViewContentModeScaleAspectFit;
    self.switchCamBtn.imageView.contentMode   = UIViewContentModeScaleAspectFit;
    self.closeCamBtn.imageView.contentMode    = UIViewContentModeScaleAspectFit;
    self.beautyBtn.imageView.contentMode      = UIViewContentModeScaleAspectFit;
    self.audioEffectBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.settingsBtn.imageView.contentMode    = UIViewContentModeScaleAspectFit;
    self.userControlBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.audioEffectSettingBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;
}

- (void)dealloc {
    [self.audioEffectView resetAudioSetting];
    [self.beautyPanel resetAndApplyValues];
    [self.cloudManager stopLive];
}

- (void)setupMainView {
    self.localPreView = [[TRTCVideoView alloc] init];
    self.localPreView.delegate = self;
}


- (void)setupAnchorCloudManager {
    [self setupCloudManager];
    [self.cloudManager setAudioEnabled:YES];
}

// LiveController 进房时调用
- (void)setupCloudManager {
    [self.cloudManager switchRole:TRTCRoleAnchor];
    self.mainViewUserId = self.cloudManager.userId;
    
    [self.cloudManager addMainVideoView:self.localPreView userId:self.mainViewUserId];
    
    [self.cloudManager setLocalPreView:self.localPreView];
    [self.localPreView setUserId:self.cloudManager.userId];
    [self.cloudManager setLogEnable:self.cloudManager.logEnable];
    [self.cloudManager setAutoFocusEnabled:YES]; // 默认打开自动对焦
    self.logBtn.selected = self.cloudManager.logEnable;
}


- (void)setupAudienceCloudManager {
    for (TRTCVideoView *view in [self.cloudManager.viewDic allValues]) {
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
    [self.cloudManager setAudioEnabled:NO];
    [self layoutViews];
}

- (void)setupBeautyPanel {
    [self.cloudManager configBeautyPanel:self.beautyPanel];
    [ThemeConfigurator configBeautyPanelTheme:self.beautyPanel];
    self.beautyPanel.pituDelegate = self;
    [self.beautyPanel resetAndApplyValues];
}

- (void)setupAudioEffect {
    self.audioEffectView          = [[AudioEffectSettingView alloc] initWithType:AudioEffectSettingViewCustom];
    self.audioEffectView.delegate = self;
    if ([TCUtil getDEBUGSwitch]) {
        [self.audioEffectView setIsDebugMode];
    }
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
    
    [_logBtn addTarget:self
                action:@selector(onLogBtnClick:)
      forControlEvents:UIControlEventTouchUpInside];
    [_logBtn sizeToFit];
    [_logBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(40);
        make.height.mas_equalTo(40);
    }];
    
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithCustomView:_logBtn];
    UIBarButtonItem *space     = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    
    space.width = 30;
    self.navigationItem.rightBarButtonItems = @[space,rightItem];
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
        if (!self.cloudManager.viewDic[self.mainViewUserId]) {
            return;
        }
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

- (void)embedChildVC:(UIViewController *)vc {
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

- (void)unembedChildVC:(UIViewController *)vc {
    if (!vc) {
        return;
    }
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
    __block UITextView *toastView;
    dispatch_async(dispatch_get_main_queue(), ^{
        toastView = [[UITextView alloc] init];
        toastView.userInteractionEnabled = NO;
        toastView.scrollEnabled          = NO;
        toastView.text                   = log;
        toastView.backgroundColor        = [UIColor whiteColor];
        toastView.alpha                  = 0.5;
        toastView.textColor              = [UIColor blackColor];
        [self.toastStackView addArrangedSubview:toastView];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [toastView removeFromSuperview];
    });
}

- (TRTCCdnPlayerSettingsViewController *)cdnPlayerVC {
    if (!_cdnPlayerVC) {
        _cdnPlayerVC = [[TRTCCdnPlayerSettingsViewController alloc] init];
    }
    return _cdnPlayerVC;
}

#pragma mark - Actinos

- (IBAction)cdnSettingClick:(UIButton *)button {
    [self toggleEmbedVC:self.cdnPlayerVC];
}

- (IBAction)onLogBtnClick:(UIButton *)button {
    button.selected = !button.selected;
    [self.cloudManager setLogEnable:button.selected];
}

- (IBAction)onSwitchRoleBtnClick:(UIButton *)button {
    button.selected = !button.selected;
}

- (IBAction)onSwitchCamBtnClick:(UIButton *)button {
    button.selected = !button.selected;
    [self.cloudManager switchCam:!button.selected];
}

- (IBAction)onCloseCamBtnClick:(UIButton *)button {
    button.selected = !button.selected;
    [self.cloudManager setCamEnable:!button.selected];
}

- (IBAction)onMuteMicBtnClick:(UIButton *)button {
    button.selected = !button.selected;
    [self.cloudManager setMicEnable:!button.selected];
}

- (IBAction)onBeautyBtnClick:(UIButton *)button {
    button.selected = !button.selected;
    [self.beautyPanel setHidden:!button.selected];
}

- (IBAction)onAudioEffectBtnClick:(UIButton *)button {
    [self.audioEffectView show];
}

- (IBAction)onSettingsBtnClick:(UIButton *)button {
    if (!self.settingsVC) {
        self.settingsVC = [[TRTCFeatureContainerViewController alloc] init];
        self.settingsVC.trtcCloudManager = self.cloudManager;
        self.settingsVC.recordManager = self.recordManager;
    }
    [self toggleEmbedVC:self.settingsVC];
}

- (IBAction)onUserListBtnClick:(UIButton *)button {
    if (!self.userListVC) {
        self.userListVC = [[TRTCRemoteUserListViewController alloc] init];
        self.userListVC.trtcCloudManager = self.cloudManager;
    }
    [self toggleEmbedVC:self.userListVC];
}
- (IBAction)onAudioEffectSettingBtnClick:(UIButton *)sender {
    [self presentViewController:[[TRTCEffectSettingContainerVC alloc]init] animated:YES completion:nil];
}

- (IBAction)onClickStartChorus:(UIButton *)button {
    if(self.cloudManager.role == TRTCRoleAnchor) {
        if (self.chorusManager.isChorusOn) {
            [self.chorusManager stopChorus];
        } else {
            [self.chorusManager startChorus];
        }
    } else if (self.cloudManager.role == TRTCRoleAudience) {
        if (self.chorusManager.isCdnPlaying) {
            [self.chorusManager stopCdnPlay];
            self.currentLrcRow = 0;
            [self.lrcView reloadData];
            [self.lrcView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.currentLrcRow inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
            [self.cdnImageView setHidden:YES];
        } else if (self.cloudManager.chrousUri.length > 0) {
            // 合唱推流只有音频，没有视频，所以传自身的view，但不显示
            [self.chorusManager startCdnPlay: self.cloudManager.chrousUri view:self.view];
            [self.cdnImageView setHidden:NO];
        }
//        self.cdnPlayerView.hidden = !self.chorusManager.isCdnPlaying;
        [self.chorusPlay setImage:[UIImage imageNamed:self.chorusManager.isCdnPlaying ? @"stop2" : @"start2"] forState:UIControlStateNormal];
    }
}

#pragma mark - TRTCCloudManagerDelegate SubRoom

- (void)onEnterSubRoom:(NSString *)roomId result:(NSInteger)result {
}

- (void)onExitSubRoom:(NSString *)roomId reason:(NSInteger)reason {
    
}

- (void)onSubRoomUserAudioAvailable:(NSString *)roomId userId:(NSString *)userId available:(BOOL)available {
    
}

- (void)onSubRoomUserVideoAvailable:(NSString *)roomId userId:(NSString *)userId available:(BOOL)available {
    TRTCCloud* subCloud = self.cloudManager.subClouds[roomId];
    if (available) {
        NSString *viewId = [[NSString alloc] initWithFormat:@"%@-SRoom", userId];
        TRTCVideoView *remoteView = self.cloudManager.viewDic[viewId];
        [subCloud startRemoteView:userId streamType:TRTCVideoStreamTypeBig view:remoteView];
    }else{
        [subCloud stopRemoteView:userId streamType:TRTCVideoStreamTypeBig];
    }
    
    [self layoutViews];
}

- (void)onSubRoomRemoteUserEnterRoom:(NSString *)roomId userId:(NSString *)userId {
    NSString *viewId = [[NSString alloc] initWithFormat:@"%@-SRoom", userId];
    TRTCVideoView *videoView = [[TRTCVideoView alloc] init];
    videoView.delegate = self;
    [videoView setUserId:userId];
    [videoView setRoomId:roomId];
    [videoView.audioVolumeIndicator setHidden:YES];
    [videoView showNetworkIndicatorImage:YES];
    [self.cloudManager.viewDic setValue:videoView forKey:viewId];
}

- (void)onSubRoomRemoteUserLeaveRoom:(NSString *)roomId userId:(NSString *)userId reason:(NSInteger)reason {
    NSString *viewId = [[NSString alloc] initWithFormat:@"%@-SRoom", userId];
    [self.cloudManager.viewDic[viewId] removeFromSuperview];
    [self.cloudManager.viewDic removeObjectForKey:viewId];
}

#pragma mark - TRTCCloudManagerDelegate delegate

- (void)onUserVideoAvailable:(NSString *)userId available:(bool)available {
    if (self.cloudManager.enableChorus) { return; }
    TRTCVideoView *remoteView = self.cloudManager.viewDic[userId];
    [remoteView showVideoCloseTip:!available];
    
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
                        self.cloudManager.roomId, @(result)]];
    } else {
        [self toastTip:[NSString stringWithFormat:@"%@: [%ld]",
                        TRTCLocalize(@"Demo.TRTC.Live.enterRoomFail"),
                        (long)result]];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)onExitRoom:(NSInteger)reason {
    NSString *msg = [NSString stringWithFormat:@"%@[roomId:%@]: reason[%ld]",
                     TRTCLocalize(@"Demo.TRTC.Live.leaveRoom"),
                     self.cloudManager.roomId, (long)reason];
    [self toastTip:msg];
}

- (void)onRecvSEIMsg:(NSString *)userId message:(NSData *)message {
    NSString *msg = [[NSString alloc] initWithData:message encoding:NSUTF8StringEncoding];
    [self toastTip:[NSString stringWithFormat:@"%@: %@", userId, msg]];
}

- (void)onRecvCustomCmdMsgUserId:(NSString *)userId cmdID:(NSInteger)cmdID seq:(UInt32)seq message:(NSData *)message {
    NSString *msg = [[NSString alloc] initWithData:message encoding:NSUTF8StringEncoding];
    [self toastTip:[NSString stringWithFormat:@"%@: %@", userId, msg]];
}

- (void)onConnectOtherRoom:(NSString *)userId errCode:(TXLiteAVError)errCode errMsg:(NSString *)errMsg {
    [self toastTip:[NSString stringWithFormat:@"PK result: %@(%d) userId: %@", errMsg, errCode, userId]];
    [self unembedChildVC:self.settingsVC];
}

- (void)onWarning:(TXLiteAVWarning)warningCode
       warningMsg:(NSString *)warningMsg
          extInfo:(NSDictionary *)extInfo {
    [self toastTip:@"WARNING: %@, %@", @(warningCode), warningMsg];
}

- (void)onError:(TXLiteAVError)errCode errMsg:(NSString *)errMsg extInfo:(NSDictionary *)extInfo {
    // 有些手机在后台时无法启动音频，这种情况下，TRTC会在恢复到前台后尝试重启音频，不应调用exitRoom。
    
    BOOL isStartingRecordInBackgroundError =
    errCode == ERR_MIC_START_FAIL &&
    [UIApplication sharedApplication].applicationState != UIApplicationStateActive;
    if (!isStartingRecordInBackgroundError) {
        NSString *msg = [NSString
                         stringWithFormat:@"%@: %@ [%d]", TRTCLocalize(@"Demo.TRTC.Live.error"), errMsg, errCode];
        UIAlertController *alertController =
        [UIAlertController alertControllerWithTitle:TRTCLocalize(@"Demo.TRTC.Live.alertTitle")
                                            message:msg
                                     preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:TRTCLocalize(@"Demo.TRTC.Live.ok")
                                                            style:UIAlertActionStyleDefault
                                                          handler:nil]];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (void)roomSettingsManager:(TRTCCloudManager *)manager enableVODAttachToTRTC:(BOOL)isEnabled {
#ifndef DISABLE_VOD
    if (_vodVC) {
        [_vodVC setEnableAttachVodToTRTC:isEnabled trtcCloud:self.cloudManager.trtcCloud];
    }
#endif
}

- (void)roomSettingsManager:(TRTCCloudManager *)manager enableVOD:(BOOL)isEnabled {
#ifndef DISABLE_VOD
    if (isEnabled) {
        if (_vodVC == nil) {
            _vodVC = [[TRTCVODViewController alloc] init];
            [self.view insertSubview:_vodVC.view atIndex:1];
        }
    } else {
        if (_vodVC) {
            [_vodVC stopPlay];
            [_vodVC.view removeFromSuperview];
            _vodVC = nil;
        }
    }
#endif

}

- (void)onRemoteUserAudioFrameMsg:(NSString *)userId message:(NSData *)message {
    NSString *msg = [[NSString alloc] initWithData:message encoding:NSUTF8StringEncoding];
    [self toastTip:[NSString stringWithFormat:@"%@: %@", userId, msg]];
}

- (void)onLocalRecordComplete:(NSInteger)errCode storagePath:(NSString *)storagePath {
    if (errCode == -1) {
        [self toastTip:@"%@%d",TRTCLocalize(@"Demo.TRTC.Live.recordTip"), errCode];
        return;
    }
    if (errCode == -2) {
        [self toastTip:TRTCLocalize(@"Demo.TRTC.Live.recordTipEnd")];
    }
    if (self.cloudManager.localRecordType == TRTCRecordTypeAudio) {
        NSURL *fileUrl = [NSURL fileURLWithPath:storagePath];
        UIActivityViewController *activityView =
        [[UIActivityViewController alloc] initWithActivityItems:@[fileUrl]
                                          applicationActivities:nil];
        [self presentViewController:activityView animated:YES completion:nil];
    } else {
        __weak __typeof(self) weakSelf = self;
        [PhotoUtil saveAssetToAlbum:[NSURL fileURLWithPath:storagePath]
                         completion:^(BOOL success, NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) {
                    [weakSelf toastTip:TRTCLocalize(@"Demo.TRTC.Live.recordTipSuccess")];
                } else {
                    [weakSelf toastTip:TRTCLocalize(@"Demo.TRTC.Live.recordTipFailure")];
                }
            });
        }];
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

#pragma mark - BeautyLoadPituDelegate
- (void)onLoadPituStart {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showInProgressText:LivePlayerLocalize(@"LivePusherDemo.CameraPush.startloadingassets")];
    });
}

- (void)onLoadPituProgress:(CGFloat)progress {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showInProgressText:LocalizeReplaceXX(
                                                   LivePlayerLocalize(@"LivePusherDemo.CameraPush.loadingxx"),
                                                   [NSString stringWithFormat:@"%d", (int)(progress * 100)])];
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

#pragma mark - TRTCChorusDelegate
- (void)onChorusStart:(ChorusStartReason)reason message:(NSString *)msg {
    [self.chorusPlay setImage:[UIImage imageNamed:@"stop2"] forState:UIControlStateNormal];
}

- (void)onChorusStop:(ChorusStopReason)reason message:(NSString *)msg {
    [self.chorusPlay setImage:[UIImage imageNamed:@"start2"] forState:UIControlStateNormal];
    self.currentLrcRow = 0;
    [self.lrcView reloadData];
    [self.lrcView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.currentLrcRow inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
}

- (void)onMusicPlayProgress:(NSInteger)curPtsMS duration:(NSInteger)durationMS {
    [self updateLrc:curPtsMS];
}

- (void)updateLrc:(NSInteger) progressInMS {
    for (int i = 0; i < self.lrcContent.timerArray.count; i++) {
        NSArray *timeArray = [self.lrcContent.timerArray[i] componentsSeparatedByString:@":"];
        UInt64 lrcTimeInMs = [timeArray[0] intValue] * 60 * 1000 + [timeArray[1] floatValue] * 1000;
        if (progressInMS > lrcTimeInMs) {
            _currentLrcRow = i;
        } else {
            break;
        }
    }

    [self.lrcView reloadData];
    [self.lrcView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:_currentLrcRow inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
}

#pragma mark - UITableView delegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.lrcContent.wordArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LrcTableViewCell *cell = [self.lrcView dequeueReusableCellWithIdentifier:@"LrcTableViewCell" forIndexPath:indexPath];

    UILabel* label = cell.label;
    label.text = self.lrcContent.wordArray[indexPath.row];
    if(indexPath.row == _currentLrcRow) {
        label.font = [UIFont systemFontOfSize:20];
        cell.textLabel.textColor = [UIColor greenColor];
    } else {
        label.font = [UIFont systemFontOfSize:15];
        cell.textLabel.textColor = [UIColor whiteColor];
    }

    label.textAlignment = NSTextAlignmentCenter;
    cell.backgroundColor = [UIColor clearColor];
    return cell;
}

#pragma mark - AudioEffectView delegate

- (void)onEffectViewHidden:(BOOL)isHidden {
}

#pragma mark - TRTCCloudDeleagate RecvAudioMsgDelegate
- (void)onRecvAudioMsg:(NSString *)userId msg:(NSString *)msg {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self toastTip:[NSString stringWithFormat:@"收到%@的网络消息: %@", userId, msg]];
    });
}

- (void)onNetworkQuality:(TRTCQualityInfo *)localQuality remoteQuality:(NSArray<TRTCQualityInfo *> *)remoteQuality {
    if (self.cloudManager.enableChorus) { return; }
    [self.localPreView setNetworkIndicatorImage:[self imageForNetworkQuality:localQuality.quality]];
    for (TRTCQualityInfo* qualityInfo in remoteQuality) {
        TRTCVideoView* remoteVideoView = [self.cloudManager.viewDic objectForKey:qualityInfo.userId];
        if (remoteVideoView) {
            [remoteVideoView setNetworkIndicatorImage:[self imageForNetworkQuality:qualityInfo.quality]];
        }
    }
}

- (UIImage*)imageForNetworkQuality:(TRTCQuality)quality
{
    UIImage* image = nil;
    switch (quality) {
        case TRTCQuality_Down:
        case TRTCQuality_Vbad:
            image = [UIImage imageNamed:@"signal5"];
            break;
        case TRTCQuality_Bad:
            image = [UIImage imageNamed:@"signal4"];
            break;
        case TRTCQuality_Poor:
            image = [UIImage imageNamed:@"signal3"];
            break;
        case TRTCQuality_Good:
            image = [UIImage imageNamed:@"signal2"];
            break;
        case TRTCQuality_Excellent:
            image = [UIImage imageNamed:@"signal1"];
            break;
        default:
            break;
    }
    
    return image;
}


@end

