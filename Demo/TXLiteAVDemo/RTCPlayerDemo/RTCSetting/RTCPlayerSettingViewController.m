//
//  RTCPlayerSettingContainer.m
//  TXLiteAVDemo_Enterprise
//
//  Created by jiruizhang on 2020/12/3.
//  Copyright © 2020 Tencent. All rights reserved.
//

#import "RTCPlayerSettingViewController.h"

#import "AppLocalized.h"
#import "MBProgressHUD.h"
#import "Masonry.h"
#import "RTCSettingBottomBar.h"
#import "RTCSettingsBaseViewController.h"
#import "V2TXLiveDef.h"

@interface                                   RTCPlayerSettingViewController () <RTCSettingBottomBarDelegate>
@property(nonatomic, weak) UIViewController *hostVC;

@property(nonatomic, strong) RTCSettingBottomBar *settingBar;
@property(nonatomic, strong) UIView *             centerContainerView;

@property(nonatomic, strong, nullable) UIViewController *             currentEmbededVC;
@property(nonatomic, strong, nullable) RTCSettingsBaseViewController *settingsVC;

@property(nonatomic, strong) V2TXLivePlayer *player;

@end

@implementation RTCPlayerSettingViewController

- (instancetype)initWithHostVC:(UIViewController *)hostVC muteAudio:(BOOL)isAudioMuted muteVideo:(BOOL)isVideoMuted logView:(BOOL)isLogShow player:(V2TXLivePlayer *)player {
    self = [super init];
    if (self) {
        self.hostVC       = hostVC;
        self.isAudioMuted = isAudioMuted;
        self.isVideoMuted = isVideoMuted;
        self.isLogShow    = isLogShow;
        self.fillMode     = V2TXLiveFillModeFit;
        self.player = player;

        [self addBar];
        [self addCenterView];
    }
    return self;
}

- (void)setIsStart:(BOOL)isStart {
    _isStart = isStart;
    [self.settingBar updateItem:RTCSettingBarItemTypeStart value:isStart];
}

- (void)setIsVideoMuted:(BOOL)isVideoMuted {
    _isVideoMuted = isVideoMuted;
    [self.settingBar updateItem:RTCSettingBarItemTypeMuteVideo value:isVideoMuted];
}

- (void)setIsAudioMuted:(BOOL)isAudioMuted {
    _isAudioMuted = isAudioMuted;
    [self.settingBar updateItem:RTCSettingBarItemTypeMuteAudio value:isAudioMuted];
}

- (void)addBar {
    self.settingBar          = [RTCSettingBottomBar
        createInstance:@[ @(RTCSettingBarItemTypeStart), @(RTCSettingBarItemTypeMuteVideo), @(RTCSettingBarItemTypeMuteAudio), @(RTCSettingBarItemTypeFeature), @(RTCSettingBarItemTypeLog) ]];
    self.settingBar.delegate = self;
    [self.settingBar updateItem:RTCSettingBarItemTypeMuteAudio value:self.isAudioMuted];
    [self.settingBar updateItem:RTCSettingBarItemTypeLog value:self.isLogShow];

    [self addSubview:self.settingBar];
    [self.settingBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.equalTo(self);
        make.bottom.equalTo(self);
        make.height.mas_equalTo(44);
    }];
}

- (void)addCenterView {
    self.centerContainerView                    = [[UIView alloc] init];
    self.centerContainerView.layer.cornerRadius = 12;
    self.centerContainerView.clipsToBounds      = YES;
    UIVisualEffectView *effectView              = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
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

#pragma mark - RTCSettingBottomBarDelegate

- (void)RTCSettingBottomBarDidSelectItem:(RTCSettingBarItemType)type {
    switch (type) {
        case RTCSettingBarItemTypeLog:
            [self onClickLogButton];
            break;
        case RTCSettingBarItemTypeCamera:
            [self onClickSwitchCameraButton];
            break;
        case RTCSettingBarItemTypeMuteAudio:
            [self onClickAudioMuteButton];
            break;
        case RTCSettingBarItemTypeFeature:
            [self onClickFeatureSettingsButton];
            break;
        case RTCSettingBarItemTypeMuteVideo:
            [self onClickVideoMuteButton];
            break;
        case RTCSettingBarItemTypeStart:
            [self onClickStartSettingsButton];
            break;
        default:
            break;
    }
}

#pragma mark - Actions

- (void)onClickLogButton {
    if (self.delegate && [self.delegate respondsToSelector:@selector(RTCPlayerSettingVC:didClickLog:)]) {
        [self.delegate RTCPlayerSettingVC:self didClickLog:!self.isLogShow];
        self.isLogShow = !self.isLogShow;

        [self.settingBar updateItem:RTCSettingBarItemTypeLog value:self.isLogShow];
    }
}

- (void)onClickSwitchCameraButton {
}

- (void)onClickVideoMuteButton {
    if (self.delegate && [self.delegate respondsToSelector:@selector(RTCPlayerSettingVC:didClickMuteVideo:)]) {
        self.isVideoMuted = !self.isVideoMuted;
        [self.delegate RTCPlayerSettingVC:self didClickMuteVideo:self.isVideoMuted];
        [self.settingBar updateItem:RTCSettingBarItemTypeMuteVideo value:self.isVideoMuted];
    }
}

- (void)onClickAudioMuteButton {
    if (self.delegate && [self.delegate respondsToSelector:@selector(RTCPlayerSettingVC:didClickMuteAudio:)]) {
        self.isAudioMuted = !self.isAudioMuted;
        [self.delegate RTCPlayerSettingVC:self didClickMuteAudio:self.isAudioMuted];
        [self.settingBar updateItem:RTCSettingBarItemTypeMuteAudio value:self.isAudioMuted];
    }
}

- (void)onClickFeatureSettingsButton {
    if (!self.settingsVC) {
        self.settingsVC       = [[RTCSettingsBaseViewController alloc] init];
        self.settingsVC.title = V2Localize(@"V2.Live.LinkMicNew.setting");

        NSInteger        playoutVolume             = 100;
        V2TXLiveRotation rotation                  = V2TXLiveRotation0;
        BOOL             isVolumeEvaluationEnabled = NO;

        __weak __typeof(self) wSelf = self;

        self.settingsVC.items =
            @[
                [[RTCSettingsSliderItem alloc] initWithTitle:V2Localize(@"V2.Live.LinkMicNew.playingvolume")
                                                       value:playoutVolume
                                                         min:0
                                                         max:100
                                                        step:1
                                                  continuous:YES
                                                      action:^(float volume) {
                                                          [wSelf.player setPlayoutVolume:(NSInteger)volume];
                                                      }],
                [[RTCSettingsSegmentItem alloc] initWithTitle:V2Localize(@"V2.Live.LinkMicNew.fillingdirection")
                                                        items:@[ V2Localize(@"V2.Live.LinkMicNew.paved"), V2Localize(@"V2.Live.LinkMicNew.adaptive") ]
                                                selectedIndex:self.fillMode
                                                       action:^(NSInteger index) {
                                                           wSelf.fillMode = (index == 0) ? V2TXLiveFillModeFill : V2TXLiveFillModeFit;
                                                           [wSelf.player setRenderFillMode:wSelf.fillMode];
                                                       }],
                [[RTCSettingsSegmentItem alloc] initWithTitle:V2Localize(@"V2.Live.LinkMicNew.directionofrotation")
                                                        items:@[ @"0", @"90", @"180", @"270" ]
                                                selectedIndex:rotation
                                                       action:^(NSInteger index) {
                                                           [wSelf.player setRenderRotation:index];
                                                       }],
                [[RTCSettingsSwitchItem alloc] initWithTitle:V2Localize(@"V2.Live.LinkMicNew.volumeprompt")
                                                        isOn:isVolumeEvaluationEnabled
                                                      action:^(BOOL isOn) {
                                                          [wSelf.player enableVolumeEvaluation:isOn ? 200 : 0];

                                                          if (wSelf.delegate && [wSelf.delegate respondsToSelector:@selector(RTCPlayerSettingVC:enableVolumeEvaluation:)]) {
                                                              [wSelf.delegate RTCPlayerSettingVC:wSelf enableVolumeEvaluation:isOn];
                                                          }
                                                      }],
                [[RTCSettingsButtonItem alloc] initWithTitle:V2Localize(@"V2.Live.LinkMicNew.videosnapshot")
                                                 buttonTitle:V2Localize(@"V2.Live.LinkMicNew.snapshot")
                                                      action:^{
                                                          [wSelf.player snapshot];
                                                      }],
            ]
                .mutableCopy;
    }
    [self toggleEmbedVC:self.settingsVC];
}

- (void)onClickStartSettingsButton {
    if (self.delegate && [self.delegate respondsToSelector:@selector(RTCPlayerSettingVC:didClickStartVideo:)]) {
        self.isStart = !self.isStart;
        [self.delegate RTCPlayerSettingVC:self didClickStartVideo:self.isStart];
        [self.settingBar updateItem:RTCSettingBarItemTypeStart value:self.isStart];
    }
}

#pragma mark - Settings ViewController Embeding

- (void)toggleEmbedVC:(UIViewController *)vc {
    if (self.currentEmbededVC != vc) {
        [self embedChildVC:vc];
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
    self.currentEmbededVC           = vc;
}

- (void)unembedChildVC:(UIViewController *_Nullable)vc {
    if (!vc) {
        return;
    }
    [vc.navigationController willMoveToParentViewController:nil];
    [vc.navigationController.view removeFromSuperview];
    [vc.navigationController removeFromParentViewController];
    self.currentEmbededVC           = nil;
    self.centerContainerView.hidden = YES;
}

#pragma mark - Util

- (void)showText:(NSString *)text {
    MBProgressHUD *hud = [MBProgressHUD HUDForView:[UIApplication sharedApplication].delegate.window];
    if (hud == nil) {
        hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].delegate.window animated:NO];
    }
    hud.mode       = MBProgressHUDModeText;
    hud.label.text = text;
    [hud showAnimated:YES];
    [hud hideAnimated:YES afterDelay:1];
}

@end
