//
//  TRTCLiveAudienceViewController.m
//  TXLiteAVDemo
//
//  Created by bluedang on 2021/6/1.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "TRTCLiveAudienceViewController.h"
#import "TRTCCdnPlayerManager.h"
#import "UIButton+TRTC.h"
#import "ColorMacro.h"
#import "AppLocalized.h"

@interface TRTCLiveAudienceViewController () <TXLivePlayListener>
@property (strong, nonatomic) TRTCCdnPlayerManager *cdnPlayer;
@property (strong, nonatomic) UIView *cdnView;
@end

@implementation TRTCLiveAudienceViewController

+ (instancetype)initWithTRTCCloudManager:(TRTCCloudManager*)cloudManager {
    TRTCLiveAudienceViewController *liveVC = [[TRTCLiveAudienceViewController alloc] initWithNibName:@"TRTCLiveViewController" bundle:nil];
    liveVC.cloudManager = cloudManager;

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
    
    [self setupAudienceCloudManager];
    
    [self setAnchorModeEnable:false];
    self.cdnBtn.backgroundColor = UIColorFromRGB(0x2364db);
    [self.cdnBtn setTitle:TRTCLocalize(@"Demo.TRTC.Live.switchCdnPlay") forState:UIControlStateNormal];
    [self.cdnBtn setTitle:TRTCLocalize(@"Demo.TRTC.Live.switchUdpPlay") forState:UIControlStateSelected];
    self.cdnBtn.layer.cornerRadius = 5.0;
    [self.cdnBtn addTarget:self action:@selector(onCdnBtnClick:)
          forControlEvents:UIControlEventTouchDown];
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
}

- (void)onSwitchRoleBtnClick:(UIButton*)button {
    button.selected = !button.selected;
    [self setAnchorModeEnable:button.isSelected];
    
    if (button.isSelected) {
        [self cdnStop];
    }
    
    if (button.isSelected) {
        [self setupAnchorCloudManager];
    } else {
        [self setupAudienceCloudManager];
    }
    self.stackLogBtn.selected = self.cloudManager.logEnable;
    [self layoutViews];
}

- (void)onCdnBtnClick:(UIButton*)button {
    if (!button.isSelected) {
        [self cdnStart];
    } else {
        [self cdnStop];
    }
}

- (void)onLogBtnClick:(UIButton*)button {
    if (!self.cdnBtn.selected) {
        [super onLogBtnClick:button];
    } else {
        button.selected = !button.selected;
        [self.cdnPlayer setDebugLogEnabled:button.selected];
    }
}


- (void)cdnStart {
    self.cdnBtn.selected = true;
    NSString *anchorId;
    for (NSString *userId in [self.cloudManager.viewDic allKeys]) {
        if ([userId isEqualToString:self.cloudManager.userId]) {
            continue;
        }
        anchorId = userId;
        break;
    }
    [self.cloudManager stopLive];
    [self.holderView addSubview:self.cdnView];
    [self.cdnPlayer startPlay:[self.cloudManager getCdnUrlOfUser:anchorId]];
    self.stackLogBtn.selected = self.cloudManager.logEnable;
    [self.cdnPlayer setDebugLogEnabled:self.stackLogBtn.selected];
}

- (void)cdnStop {
    self.cdnBtn.selected = false;

    [self.cdnPlayer stopPlay];
    [self.cdnView removeFromSuperview];
    [self.cloudManager enterLiveRoom:self.cloudManager.roomId userId:self.cloudManager.userId];
}

#pragma mark - TRTCCloudManagerDelegate delegate

- (void)onUserVideoAvailable:(NSString*)userId available:(bool)available {
    if (!available) {
        if (![userId isEqualToString:self.mainViewUserId]) {
            return;
        }
        self.mainViewUserId = self.cloudManager.userId;
    } else {
        if (!self.mainViewUserId) {
            self.mainViewUserId = userId;
        }
        [self.cloudManager.viewDic[userId] setDelegate:self];
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
        [self toastTip:(NSString *) param[EVT_MSG]];
    } else if (EvtID == PLAY_EVT_PLAY_END) {
        [self cdnStop];
    } else if (EvtID == EVT_PLAY_GET_MESSAGE) {
        NSData *msgData = param[@"EVT_GET_MSG"];
        if (msgData.length == 0) { return; }
        NSString *msg = [[NSString alloc] initWithData:msgData encoding:NSUTF8StringEncoding];
        if (msg) {
            [self toastTip:msg];
        }
    }
}

@end
