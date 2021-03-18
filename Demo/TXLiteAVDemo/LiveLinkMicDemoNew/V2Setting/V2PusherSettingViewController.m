//
//  V2TRTCSettingContainer.m
//  TXLiteAVDemo_Enterprise
//
//  Created by jiruizhang on 2020/12/3.
//  Copyright © 2020 Tencent. All rights reserved.
//

#import "V2PusherSettingViewController.h"
#import "Masonry.h"
#import "V2SettingBottomBar.h"
#import "V2SettingsContainerViewController.h"
#import "V2SettingsBaseViewController.h"
#import "ThemeConfigurator.h"
#import <AudioEffectSettingKit/AudioEffectSettingKit.h>
#import "MBProgressHUD.h"
//#import "AudioEffectSettingKit.h"

@interface V2PusherSettingViewController () <V2SettingBottomBarDelegate, AudioEffectViewDelegate, UIGestureRecognizerDelegate>
@property (nonatomic, weak) UIViewController *hostVC;
@property (nonatomic, strong) V2SettingBottomBar *settingBar;
@property (nonatomic, strong) UIView *centerContainerView;
@property (nonatomic, strong) AudioEffectSettingView *audioEffectView;

@property (strong, nonatomic, nullable) UIViewController *currentEmbededVC;
@property (strong, nonatomic, nullable) V2SettingsContainerViewController *settingsVC;
@property (strong, nonatomic, nullable) V2SettingsBaseViewController *beautyVC;
@property (strong, nonatomic) V2SettingsBaseViewController *videoVC;
@property (strong, nonatomic) V2SettingsBaseViewController *audioVC;

@property (strong, nonatomic) V2PusherSettingModel *pusherVM;

@end

@implementation V2PusherSettingViewController

- (instancetype)initWithHostVC:(UIViewController *)hostVC
                     muteVideo:(BOOL)isVideoMuted
                     muteAudio:(BOOL)isAudioMuted
                       logView:(BOOL)isLogShow
                        pusher:(V2TXLivePusher *)pusher
               pusherViewModel:(V2PusherSettingModel *)pusherVM {
    self = [super init];
    if (self) {
        self.hostVC = hostVC;
        self.isVideoMuted = isVideoMuted;
        self.isAudioMuted = isAudioMuted;
        self.isLogShow = isLogShow;
        self.pusher = pusher;
        
        self.pusherVM = pusherVM;
        
        [self addBar];
        [self addCenterView];
        [self addAudioEffectView];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapAction)];
        tapGesture.delegate = self;
        [self addGestureRecognizer:tapGesture];
    }
    return self;
}

- (void)setIsStart:(BOOL)isStart {
    _isStart = isStart;
    [self.settingBar updateItem:V2TRTCSettingBarItemTypeStart value:isStart];
}

- (BOOL)isVideoMuted {
    return self.pusherVM.isVideoMuted;
}
- (void)setIsVideoMuted:(BOOL)isVideoMuted {
    self.pusherVM.isVideoMuted = isVideoMuted;
    [self.settingBar updateItem:V2TRTCSettingBarItemTypeMuteVideo value:isVideoMuted];
}

- (BOOL)isAudioMuted {
    return self.pusherVM.isAudioMuted;
}
- (void)setIsAudioMuted:(BOOL)isAudioMuted {
    self.pusherVM.isAudioMuted = isAudioMuted;
    [self.settingBar updateItem:V2TRTCSettingBarItemTypeMuteAudio value:isAudioMuted];
}

- (void)setFrontCamera:(BOOL)frontCamera {
    _frontCamera = frontCamera;
    [self.settingBar updateItem:V2TRTCSettingBarItemTypeCamera value:frontCamera];
}

- (void)setIsLogShow:(BOOL)isLogShow {
    _isLogShow = isLogShow;
    [self.settingBar updateItem:V2TRTCSettingBarItemTypeLog value:isLogShow];
}

- (void)setPusher:(V2TXLivePusher *)pusher {
    _pusher = pusher;
    if (pusher) {
        [self.audioEffectView setAudioEffectManager:[pusher getAudioEffectManager]];
    }
}

- (void)stopPush {
    /// 资源释放
    self.isStart = NO;
    [self.audioEffectView stopPlay];
}

- (void)dealloc {
    [self.audioEffectView resetAudioSetting];
}

- (void)addBar {
    self.settingBar = [V2SettingBottomBar createInstance:@[
        @(V2TRTCSettingBarItemTypeStart),
        @(V2TRTCSettingBarItemTypeCamera),
        @(V2TRTCSettingBarItemTypeMuteVideo),
        @(V2TRTCSettingBarItemTypeMuteAudio),
        @(V2TRTCSettingBarItemTypeBeauty),
        @(V2TRTCSettingBarItemTypeBGM),
        @(V2TRTCSettingBarItemTypeFeature),
        @(V2TRTCSettingBarItemTypeLog)]];
    
    self.settingBar.delegate = self;
    [self.settingBar updateItem:V2TRTCSettingBarItemTypeMuteAudio value:self.isAudioMuted];
    [self.settingBar updateItem:V2TRTCSettingBarItemTypeLog value:self.isLogShow];
    [self.settingBar updateItem:V2TRTCSettingBarItemTypeCamera value:self.frontCamera];
    
    [self addSubview:self.settingBar];
    [self.settingBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self);
        make.bottom.equalTo(self);
        make.height.mas_equalTo(44);
    }];
}

- (void)addCenterView {
    self.centerContainerView = [[UIView alloc] init];
    self.centerContainerView.layer.cornerRadius = 12;
    self.centerContainerView.clipsToBounds = YES;
    UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    [self.centerContainerView addSubview:effectView];
    [effectView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.leading.trailing.equalTo(self.centerContainerView);
    }];
    [self addSubview:self.centerContainerView];
    [self.centerContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self).offset(10);
        make.trailing.equalTo(self).offset(-10);
        make.top.equalTo(self).offset(10);
        make.bottom.equalTo(self.settingBar.mas_top).offset(-20);
    }];
    
    self.centerContainerView.hidden = YES;
}

- (void)addAudioEffectView {
    self.audioEffectView = [[AudioEffectSettingView alloc] initWithType:AudioEffectSettingViewDefault];
    [self.audioEffectView setAudioEffectManager:[self.pusher getAudioEffectManager]];
    self.audioEffectView.delegate = self;
    self.audioEffectView.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.8];
    [self.audioEffectView hide];
    [self addSubview:self.audioEffectView];
    
    CGFloat bottomPadding = 0;
    if (@available(iOS 11.0, *)) {
        UIWindow *window = UIApplication.sharedApplication.windows.firstObject;
        bottomPadding = window.safeAreaInsets.bottom;
    }
    [self.audioEffectView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self);
        make.bottom.equalTo(self).offset(bottomPadding);
        make.height.mas_equalTo([AudioEffectSettingView height] + bottomPadding);
    }];
}

- (void)handleTapAction {
    if (self.currentEmbededVC) {
        [self unembedChildVC:self.currentEmbededVC];
    }
    [self.audioEffectView hide];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    CGPoint locationInView = [touch locationInView:self];
    if ((self.centerContainerView.hidden == NO && CGRectContainsPoint(self.centerContainerView.frame, locationInView))
        || (self.audioEffectView.hidden == NO && CGRectContainsPoint(self.audioEffectView.frame, locationInView))) {
        return NO;
    } else {
        return YES;
    }
}

#pragma mark - AudioEffectViewDelegate

- (void)onEffectViewHidden:(BOOL)isHidden {
    self.settingBar.hidden = !isHidden;
}

#pragma mark - V2SettingBottomBarDelegate

- (void)v2SettingBottomBarDidSelectItem:(V2TRTCSettingBarItemType)type {
    switch (type) {
        case V2TRTCSettingBarItemTypeLog:
            [self onClickLogButton];
            break;
        case V2TRTCSettingBarItemTypeBeauty:
            [self onClickBeautyButton];
            break;
        case V2TRTCSettingBarItemTypeCamera:
            [self onClickSwitchCameraButton];
            break;
        case V2TRTCSettingBarItemTypeMuteAudio:
            [self onClickAudioMuteButton];
            break;
        case V2TRTCSettingBarItemTypeLocalRotation:
            [self onClickLocalRotationButton];
            break;
        case V2TRTCSettingBarItemTypeBGM:
            [self onClickBgmSettingsButton];
            break;
        case V2TRTCSettingBarItemTypeFeature:
            [self onClickFeatureSettingsButton];
            break;
        case V2TRTCSettingBarItemTypeMuteVideo:
            [self onClickVideoMuteButton];
            break;
        case V2TRTCSettingBarItemTypeStart:
            [self onClickVideoStartButton];
        default:
            break;
    }
}

#pragma mark - Actions

- (void)onClickLogButton {
    if (self.delegate && [self.delegate respondsToSelector:@selector(v2PusherSettingVC:didClickLog:)]) {
        self.isLogShow = !self.isLogShow;
        [self.delegate v2PusherSettingVC:self didClickLog:self.isLogShow];
        [self.settingBar updateItem:V2TRTCSettingBarItemTypeLog value:self.isLogShow];
    }
}

- (void)onClickBeautyButton {
    if (!self.beautyVC) {
        self.beautyVC = [[V2SettingsBaseViewController alloc] init];
        self.beautyVC.title = @"美颜设置";
        int defaultValue = 5;
        __weak __typeof(self) wSelf = self;
        self.beautyVC.items = @[
            [[V2SettingsSliderItem alloc] initWithTitle:@"红润"
                                                    value:defaultValue min:0 max:9 step:1
                                               continuous:YES
                                                   action:^(float volume) {
                [[wSelf.pusher getBeautyManager] setRuddyLevel:volume];
            }],
            [[V2SettingsSliderItem alloc] initWithTitle:@"美白"
                                                    value:defaultValue min:0 max:9 step:1
                                               continuous:YES
                                                   action:^(float volume) {
                [[wSelf.pusher getBeautyManager] setWhitenessLevel:volume];
            }],
            [[V2SettingsSliderItem alloc] initWithTitle:@"美颜"
                                                    value:defaultValue min:0 max:9 step:1
                                               continuous:YES
                                                   action:^(float volume) {
                [[wSelf.pusher getBeautyManager] setBeautyLevel:volume];
            }]
        ].mutableCopy;
        
        [[self.pusher getBeautyManager] setRuddyLevel:defaultValue];
        [[self.pusher getBeautyManager] setWhitenessLevel:defaultValue];
        [[self.pusher getBeautyManager] setBeautyLevel:defaultValue];
    }
    [self toggleEmbedVC:self.beautyVC];
    
    [self.centerContainerView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self).offset(10);
        make.trailing.equalTo(self).offset(-10);
        make.height.mas_equalTo(200);
        make.bottom.equalTo(self.settingBar.mas_top).offset(-20);
    }];
}

- (void)onClickSwitchCameraButton {
    if (self.delegate && [self.delegate respondsToSelector:@selector(v2PusherSettingVCDidClickSwitchCamera:value:)]) {
        self.frontCamera = !self.frontCamera;
        [self.delegate v2PusherSettingVCDidClickSwitchCamera:self value:self.frontCamera];
        [self.settingBar updateItem:V2TRTCSettingBarItemTypeCamera value:self.frontCamera];
    }
}

- (void)onClickAudioMuteButton {
    if (self.delegate && [self.delegate respondsToSelector:@selector(v2PusherSettingVC:didClickMuteAudio:)]) {
        self.isAudioMuted = !self.isAudioMuted;
        [self.delegate v2PusherSettingVC:self didClickMuteAudio:self.isAudioMuted];
        [self.settingBar updateItem:V2TRTCSettingBarItemTypeMuteAudio value:self.isAudioMuted];
    }
}

- (void)onClickVideoMuteButton {
    if (self.delegate && [self.delegate respondsToSelector:@selector(v2PusherSettingVC:didClickMuteVideo:)]) {
        self.isVideoMuted = !self.isVideoMuted;
        [self.delegate v2PusherSettingVC:self didClickMuteVideo:self.isVideoMuted];
        [self.settingBar updateItem:V2TRTCSettingBarItemTypeMuteVideo value:self.isVideoMuted];
    }
}

- (void)onClickVideoStartButton {
    if (self.delegate && [self.delegate respondsToSelector:@selector(v2PusherSettingVC:didClickStartVideo:)]) {
        self.isStart = !self.isStart;
        [self.delegate v2PusherSettingVC:self didClickStartVideo:self.isStart];
        [self.settingBar updateItem:V2TRTCSettingBarItemTypeStart value:self.isStart];
    }
}

- (void)onClickLocalRotationButton {
    if (self.delegate && [self.delegate respondsToSelector:@selector(v2PusherSettingVCDidClickLocalRotation:)]) {
        [self.delegate v2PusherSettingVCDidClickLocalRotation:self];
    }
}

- (void)onClickBgmSettingsButton {
    if (self.currentEmbededVC) {
        [self unembedChildVC:self.currentEmbededVC];
    }
    [self.audioEffectView show];
}

- (void)onClickFeatureSettingsButton {
    if (!self.settingsVC) {
        self.settingsVC = [[V2SettingsContainerViewController alloc] init];
        self.settingsVC.settingVCs = @[self.videoVC, self.audioVC];
    }
    [self toggleEmbedVC:self.settingsVC];
    
    [self.centerContainerView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self).offset(10);
        make.trailing.equalTo(self).offset(-10);
        make.top.equalTo(self).offset(10);
        make.bottom.equalTo(self.settingBar.mas_top).offset(-20);
    }];
}

#pragma mark - setting vc

- (V2SettingsBaseViewController *)videoVC {
    if (_videoVC == nil) {
        _videoVC = [[V2SettingsBaseViewController alloc] init];
        _videoVC.title = @"视频";
        
        __weak __typeof(self) wSelf = self;
        _videoVC.items = @[
            [[V2SettingsSelectorItem alloc] initWithTitle:@"分辨率"
                                                      items: [V2PusherSettingModel resolutionNames]
                                              selectedIndex:(NSInteger)self.pusherVM.videoResolution
                                                     action:^(NSInteger index) {
                V2TXLiveVideoResolution resolution = [[V2PusherSettingModel resolutions][index] integerValue];
                [wSelf.pusherVM setVideoResolution:resolution];
            }],
            [[V2SettingsSegmentItem alloc] initWithTitle:@"  本地预览镜像"
                                                     items:@[@"auto", @"开启", @"关闭"]
                                             selectedIndex:self.pusherVM.localMirrorType
                                                    action:^(NSInteger index) {
                [wSelf.pusherVM setLocalMirrorType:index];
            }],
            [[V2SettingsSwitchItem alloc] initWithTitle:@"开启远程镜像"
                                                     isOn:self.pusherVM.isRemoteMirrorEnabled
                                                   action:^(BOOL isOn) {
                [wSelf onEnableRemoteMirror:isOn];
            }],
            [[V2SettingsSwitchItem alloc] initWithTitle:@"开启视频水印" isOn:NO action:^(BOOL isOn) {
                [wSelf onEnableWatermark:isOn];
            }],
            [[V2SettingsButtonItem alloc] initWithTitle:@"视频截图" buttonTitle:@"截图" action:^{
                [wSelf snapshotLocalVideo];
            }],
        ].mutableCopy;
    }
    
    return _videoVC;
}

- (V2SettingsBaseViewController *)audioVC {
    if (_audioVC == nil) {
        _audioVC = [[V2SettingsBaseViewController alloc] init];
        _audioVC.title = @"音频";
        
        __weak __typeof(self) wSelf = self;
            
        _audioVC.items = @[
            [[V2SettingsSegmentItem alloc] initWithTitle:@"  音量类型"
                                                     items:@[@"自动", @"媒体", @"通话"]
                                             selectedIndex:self.pusherVM.volumeType
                                                    action:^(NSInteger index) {
                wSelf.pusherVM.volumeType = (TRTCSystemVolumeType)index;
            }],
            [[V2SettingsSliderItem alloc] initWithTitle:@"采集音量"
                                                    value:100 min:0 max:100 step:1
                                               continuous:YES
                                                   action:^(float volume) {
                wSelf.pusherVM.captureVolume = (NSInteger)volume;
            }],
            [[V2SettingsSwitchItem alloc] initWithTitle:@"开启耳返"
                                                     isOn:self.pusherVM.isEarMonitoringEnabled
                                                   action:^(BOOL isOn) {
                wSelf.pusherVM.isEarMonitoringEnabled = isOn;
            }],
            [[V2SettingsSwitchItem alloc] initWithTitle:@"音量提示"
                                                     isOn:self.pusherVM.isEnableVolumeEvaluation
                                                   action:^(BOOL isOn) {
                wSelf.pusherVM.isEnableVolumeEvaluation = isOn;
            }],
        ].mutableCopy;
    }
    
    return _audioVC;
}

#pragma mark - video setting action

- (void)onEnableVideo:(BOOL)isOn {
    [self.pusherVM setVideoEnabled:isOn];
}

- (void)onMuteVideo:(BOOL)isMuted {
    self.pusherVM.isVideoMuted = isMuted;
}

- (void)onSelectLocalMirror:(NSInteger)index {
    [self.pusherVM setLocalMirrorType:index];
}

- (void)onEnableRemoteMirror:(BOOL)isOn {
    [self.pusherVM setIsRemoteMirrorEnabled:isOn];
}

- (void)onEnableWatermark:(BOOL)isOn {
    if (isOn) {
        UIImage *image = [UIImage imageNamed:@"watermark"];
        [self.pusherVM setWaterMark:image inRect:CGRectMake(0.1, 0.15, 120, 30)];
    } else {
        [self.pusherVM setWaterMark:nil inRect:CGRectZero];
    }
}

- (void)snapshotLocalVideo {
    [self.pusherVM snapshot];
}

#pragma mark - Settings ViewController Embeding

- (void)toggleEmbedVC:(UIViewController *)vc {
    if (self.currentEmbededVC != vc) {
        [self embedChildVC:vc];
        [self.audioEffectView hide];
    } else {
        [self unembedChildVC:vc];
    }
}

- (void)embedChildVC:(UIViewController *)vc {
    if (self.currentEmbededVC) {
        [self unembedChildVC:self.currentEmbededVC];
    }
    
    UINavigationController *naviVC = [[UINavigationController alloc] initWithRootViewController:vc];
    [self.hostVC addChildViewController:naviVC];
    [self.centerContainerView addSubview:naviVC.view];
    [naviVC.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.centerContainerView);
    }];
    [naviVC didMoveToParentViewController:self.hostVC];

    self.centerContainerView.hidden = NO;
    self.currentEmbededVC = vc;
}

- (void)unembedChildVC:(UIViewController * _Nullable)vc {
    if (!vc) { return; }
    [vc.navigationController willMoveToParentViewController:nil];
    [vc.navigationController.view removeFromSuperview];
    [vc.navigationController removeFromParentViewController];
    self.currentEmbededVC = nil;
    self.centerContainerView.hidden = YES;
}

@end
