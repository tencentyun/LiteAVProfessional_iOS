/*
 * Module:   TRTCFeatureContainerViewController
 *
 * Function: 音视频设置弹出页，包含五个子页面：视频、音频、混流、跨房PK和其它
 *
 */

#import "TRTCFeatureContainerViewController.h"

#import "TRTCAudioSettingsViewController.h"
#import "TRTCMoreSettingsViewController.h"
#import "TRTCPKSettingsViewController.h"
#import "TRTCStreamSettingsViewController.h"
#import "TRTCSubRoomSettingsViewController.h"
#import "TRTCVideoSettingsViewController.h"

@interface TRTCFeatureContainerViewController ()

@property(strong, nonatomic) TRTCVideoSettingsViewController *  videoVC;
@property(strong, nonatomic) TRTCAudioSettingsViewController *  audioVC;
@property(strong, nonatomic) TRTCStreamSettingsViewController * streamVC;
@property(strong, nonatomic) TRTCPKSettingsViewController *     pkVC;
@property(strong, nonatomic) TRTCMoreSettingsViewController *   moreVC;
@property(strong, nonatomic) TRTCSubRoomSettingsViewController *subRoom;

@end

@implementation TRTCFeatureContainerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.videoVC                  = [[TRTCVideoSettingsViewController alloc] init];
    self.videoVC.trtcCloudManager = self.trtcCloudManager;

    self.audioVC                  = [[TRTCAudioSettingsViewController alloc] init];
    self.audioVC.trtcCloudManager = self.trtcCloudManager;
    self.audioVC.recordManager    = self.recordManager;

    self.streamVC                  = [[TRTCStreamSettingsViewController alloc] init];
    self.streamVC.trtcCloudManager = self.trtcCloudManager;

    self.pkVC                  = [[TRTCPKSettingsViewController alloc] init];
    self.pkVC.trtcCloudManager = self.trtcCloudManager;

    self.moreVC                   = [[TRTCMoreSettingsViewController alloc] init];
    self.moreVC.trtcCloudManager  = self.trtcCloudManager;
    self.subRoom                  = [[TRTCSubRoomSettingsViewController alloc] initWithCloudManager:self.trtcCloudManager];
    self.settingVCs = @[
        self.videoVC,
        self.audioVC,
        self.streamVC,
        self.pkVC,
        self.subRoom,
        self.moreVC,
    ];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.pkVC syncButtonStatus];
}

@end
