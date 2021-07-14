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

@interface TRTCMoreSettingsViewController ()

@property (strong, nonatomic) TRTCSettingsSwitchItem *gSensor;

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
    
    self.items = @[
        self.gSensor
        ,
        [[TRTCSettingsSwitchItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.flashLight")
                                                 isOn:NO
                                               action:^(BOOL isOn) {
            [wSelf onEnableFlashLight:isOn];
        }],
        
        [[TRTCSettingsMessageItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.sendSEIMessage") placeHolder:@""
                                                action:^(NSString * _Nullable content) {
            [wSelf sendSeiMessage:content];
        }],
    ];
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

@end
