/*
 * Module:   TRTCMoreSettingsViewController
 *
 * Function: 其它设置页
 *
 *    1. 其它设置项包括: 流控方案、双路编码开关、默认观看低清、重力感应和闪光灯切换
 *
 *    2. 发送自定义消息和SEI消息，两种消息的说明可参见TRTC的文档或TRTCCloud.h中的接口注释。
 *
 */

#import "TRTCMoreSettingsViewController.h"

#import "AppLocalized.h"
#import "TCUtil.h"

@interface TRTCMoreSettingsViewController ()

@property(strong, nonatomic) TRTCSettingsSwitchItem  *gSensor;
@property(strong, nonatomic) TRTCSettingsSwitchItem  *flashLight;
@property(strong, nonatomic) TRTCSettingsMessageItem *sendSEIMessage;
@property(strong, nonatomic) TRTCSettingsSegmentItem *streamControl;
@property(strong, nonatomic) TRTCSettingsSwitchItem  *twoWayCoding;
@property(strong, nonatomic) TRTCSettingsSwitchItem  *lowDefinition;
@property(strong, nonatomic) TRTCSettingsSwitchItem  *autoFocus;
@property(strong, nonatomic) TRTCSettingsSwitchItem  *playback;
@property(strong, nonatomic) TRTCSettingsSwitchItem  *playbackToTRTC;
@property(strong, nonatomic) TRTCSettingsMessageItem *testMsgItem;
@property(strong, nonatomic) TRTCSettingsMessageItem *msgToAudio;
@property(strong, nonatomic) TRTCSettingsMessageItem *msgToAudioByNetwork;
@property(strong, nonatomic) TRTCSettingsMessageItem *switchToStringRoom;
@property(strong, nonatomic) TRTCSettingsMessageItem *switchToIntRoom;
@property(strong, nonatomic) TRTCSettingsMessageItem *recordTypeItem;
@property(strong, nonatomic) TRTCSettingsSwitchItem  *localRecord;

@property(assign, nonatomic) BOOL enableVodAttachToTRTC;
@end

@implementation TRTCMoreSettingsViewController

- (NSString *)title {
    return TRTCLocalize(@"Demo.TRTC.Live.other");
}

- (void)viewDidLoad {
    [super viewDidLoad];

    __weak __typeof(self) wSelf = self;

    self.gSensor = [[TRTCSettingsSwitchItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.gSensor")
                                                            isOn:self.trtcCloudManager.gSensorEnabled
                                                          action:^(BOOL isOn) {
                                                              [wSelf onEnableGSensor:isOn];
                                                          }];

    self.flashLight     = [[TRTCSettingsSwitchItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.flashLight")
                                                               isOn:NO
                                                             action:^(BOOL isOn) {
                                                                 [wSelf onEnableFlashLight:isOn];
                                                             }];
    self.sendSEIMessage = [[TRTCSettingsMessageItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.sendSEIMessage")
                                                             placeHolder:@""
                                                                  action:^(NSString *_Nullable content) {
                                                                      [wSelf sendSeiMessage:content];
                                                                  }];

    if (DEBUGSwitch) {
        [self addDebugItems];
    } else {
        self.items = [@[
            self.gSensor,
            self.flashLight,
            self.sendSEIMessage,
        ] mutableCopy];
    }
}

- (void)addDebugItems {
    TRTCVideoConfig *     config = self.trtcCloudManager.videoConfig;
    __weak __typeof(self) wSelf  = self;
    self.streamControl           = [[TRTCSettingsSegmentItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.qosControlMode")
                                                                  items:@[ TRTCLocalize(@"Demo.TRTC.Live.customerMode"), TRTCLocalize(@"Demo.TRTC.Live.cloudMode") ]
                                                          selectedIndex:config.qosConfig.controlMode
                                                                 action:^(NSInteger index) {
                                                                     [wSelf onSelectQosControlModeIndex:index];
                                                                 }];

    self.twoWayCoding = [[TRTCSettingsSwitchItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.twoWayCoding")
                                                                 isOn:config.isSmallVideoEnabled
                                                               action:^(BOOL isOn) {
                                                                   [wSelf onEnableSmallVideo:isOn];
                                                               }];

    self.lowDefinition = [[TRTCSettingsSwitchItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.lowDefinition")
                                                                  isOn:config.prefersLowQuality
                                                                action:^(BOOL isOn) {
                                                                    [wSelf onEnablePrefersLowQuality:isOn];
                                                                }];

    self.autoFocus = [[TRTCSettingsSwitchItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.autofocus")
                                                              isOn:config.isAutoFocusOn
                                                            action:^(BOOL isOn) {
                                                                [wSelf onEnableAutoFocus:isOn];
                                                            }];
    self.playback  = [[TRTCSettingsSwitchItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.VOD")
                                                             isOn:self.trtcCloudManager.enableVOD
                                                           action:^(BOOL isOn) {
                                                               // 推送至TRTC辅路按钮打开时，vod player销毁前进行dettach TRTC
                                                               if (wSelf.enableVodAttachToTRTC && !isOn) {
                                                                   [wSelf onEnableAttachVodToTRTC:NO];
                                                               }
                                                               [wSelf onEnableVOD:isOn];
                                                               // 推送至TRTC辅路按钮打开时，vod player创建后进行attach至TRTC
                                                               if (wSelf.enableVodAttachToTRTC && isOn) {
                                                                   [wSelf onEnableAttachVodToTRTC:YES];
                                                               }
                                                           }];

    self.playbackToTRTC = [[TRTCSettingsSwitchItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.attachVodToTRTC")
                                                                   isOn:NO
                                                                 action:^(BOOL isOn) {
                                                                     [wSelf onEnableAttachVodToTRTC:isOn];
                                                                     wSelf.enableVodAttachToTRTC = isOn;
                                                                 }];

    self.testMsgItem = [[TRTCSettingsMessageItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.customMessage")
                                                          placeHolder:TRTCLocalize(@"Demo.TRTC.Live.testMessage")
                                                               action:^(NSString *message) {
                                                                   [wSelf sendMessage:message];
                                                               }];

    self.msgToAudio = [[TRTCSettingsMessageItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.voiceMessage")
                                                         placeHolder:TRTCLocalize(@"Demo.TRTC.Live.voiceMessageTest")
                                                              action:^(NSString *message) {
                                                                  [wSelf bindMsgToAudioFrame:message];
                                                              }];
    self.msgToAudioByNetwork = [[TRTCSettingsMessageItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.voiceNetworkMessageTest")
                                                                  placeHolder:TRTCLocalize(@"Demo.TRTC.Live.voiceNetworkMessageTestPlaceHolder")
                                                                       action:^(NSString *message) {
                                                                            [wSelf sendMsgToAudioPacket:message];
                                                                       }];

    self.switchToStringRoom = [[TRTCSettingsMessageItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.stringRoom")
                                                                 placeHolder:TRTCLocalize(@"Demo.TRTC.Live.stringRoomID")
                                                                      action:^(NSString *message) {
                                                                          [wSelf switchToStringRoom:message];
                                                                      }];

    self.switchToIntRoom = [[TRTCSettingsMessageItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.numRoom")
                                                              placeHolder:TRTCLocalize(@"Demo.TRTC.Live.numRoomID")
                                                                   action:^(NSString *message) {
                                                                       [wSelf switchToIntRoom:message];
                                                                   }];

    self.recordTypeItem = [[TRTCSettingsSegmentItem alloc]
        initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.recordingType")
                items:@[ TRTCLocalize(@"Demo.TRTC.Live.recordingTypeAudio"), TRTCLocalize(@"Demo.TRTC.Live.recordingTypeVideo"), TRTCLocalize(@"Demo.TRTC.Live.recordingTypeAudioAndVideo") ]
        selectedIndex:(int)self.trtcCloudManager.localRecordType
               action:^(NSInteger index) {
                   [wSelf onLocalRecordTypeSelect:index];
               }];

    self.localRecord = [[TRTCSettingsSwitchItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.localRecording")
                                                                isOn:self.trtcCloudManager.enableLocalRecord
                                                              action:^(BOOL isOn) {
                                                                  [wSelf onEnableLocalRecord:isOn];
                                                              }];

    self.items = [@[
        self.streamControl,
        self.twoWayCoding,
        self.lowDefinition,
        self.gSensor,
        self.flashLight,
        self.autoFocus,
        self.playback,
        self.playbackToTRTC,
        self.testMsgItem,
        self.sendSEIMessage,
        self.msgToAudio,
        self.msgToAudioByNetwork,
        self.switchToStringRoom,
        self.switchToIntRoom,
        self.recordTypeItem,
        self.localRecord,
    ] mutableCopy];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.gSensor.isOn = self.trtcCloudManager.gSensorEnabled;
    [self.tableView reloadData];
}

#pragma mark - Actions

- (void)onEnableGSensor:(BOOL)isOn {
    [self.trtcCloudManager setGSensorEnabled:isOn];
}

- (void)onEnableFlashLight:(BOOL)isOn {
    [self.trtcCloudManager setFlashLightEnabled:isOn];
}

- (void)sendSeiMessage:(NSString *)message {
    [self.trtcCloudManager sendSEIMessage:message];
}

- (void)onSelectQosControlModeIndex:(NSInteger)index {
    [self.trtcCloudManager setQosControlMode:index];
}

- (void)onEnableSmallVideo:(BOOL)isOn {
    [self.trtcCloudManager setSmallVideoEnabled:isOn];
}

- (void)onEnablePrefersLowQuality:(BOOL)isOn {
    [self.trtcCloudManager setPrefersLowQuality:isOn];
}

- (void)onToggleTorchLight {
    [self.trtcCloudManager switchTorch];
}

- (void)onEnableAutoFocus:(BOOL)isOn {
    [self.trtcCloudManager setAutoFocusEnabled:isOn];
}

- (void)onEnableVOD:(BOOL)isOn {
    [self.trtcCloudManager setEnableVOD:isOn];
}

- (void)onEnableAttachVodToTRTC:(BOOL)isOn {
    [self.trtcCloudManager setEnableAttachVodToTRTC:isOn];
}

- (void)sendMessage:(NSString *)message {
    [self.trtcCloudManager sendCustomMessage:message];
}

- (void)bindMsgToAudioFrame:(NSString *)message {
    [self.trtcCloudManager bindMsgToAudioFrame:message];
}

- (void)sendMsgToAudioPacket:(NSString *)message {
    [self.trtcCloudManager sendMsgToAudioPacket:message];
}

- (void)switchToStringRoom:(NSString *)roomId {
    TRTCSwitchRoomConfig *cfg = [[TRTCSwitchRoomConfig alloc] init];
    cfg.roomId                = 0;
    cfg.strRoomId             = roomId;
    [self.trtcCloudManager switchRoom:cfg];
}

- (void)switchToIntRoom:(NSString *)roomId {
    TRTCSwitchRoomConfig *cfg = [[TRTCSwitchRoomConfig alloc] init];
    cfg.roomId                = roomId.intValue;
    [self.trtcCloudManager switchRoom:cfg];
}

- (void)onLocalRecordTypeSelect:(NSInteger)index {
    TRTCRecordType type = TRTCRecordTypeBoth;
    switch (index) {
        case 0:
            type = TRTCRecordTypeAudio;
            break;
        case 1:
            type = TRTCRecordTypeVideo;
            break;
        case 2:
            type = TRTCRecordTypeBoth;
            break;
        default:
            break;
    }
    self.trtcCloudManager.localRecordType = type;
}

- (void)onEnableLocalRecord:(BOOL)isOn {
    if (isOn) {
        [self.trtcCloudManager startLocalRecording];
    } else {
        [self.trtcCloudManager stopLocalRecording];
    }
}
@end
