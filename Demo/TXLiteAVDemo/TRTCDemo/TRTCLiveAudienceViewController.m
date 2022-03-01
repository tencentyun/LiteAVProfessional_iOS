//
//  TRTCLiveAudienceViewController.m
//  TXLiteAVDemo
//
//  Created by bluedang on 2021/6/1.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "TRTCLiveAudienceViewController.h"

#import "AppLocalized.h"
#import "ColorMacro.h"
#import "TRTCCdnPlayerManager.h"
#import "UIButton+TRTC.h"


@interface                                         TRTCLiveAudienceViewController () <TXLivePlayListener>
@property(strong, nonatomic) TRTCCdnPlayerManager *cdnPlayer;
@property(strong, nonatomic) UIView *              cdnView;
@property(nonatomic, assign) BOOL isSwitchSDN;
@property(strong, nonatomic) NSString *anchorId;

@end

@implementation TRTCLiveAudienceViewController

+ (instancetype)initWithTRTCCloudManager:(TRTCCloudManager *)cloudManager {
    TRTCLiveAudienceViewController *liveVC = [[TRTCLiveAudienceViewController alloc] initWithNibName:@"TRTCLiveViewController" bundle:nil];
    liveVC.cloudManager                    = cloudManager;

    [cloudManager setDelegate:liveVC];
    return liveVC;
}

- (TRTCCdnPlayerManager *)cdnPlayer {
    if (!_cdnPlayer) {
        _cdnPlayer = [[TRTCCdnPlayerManager alloc] initWithContainerView:self.cdnView delegate:self];
    }
    return _cdnPlayer;
}

- (UIView *)cdnView {
    if (!_cdnView) {
        _cdnView = [[UIView alloc] initWithFrame:self.holderView.frame];
    }
    return _cdnView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.cdnPlayerVC.manager = self.cdnPlayer;
    [self setupAudienceCloudManager];

    [self setAnchorModeEnable:false];
    self.cdnBtn.backgroundColor = UIColorFromRGB(0x2364db);
    [self.cdnBtn setTitle:TRTCLocalize(@"Demo.TRTC.Live.switchCdnPlay") forState:UIControlStateNormal];
    [self.cdnBtn setTitle:TRTCLocalize(@"Demo.TRTC.Live.switchUdpPlay") forState:UIControlStateSelected];
    self.cdnBtn.layer.cornerRadius = 5.0;
    [self.cdnBtn addTarget:self action:@selector(onCdnBtnClick:) forControlEvents:UIControlEventTouchDown];

    [self setupChorus];
}

- (void)setAnchorModeEnable:(BOOL)enable {
    [self.logBtn setHidden:!enable];
    [self.stackLogBtn setHidden:enable];

    [self.switchCamBtn setHidden:!enable];
    [self.closeCamBtn setHidden:!enable];
    [self.beautyBtn setHidden:!enable];
    [self.audioEffectBtn setHidden:!enable];
    [self.settingsBtn setHidden:!enable];
    [self.muteMic setHidden:!enable];
    [self.cdnBtn setHidden:enable];
    [self.cdnSettingBtn setHidden:!enable];
    [self.audioEffectSettingBtn setHidden:!enable];
}

/// 当身份时切换时，需重置UI状态
- (void)resetUIState {
    [self.closeCamBtn setSelected:NO];
    [self.muteMic setSelected:NO];
    [self.switchCamBtn setSelected:NO];
}

- (void)onSwitchRoleBtnClick:(UIButton *)button {
    button.selected = !button.selected;
    [self setAnchorModeEnable:button.isSelected];
    if (button.isSelected) {
        if (self.cdnBtn.selected) {
            [self cdnStop];
        }
        self.cdnSettingBtn.hidden = YES;
        // 重置当前UI状态
        [self resetUIState];
        [self setupAnchorCloudManager];
    } else {
        [self setupAudienceCloudManager];
    }
    self.stackLogBtn.selected = self.cloudManager.logEnable;
    [self layoutViews];
}

- (void)onCdnBtnClick:(UIButton *)button {
    if (!button.isSelected) {
        [self cdnStart];
    } else {
        [self cdnStop];
    }
}

- (void)onLogBtnClick:(UIButton *)button {
    if (!self.cdnBtn.selected) {
        [super onLogBtnClick:button];
    } else {
        button.selected = !button.selected;
        [self.cdnPlayer setDebugLogEnabled:button.selected];
    }
}

- (void)cdnStart {
    self.cdnBtn.selected = true;
    self.cdnSettingBtn.hidden = NO;
    self.userControlBtn.hidden = YES;
    for (NSString *userId in [self.cloudManager.viewDic allKeys]) {
        if ([userId isEqualToString:self.cloudManager.userId]) {
            continue;
        }
        TRTCVideoView *view = self.cloudManager.viewDic[userId];
        if (view.userConfig.isSubStream) {
            continue;
        }
        self.anchorId = userId;
        break;
    }
    [self.cloudManager stopLive];
    _isSwitchSDN = YES;
    [self.holderView addSubview:self.cdnView];
    self.stackLogBtn.selected = self.cloudManager.logEnable;
}

- (void)cdnStop {
    _isSwitchSDN = NO;
    self.cdnBtn.selected = false;
    self.cdnSettingBtn.hidden = YES;
    self.userControlBtn.hidden = NO;
    [self.cdnPlayer stopPlay];
    [self.cdnView removeFromSuperview];
    [self.cloudManager enterLiveRoom:self.cloudManager.roomId userId:self.cloudManager.userId];
}

#pragma mark - TRTCCloudManagerDelegate delegate

- (void)onUserVideoAvailable:(NSString *)userId available:(bool)available {
    [super onUserVideoAvailable:userId available:available];
    NSDictionary *viewDic = self.cloudManager.viewDic;
    if (available) {
        if (!self.mainViewUserId || viewDic.count == 1) {
            self.mainViewUserId = userId;
        }
    }

    [self layoutViews];
}

- (void)onEnterRoom:(NSInteger)result {
    [super onEnterRoom:result];
    self.stackLogBtn.selected = self.cloudManager.logEnable;
    [self.cloudManager setLogEnable:self.cloudManager.logEnable];
}

#pragma mark - TXLivePlayListener

- (void)onPlayEvent:(int)EvtID withParam:(NSDictionary *)param {
    if (EvtID == PLAY_ERR_NET_DISCONNECT) {
        [self cdnStop];
        [self toastTip:(NSString *)param[EVT_MSG]];
    } else if (EvtID == PLAY_EVT_PLAY_END) {
        [self cdnStop];
    } else if (EvtID == EVT_PLAY_GET_MESSAGE) {
        NSData *msgData = param[@"EVT_GET_MSG"];
        if (msgData.length == 0) {
            return;
        }
        NSString *msg = [[NSString alloc] initWithData:msgData encoding:NSUTF8StringEncoding];
        if (msg) {
            [self toastTip:msg];
        }
    }
}

- (void)dealloc
{
    self.cloudManager.videoConfig.isEnabled = YES;
    self.cloudManager.videoConfig.localRenderParams.rotation = 0;
}

-(void)onExitRoom:(NSInteger)reason {
    [super onExitRoom:reason];
    if (_isSwitchSDN) {
        _isSwitchSDN = NO;
        [self.cdnPlayer startPlay:[self.cloudManager getCdnUrlOfUser:self.anchorId]];
        [self.cdnPlayer setDebugLogEnabled:self.stackLogBtn.selected];
    }
}
@end
