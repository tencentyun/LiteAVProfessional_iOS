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
#import "TRTCCloudDef.h"
#import "AppLocalized.h"
#import "TCUtil.h"

@interface                                            TRTCAudioSettingsViewController ()
@property(strong, nonatomic) TRTCSettingsButtonItem * recordItem;
@property(strong, nonatomic) TRTCSettingsSegmentItem *audioTypeItem;
@property(strong, nonatomic) TRTCSettingsSwitchItem * ansItem;
@property(strong, nonatomic) TRTCSettingsSwitchItem * aecItem;
@property(strong, nonatomic) TRTCSettingsSliderItem * captureVolume;
@property(strong, nonatomic) TRTCSettingsSliderItem * playVolume;
@property(strong, nonatomic) TRTCSettingsSwitchItem * earMonitoring;
@property(strong, nonatomic) TRTCSettingsSwitchItem * earPhoneMode;
@property(strong, nonatomic) TRTCSettingsSwitchItem * agcItem;
@property(strong, nonatomic) TRTCSettingsSwitchItem * volumeEvaluation;
@property(strong, nonatomic) TRTCSettingsSliderItem * earVolume;

@property(strong, nonatomic) TRTCSettingsSliderItem * voicePitch;
@property(strong, nonatomic) TRTCSettingsSwitchItem * soundCollection;
@property(strong, nonatomic) TRTCSettingsSwitchItem * speakerphone;
@property(strong, nonatomic) TRTCSettingsButtonItem * recordTypeItem;
@property(strong, nonatomic) TRTCSettingsSelectorItem * audiobitrateItem;
@property(strong, nonatomic) TRTCSettingsMessageItem * audioParallelMaxCountItem;

@property(strong, nonatomic) TRTCSettingsSwitchButtonItem * customAudioRendering;

@property(assign, nonatomic) NSInteger                recordTypeIndex;
@end

@implementation TRTCAudioSettingsViewController

- (NSString *)title {
    return TRTCLocalize(@"Demo.TRTC.Live.audio");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    __weak __typeof(self) wSelf  = self;
    TRTCAudioConfig *     config = self.trtcCloudManager.audioConfig;
    self.recordItem              = [[TRTCSettingsButtonItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.audioRecording")
                                                        buttonTitle:self.recordManager.isRecording ? TRTCLocalize(@"Demo.TRTC.Live.stop") : TRTCLocalize(@"Demo.TRTC.Live.audioRecording")
                                                             action:^{
                                                                 [wSelf onClickRecordButton];
                                                             }];
    self.audioTypeItem           = [[TRTCSettingsSegmentItem alloc]
        initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.audioType")
                items:@[ TRTCLocalize(@"Demo.TRTC.Live.audioTypeAuto"), TRTCLocalize(@"Demo.TRTC.Live.audioTypeMedia"), TRTCLocalize(@"Demo.TRTC.Live.audioTypeCalling") ]
        selectedIndex:self.trtcCloudManager.volumeType
               action:^(NSInteger index) {
                   [wSelf onSelectVolumeTypeIndex:index];
               }];
    self.ansItem                 = [[TRTCSettingsSwitchItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.ans")
                                                            isOn:self.trtcCloudManager.ansEnabled
                                                          action:^(BOOL isOn) {
                                                              [wSelf onEnableAns:isOn];
                                                          }];

    self.aecItem       = [[TRTCSettingsSwitchItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.aec")
                                                            isOn:self.trtcCloudManager.aecEnabled
                                                          action:^(BOOL isOn) {
                                                              [wSelf onEnableAec:isOn];
                                                          }];
    self.captureVolume = [[TRTCSettingsSliderItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.captureVolume")
                                                                 value:self.trtcCloudManager.captureVolume
                                                                   min:0
                                                                   max:150
                                                                  step:1
                                                            continuous:YES
                                                                action:^(float volume) {
                                                                    [wSelf onUpdateCaptureVolume:(NSInteger)volume];
                                                                }];
    self.playVolume    = [[TRTCSettingsSliderItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.playVolume")
                                                              value:self.trtcCloudManager.playoutVolume
                                                                min:0
                                                                max:150
                                                               step:1
                                                         continuous:YES
                                                             action:^(float volume) {
                                                                 [wSelf onUpdatePlayoutVolume:(NSInteger)volume];
                                                             }];

    self.earMonitoring = [[TRTCSettingsSwitchItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.earMonitoring")
                                                                  isOn:self.trtcCloudManager.audioConfig.isEarMonitoringEnabled
                                                                action:^(BOOL isOn) {
                                                                    [wSelf onEnableEarMonitoring:isOn];
                                                                }];

    self.earPhoneMode = [[TRTCSettingsSwitchItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.earPhoneMode")
                                                                 isOn:self.trtcCloudManager.audioRoute
                                                               action:^(BOOL isOn) {
                                                                   [wSelf onHandsFreeEnabled:!isOn];
                                                               }];
    self.agcItem      = [[TRTCSettingsSwitchItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.agc")
                                                            isOn:self.trtcCloudManager.agcEnabled
                                                          action:^(BOOL isOn) {
                                                              [wSelf onEnableAgc:isOn];
                                                          }];

    self.volumeEvaluation = [[TRTCSettingsSwitchItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.volumeEvaluation")
                                                                     isOn:self.trtcCloudManager.volumeEvaluationEnabled
                                                                   action:^(BOOL isOn) {
                                                                       [wSelf onEnableVolumeEvaluation:isOn];
                                                                   }];
    
    
    
    
    self.audiobitrateItem              = [[TRTCSettingsSelectorItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.audiobitrate")
                                                                items:TRTCAudioConfig.audiobitrateList
                                                        selectedIndex:3
                                                               action:^(NSInteger index) {
                                                                       [wSelf onAudiobitrateListSelect:index];
                                                               }];
    self.earVolume = [[TRTCSettingsSliderItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.earVolume")
                                                             value:100
                                                               min:0
                                                               max:150
                                                              step:1
                                                        continuous:YES
                                                            action:^(float volume) {
                                                                [wSelf onUpdateEarMonitoringVolume:(NSInteger)volume];
                                                            }];
    self.voicePitch = [[TRTCSettingsSliderItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.voicePitch")
                                                             value:0
                                                               min:-1.0
                                                               max:1.0
                                                              step:0.1
                                                        continuous:YES
                                                            action:^(float volume) {
                                                                [wSelf onUpdatevoicePitchVolume:volume];
                                                            }];


    self.soundCollection = [[TRTCSettingsSwitchItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.voiceCapture")
                                                                    isOn:config.isEnabled
                                                                  action:^(BOOL isOn) {
                                                                      [wSelf onEnableAudio:isOn];
                                                                  }];

    self.speakerphone   = [[TRTCSettingsSwitchItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.handsFree")
                                                                 isOn:config.route == TRTCAudioModeSpeakerphone
                                                               action:^(BOOL isOn) {
                                                                   [wSelf onEnableHandsFree:isOn];
                                                               }];
    self.recordTypeItem = [[TRTCSettingsSegmentItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.audioRecordingType")
                                                                   items:@[ TRTCLocalize(@"Demo.TRTC.Live.default"), TRTCLocalize(@"Demo.TRTC.Live.local"), TRTCLocalize(@"Demo.TRTC.Live.server") ]
                                                           selectedIndex:self.recordTypeIndex
                                                                  action:^(NSInteger index) {
                                                                      [wSelf onSelectRecordTypeIndex:index];
                                                                  }];
    self.audioParallelMaxCountItem = [[TRTCSettingsMessageItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.audioParallelMaxCount")
                                                                placeHolder:TRTCLocalize(@"")
                                                                    content:nil
                                                                actionTitle:TRTCLocalize(@"Demo.TRTC.Live.setting")
                                                                     action:^(NSString *count) {
        UInt32 maxCount = [count intValue];
        [wSelf.trtcCloudManager setRemoteAudioParallelParams:maxCount];
    }];
    
    self.customAudioRendering = [[TRTCSettingsSwitchButtonItem alloc] initWithTitle:@"自定义音频渲染" isOn:NO switchAction:^(BOOL isOn) {
                
    } playAction:^(TRTCAudioFrame* customAudioFrame){
        
    }];
    self.customAudioRendering.trtcCloud = self.trtcCloudManager.trtcCloud;
    
    [self.items addObject:self.recordItem];
    if (DEBUGSwitch) {
        self.items = [@[
            self.audioTypeItem,
            self.captureVolume,
            self.playVolume,
            self.ansItem,
            self.aecItem,
            self.agcItem,
            self.soundCollection,
            self.earMonitoring,
            self.earPhoneMode,
            self.earVolume,
            self.voicePitch,
            self.speakerphone,
            self.volumeEvaluation,
            self.recordTypeItem,
            self.recordItem,
            self.audiobitrateItem,
            self.audioParallelMaxCountItem,
            self.customAudioRendering,
        ] mutableCopy];
    } else {
        self.items = [@[
            self.audioTypeItem,
            self.ansItem,
            self.aecItem,
            self.captureVolume,
            self.playVolume,
            self.earMonitoring,
            self.earPhoneMode,
            self.agcItem,
            self.volumeEvaluation,
            self.audioParallelMaxCountItem,
        ] mutableCopy];
    }
}
#pragma mark - Actions
- (void)onClickRecordButton {
    if (self.recordManager.isRecording) {
        [self.recordManager stopRecord];
        [self shareAudioFile];
    } else {
        [self.recordManager startRecord:self.recordTypeIndex];
    }
    self.recordItem.buttonTitle = self.recordManager.isRecording ? @"停止" : @"录制";
    [self.tableView reloadData];
}

- (void)onSelectRecordTypeIndex:(NSInteger)index {
    self.recordTypeIndex = index;
}
- (void)onEnableHandsFree:(BOOL)isOn {
    TRTCAudioRoute route = isOn ? TRTCAudioModeSpeakerphone : TRTCAudioModeEarpiece;
    [self.trtcCloudManager setAudioRoute:route];
}
- (void)onEnableAudio:(BOOL)isOn {
    [self.trtcCloudManager setAudioEnabled:isOn];
}
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

- (void)onAudiobitrateListSelect:(NSInteger)index {
    NSArray *list = TRTCAudioConfig.audiobitrateList;
    if ((index >= 0) && (index < list.count) ) {
        NSInteger bit = [list[index] intValue];
        [self.trtcCloudManager.trtcCloud callExperimentalAPI:[self jsonStringFrom:@{
                        @"api" : @"setAudioQualityEx",
                        @"params" : @{@"bitrate" : @(bit)}
                    }]];
    }
}
- (NSString *)jsonStringFrom:(NSDictionary *)dict {
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:NULL];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

- (void)onUpdateEarMonitoringVolume:(NSInteger)volume {
    [self.trtcCloudManager setEarMonitoringVolume:volume];
}

- (void)onUpdatevoicePitchVolume:(double)volume {
    [self.trtcCloudManager setUpdatevoicePitchVolume:volume];
}

- (void)shareAudioFile {
    if (self.recordManager.audioFilePath.length == 0) {
        return;
    }
    NSURL *                   fileUrl      = [NSURL fileURLWithPath:self.recordManager.audioFilePath];
    UIActivityViewController *activityView = [[UIActivityViewController alloc] initWithActivityItems:@[ fileUrl ] applicationActivities:nil];
    [self presentViewController:activityView animated:YES completion:nil];
}



@end
