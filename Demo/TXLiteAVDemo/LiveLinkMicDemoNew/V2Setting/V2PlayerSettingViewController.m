//
//  V2TRTCPlayerSettingContainer.m
//  TXLiteAVDemo_Enterprise
//
//  Created by jiruizhang on 2020/12/3.
//  Copyright © 2020 Tencent. All rights reserved.
//

#import "V2PlayerSettingViewController.h"
#import "Masonry.h"
#import "V2SettingBottomBar.h"
#import <TCBeautyPanel/TCBeautyPanel.h>
#import "ThemeConfigurator.h"
#import "V2SettingsBaseViewController.h"
#import "V2TXLiveDef.h"
#import "MBProgressHUD.h"

@interface V2PlayerSettingViewController () <V2SettingBottomBarDelegate>
@property (nonatomic, weak) UIViewController *hostVC;

@property (nonatomic, strong) V2SettingBottomBar *settingBar;
@property (nonatomic, strong) UIView *centerContainerView;

@property (strong, nonatomic, nullable) UIViewController *currentEmbededVC;
@property (strong, nonatomic, nullable) V2SettingsBaseViewController *settingsVC;

@property (nonatomic, strong) V2TXLivePlayer *player;

@end

@implementation V2PlayerSettingViewController

- (instancetype)initWithHostVC:(UIViewController *)hostVC
                     muteAudio:(BOOL)isAudioMuted
                     muteVideo:(BOOL)isVideoMuted
                       logView:(BOOL)isLogShow
                        player:(V2TXLivePlayer *)player {
    self = [super init];
    if (self) {
        self.hostVC = hostVC;
        self.isAudioMuted = isAudioMuted;
        self.isVideoMuted = isVideoMuted;
        self.isLogShow = isLogShow;
        
        self.player = player;
        
        [self addBar];
        [self addCenterView];
    }
    return self;
}

//- (void)clearSettingVC {
//    if (self.settingsVC != nil) {
//        if (self.currentEmbededVC != nil) {
//            [self unembedChildVC:self.settingsVC];
//        }
//        self.settingsVC = nil;
//    }
//}

- (void)setIsStart:(BOOL)isStart {
    _isStart = isStart;
    [self.settingBar updateItem:V2TRTCSettingBarItemTypeStart value:isStart];
}

- (void)setIsVideoMuted:(BOOL)isVideoMuted {
    _isVideoMuted = isVideoMuted;
    [self.settingBar updateItem:V2TRTCSettingBarItemTypeMuteVideo value:isVideoMuted];
}

- (void)setIsAudioMuted:(BOOL)isAudioMuted {
    _isAudioMuted = isAudioMuted;
    [self.settingBar updateItem:V2TRTCSettingBarItemTypeMuteAudio value:isAudioMuted];
}

- (void)addBar {
    self.settingBar = [V2SettingBottomBar createInstance:@[
        @(V2TRTCSettingBarItemTypeStart),
        @(V2TRTCSettingBarItemTypeMuteVideo),
        @(V2TRTCSettingBarItemTypeMuteAudio),
        @(V2TRTCSettingBarItemTypeFeature),
        @(V2TRTCSettingBarItemTypeLog)]];
    self.settingBar.delegate = self;
    [self.settingBar updateItem:V2TRTCSettingBarItemTypeMuteAudio value:self.isAudioMuted];
    [self.settingBar updateItem:V2TRTCSettingBarItemTypeLog value:self.isLogShow];
    
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

#pragma mark - V2SettingBottomBarDelegate

- (void)v2SettingBottomBarDidSelectItem:(V2TRTCSettingBarItemType)type {
    switch (type) {
        case V2TRTCSettingBarItemTypeLog:
            [self onClickLogButton];
            break;
        case V2TRTCSettingBarItemTypeCamera:
            [self onClickSwitchCameraButton];
            break;
        case V2TRTCSettingBarItemTypeMuteAudio:
            [self onClickAudioMuteButton];
            break;
        case V2TRTCSettingBarItemTypeFeature:
            [self onClickFeatureSettingsButton];
            break;
        case V2TRTCSettingBarItemTypeMuteVideo:
            [self onClickVideoMuteButton];
            break;
        case V2TRTCSettingBarItemTypeStart:
            [self onClickStartSettingsButton];
            break;
        default:
            break;
    }
}

#pragma mark - Actions

- (void)onClickLogButton {
    if (self.delegate && [self.delegate respondsToSelector:@selector(v2PlayerSettingVC:didClickLog:)]) {
        [self.delegate v2PlayerSettingVC:self didClickLog:!self.isLogShow];
        self.isLogShow = !self.isLogShow;
        
        [self.settingBar updateItem:V2TRTCSettingBarItemTypeLog value:self.isLogShow];
    }
}

- (void)onClickSwitchCameraButton {
    
}

- (void)onClickVideoMuteButton {
    if (self.delegate && [self.delegate respondsToSelector:@selector(v2PlayerSettingVC:didClickMuteVideo:)]) {
        self.isVideoMuted = !self.isVideoMuted;
        [self.delegate v2PlayerSettingVC:self didClickMuteVideo:self.isVideoMuted];
        [self.settingBar updateItem:V2TRTCSettingBarItemTypeMuteVideo value:self.isVideoMuted];
    }
}

- (void)onClickAudioMuteButton {
    if (self.delegate && [self.delegate respondsToSelector:@selector(v2PlayerSettingVC:didClickMuteAudio:)]) {
        self.isAudioMuted = !self.isAudioMuted;
        [self.delegate v2PlayerSettingVC:self didClickMuteAudio:self.isAudioMuted];
        [self.settingBar updateItem:V2TRTCSettingBarItemTypeMuteAudio value:self.isAudioMuted];
    }
}

- (void)onClickFeatureSettingsButton {
    if (!self.settingsVC) {
        self.settingsVC = [[V2SettingsBaseViewController alloc] init];
        self.settingsVC.title = @"设置";
        
        NSInteger playoutVolume = 100;
        V2TXLiveFillMode fillMode = V2TXLiveFillModeFit;
        V2TXLiveRotation rotation = V2TXLiveRotation0;
        BOOL isVolumeEvaluationEnabled = NO;
        
        __weak __typeof(self) wSelf = self;
        
        self.settingsVC.items = @[
            [[V2SettingsSliderItem alloc] initWithTitle:@"播放音量"
                                                    value:playoutVolume min:0 max:100 step:1
                                               continuous:YES
                                                   action:^(float volume) {
                [wSelf.player setPlayoutVolume:(NSInteger)volume];
            }],
            [[V2SettingsSegmentItem alloc] initWithTitle:@"  画面填充方向"
                                                     items:@[@"自适应", @"铺满"]
                                             selectedIndex:fillMode
                                                    action:^(NSInteger index) {
                V2TXLiveFillMode fillMode = (index == 0)?V2TXLiveFillModeFit:V2TXLiveFillModeFill;
                [wSelf.player setRenderFillMode:fillMode];
            }],
            [[V2SettingsSegmentItem alloc] initWithTitle:@"  旋转方向"
                                                     items:@[@"0", @"90", @"180", @"270"]
                                             selectedIndex:rotation
                                                    action:^(NSInteger index) {
                [wSelf.player setRenderRotation:index];
            }],
            [[V2SettingsSwitchItem alloc] initWithTitle:@"音量提示"
                                                     isOn:isVolumeEvaluationEnabled
                                                   action:^(BOOL isOn) {
                [wSelf.player enableVolumeEvaluation:isOn];
                
                if (wSelf.delegate && [wSelf.delegate respondsToSelector:@selector(v2PlayerSettingVC:enableVolumeEvaluation:)]) {
                    [wSelf.delegate v2PlayerSettingVC:wSelf enableVolumeEvaluation:isOn];
                }
            }],
            [[V2SettingsButtonItem alloc] initWithTitle:@"视频截图" buttonTitle:@"截图" action:^{
                [wSelf.player snapshot];
            }],
        ].mutableCopy;
    }
    [self toggleEmbedVC:self.settingsVC];
}

- (void)onClickStartSettingsButton {
    if (self.delegate && [self.delegate respondsToSelector:@selector(v2PlayerSettingVC:didClickStartVideo:)]) {
        self.isStart = !self.isStart;
        [self.delegate v2PlayerSettingVC:self didClickStartVideo:self.isStart];
        [self.settingBar updateItem:V2TRTCSettingBarItemTypeStart value:self.isStart];
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

#pragma mark - Util

- (void)showText:(NSString *)text {
    MBProgressHUD *hud = [MBProgressHUD HUDForView:[UIApplication sharedApplication].delegate.window];
    if (hud == nil) {
        hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].delegate.window animated:NO];
    }
    hud.mode = MBProgressHUDModeText;
    hud.label.text = text;
    [hud showAnimated:YES];
    [hud hideAnimated:YES afterDelay:1];
}

@end
