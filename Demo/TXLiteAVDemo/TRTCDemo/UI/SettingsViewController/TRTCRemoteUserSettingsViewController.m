/*
 * Module:   TRTCRemoteUserSettingsViewController
 *
 * Function: 房间内其它用户（即远端用户）的设置页
 *
 *    1. 通过TRTCRemoteUserManager来管理各项设置
 *
 */

#import "TRTCRemoteUserSettingsViewController.h"

#import "AppLocalized.h"
#import "ColorMacro.h"
#import "MBProgressHUD.h"
#import "Masonry.h"
#import "TRTCCloudManager.h"
#import "TCUtil.h"
@interface                                         TRTCRemoteUserSettingsViewController ()
@property(strong, nonatomic) TRTCRemoteUserConfig *userSettings;
@property(strong, nonatomic) TRTCSettingsSwitchItem *audioParallelMustPlaySwitch;
@end

@implementation TRTCRemoteUserSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title                       = self.userId;
    UILabel *tlabel                  = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];
    tlabel.text                      = self.navigationItem.title;
    tlabel.textColor                 = [UIColor whiteColor];
    tlabel.backgroundColor           = [UIColor clearColor];
    tlabel.adjustsFontSizeToFitWidth = YES;
    tlabel.textAlignment             = NSTextAlignmentCenter;
    [tlabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(200);
        make.height.mas_equalTo(35);
    }];

    self.navigationItem.titleView = tlabel;

    [self setupBackgroudColor];

    TRTCVideoView *view = self.trtcCloudManager.viewDic[self.userId];
    self.userSettings   = view.userConfig;

    __weak __typeof(self) wSelf = self;
    
    
    self.audioParallelMustPlaySwitch = [[TRTCSettingsSwitchItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.audioParallelMustPlay")
                                                                           isOn:_userSettings.isAudioParallelMustPlayed
                                                                         action:^(BOOL isOn) {
                                                                              [wSelf onParallelMustPlayAudio:isOn];
    }];

    self.items = [@[
        [[TRTCSettingsSwitchItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.enableVideo")
                                                 isOn:!_userSettings.isVideoMuted
                                               action:^(BOOL isOn) {
                                                   [wSelf onMuteVideo:!isOn];
                                               }],
        self.audioParallelMustPlaySwitch,
        [[TRTCSettingsSwitchItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.enableAudio")
                                                 isOn:!_userSettings.isAudioMuted
                                               action:^(BOOL isOn) {
                                                   [wSelf onMuteAudio:!isOn];
                                               }],
        [[TRTCSettingsSegmentItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.fillMode")
                                                 items:@[ TRTCLocalize(@"Demo.TRTC.Live.fill"), TRTCLocalize(@"Demo.TRTC.Live.fit") ]
                                         selectedIndex:(_userSettings.renderParams.fillMode == TRTCVideoFillMode_Fill) ? 0 : 1
                                                action:^(NSInteger index) {
                                                    [wSelf onSelectFillModeIndex:index];
                                                }],
        [[TRTCSettingsSwitchItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.enableMirror")
                                                 isOn:(_userSettings.renderParams.mirrorType == TRTCVideoMirrorTypeDisable) ? false : true
                                               action:^(BOOL isOn) {
                                                   [wSelf onEnableMirror:isOn];
                                               }],
        [[TRTCSettingsSegmentItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.picRotation")
                                                 items:@[ @"0", @"90", @"180", @"270" ]
                                         selectedIndex:_userSettings.renderParams.rotation
                                                action:^(NSInteger index) {
                                                    [wSelf onSelectRotationIndex:index];
                                                }],
        [[TRTCSettingsSliderItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.volumeNum")
                                                value:_userSettings.volume
                                                  min:0
                                                  max:100
                                                 step:1
                                           continuous:YES
                                               action:^(float volume) {
                                                   [wSelf onChangeVolume:volume];
                                               }],

        [[TRTCSettingsSelectorItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.snapshot") items:@[TRTCLocalize(@"Demo.TRTC.Live.streamSnapshot"), TRTCLocalize(@"Demo.TRTC.Live.Screenshot")] selectedIndex:0 action:^(NSInteger index) {
            [wSelf snapshotVideoWithType:TRTCVideoStreamTypeBig sourceIndex:index];
        }],
    ] mutableCopy];
    
    
    if([TCUtil getDEBUGSwitch]){
        [self.items addObject:  [[TRTCSettingsSelectorItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.secondarystreamSnapshot") items:@[TRTCLocalize(@"Demo.TRTC.Live.streamSnapshot"), TRTCLocalize(@"Demo.TRTC.Live.Screenshot")] selectedIndex:0 action:^(NSInteger index) {
            [wSelf snapshotVideoWithType:TRTCVideoStreamTypeSub sourceIndex:index];
        }]];
    }
}

- (void)setupBackgroudColor {
    UIColor *startColor = [UIColor colorWithRed:19.0 / 255.0 green:41.0 / 255.0 blue:75.0 / 255.0 alpha:1];
    UIColor *endColor   = [UIColor colorWithRed:5.0 / 255.0 green:12.0 / 255.0 blue:23.0 / 255.0 alpha:1];

    NSArray *colors = @[ (id)startColor.CGColor, (id)endColor.CGColor ];

    CAGradientLayer *layer = [CAGradientLayer layer];
    layer.colors           = colors;
    layer.startPoint       = CGPointMake(0, 0);
    layer.endPoint         = CGPointMake(1, 1);
    layer.frame            = self.view.bounds;

    [self.view.layer insertSublayer:layer atIndex:0];
}

#pragma mark - Actions

- (void)onMuteVideo:(BOOL)isMuted {
    _userSettings.isVideoMuted = isMuted;
    [self.trtcCloudManager setRemoteVideoMute:isMuted userId:self.userId];
}

- (void)onParallelMustPlayAudio:(BOOL)isMustPlayed {
    BOOL isSuccess = [self.trtcCloudManager setRemoteAudioParallelParams:isMustPlayed userId:self.userId];
    _userSettings.isAudioParallelMustPlayed = isSuccess ? isMustPlayed : !isMustPlayed;
    
    if (!isSuccess) {
        self.audioParallelMustPlaySwitch.isOn = _userSettings.isAudioParallelMustPlayed;
        [self refreshDataAtIndex:[self.items indexOfObject:self.audioParallelMustPlaySwitch] inSection:0];
    }
}

- (void)onMuteAudio:(BOOL)isMuted {
    _userSettings.isAudioMuted = isMuted;
    [self.trtcCloudManager setRemoteAudioMute:isMuted userId:self.userId];
}

- (void)onSelectFillModeIndex:(NSInteger)index {
    TRTCVideoFillMode mode              = index == 0 ? TRTCVideoFillMode_Fill : TRTCVideoFillMode_Fit;
    _userSettings.renderParams.fillMode = mode;
    if (_userSettings.isSubStream) {
        NSString *userId = [self.userId substringWithRange:NSMakeRange(0, [self.userId length] - 4)];
        [self.trtcCloudManager setRemoteSubStreamRenderParams:_userSettings.renderParams userId:userId];
        return;
    }
    [self.trtcCloudManager setRemoteRenderParams:_userSettings.renderParams userId:self.userId];
}

- (void)onSelectRotationIndex:(NSInteger)index {
    _userSettings.renderParams.rotation = index;
    if (_userSettings.isSubStream) {
        NSString *userId = [self.userId substringWithRange:NSMakeRange(0, [self.userId length] - 4)];
        [self.trtcCloudManager setRemoteSubStreamRenderParams:_userSettings.renderParams userId:userId];
        return;
    }
    [self.trtcCloudManager setRemoteRenderParams:_userSettings.renderParams userId:self.userId];
}

- (void)onEnableMirror:(BOOL)isEnabled {
    TRTCVideoMirrorType mode              = isEnabled ? TRTCVideoMirrorTypeEnable : TRTCVideoMirrorTypeDisable;
    _userSettings.renderParams.mirrorType = mode;
    [self.trtcCloudManager setRemoteRenderParams:_userSettings.renderParams userId:self.userId];
}

- (void)onChangeVolume:(NSInteger)volume {
    _userSettings.volume = volume;
    [self.trtcCloudManager setRemoteVolume:(int)volume userId:self.userId];
}

- (void)snapshotVideoWithType:(TRTCVideoStreamType)type sourceIndex:(NSInteger)index {
    __weak __typeof(self) wSelf = self;
    NSString *userId = _userSettings.isSubStream ? [self.userId substringWithRange:NSMakeRange(0, [self.userId length] - 4)] : self.userId;
    [self.trtcCloudManager.trtcCloud snapshotVideo:userId
                                    type:type
                              sourceType:(TRTCSnapshotSourceType)index
                         completionBlock:^(TXImage *image) {
        if (image && [image isKindOfClass:[TXImage class]]) {
            UIImage *activityImage = image.shareActivityImage;
            if (activityImage) {
                [wSelf shareImage:activityImage];
                return;
            }
        }
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = TRTCLocalize(@"Demo.TRTC.Live.noImage");
        [hud showAnimated:YES];
        [hud hideAnimated:YES afterDelay:1];
    }];
}

- (void)shareImage:(UIImage *)image {
    UIActivityViewController *vc = [[UIActivityViewController alloc] initWithActivityItems:@[ image ] applicationActivities:nil];
    [self presentViewController:vc animated:YES completion:nil];
}

@end
