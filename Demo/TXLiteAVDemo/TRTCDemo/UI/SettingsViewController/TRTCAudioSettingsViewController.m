/*
* Module:   TRTCAudioSettingsViewController
*
* Function: 音频设置页
*
*    1. 通过TRTCCloudManager来设置音频参数。
*
*    2. TRTCAudioRecordManager用来控制录音，demo录音停止后会弹出分享。
*
*/

#import "TRTCAudioSettingsViewController.h"
#import "AppLocalized.h"

@interface TRTCAudioSettingsViewController()
@end

@implementation TRTCAudioSettingsViewController

- (NSString *)title {
    return TRTCLocalize(@"Demo.TRTC.Live.audio");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    __weak __typeof(self) wSelf = self;

    self.items = @[
        [[TRTCSettingsSegmentItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.audioType")
                                                 items:@[TRTCLocalize(@"Demo.TRTC.Live.audioTypeAuto"), TRTCLocalize(@"Demo.TRTC.Live.audioTypeMedia"), TRTCLocalize(@"Demo.TRTC.Live.audioTypeCalling")]
                                         selectedIndex:self.trtcCloudManager.volumeType
                                                action:^(NSInteger index) {
            [wSelf onSelectVolumeTypeIndex:index];
        }],
        
        [[TRTCSettingsSwitchItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.ans")
                                                 isOn:self.trtcCloudManager.ansEnabled
                                               action:^(BOOL isOn) {
            [wSelf onEnableAns:isOn];
        }],
        [[TRTCSettingsSwitchItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.aec")
                                                 isOn:self.trtcCloudManager.aecEnabled
                                               action:^(BOOL isOn) {
            [wSelf onEnableAec:isOn];
        }],

        [[TRTCSettingsSliderItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.captureVolume")
                                                value:self.trtcCloudManager.captureVolume min:0 max:150 step:1
                                           continuous:YES
                                               action:^(float volume) {
            [wSelf onUpdateCaptureVolume:(NSInteger)volume];
        }],
        [[TRTCSettingsSliderItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.playVolume")
                                                value:self.trtcCloudManager.playoutVolume min:0 max:150 step:1
                                           continuous:YES
                                               action:^(float volume) {
            [wSelf onUpdatePlayoutVolume:(NSInteger)volume];
        }],

        [[TRTCSettingsSwitchItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.earMonitoring")
                                                 isOn:self.trtcCloudManager.earMonitoringEnabled
                                               action:^(BOOL isOn) {
            [wSelf onEnableEarMonitoring:isOn];
        }],
        
        [[TRTCSettingsSwitchItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.earPhoneMode")
                                                 isOn:self.trtcCloudManager.audioRoute
                                               action:^(BOOL isOn) {
            [wSelf onHandsFreeEnabled:!isOn];
        }],
        [[TRTCSettingsSwitchItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.agc")
                                                 isOn:self.trtcCloudManager.agcEnabled
                                               action:^(BOOL isOn) {
            [wSelf onEnableAgc:isOn];
        }],
        [[TRTCSettingsSwitchItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.volumeEvaluation")
                                                 isOn:self.trtcCloudManager.volumeEvaluationEnabled
                                               action:^(BOOL isOn) {
            [wSelf onEnableVolumeEvaluation:isOn];
        }],

    ];
}

#pragma mark - Actions

- (void)onSelectVolumeTypeIndex:(NSInteger)index {
    TXSystemVolumeType type = (TXSystemVolumeType)index;
    [self.trtcCloudManager setVolumeType:type];
}

- (void)onEnableAgc:(BOOL)isOn {
    [self.trtcCloudManager setAgcEnabled:isOn];
}

- (void)onEnableAec:(BOOL)isOn {
    [self.trtcCloudManager setAecEnabled:isOn];
}

- (void)onEnableAns:(BOOL)isOn {
    [self.trtcCloudManager setAnsEnabled:isOn];
}

- (void)onUpdateCaptureVolume:(NSInteger)volume {
    [self.trtcCloudManager setCaptureVolume:volume];
}

- (void)onUpdatePlayoutVolume:(NSInteger)volume {
    [self.trtcCloudManager setPlayoutVolume:volume];
}

- (void)onEnableEarMonitoring:(BOOL)isOn {
    [self.trtcCloudManager setEarMonitoringEnabled:isOn];
}

- (void)onHandsFreeEnabled:(BOOL)isOn {
    TXAudioRoute route = isOn ? TXAudioRouteSpeakerphone : TXAudioRouteEarpiece;
    [self.trtcCloudManager setAudioRoute:route];
}

- (void)onEnableVolumeEvaluation:(BOOL)isOn {
    [self.trtcCloudManager setVolumeEvaluationEnabled:isOn];
}

@end
