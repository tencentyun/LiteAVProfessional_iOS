/*
* Module:   TRTCVideoSettingsViewController
*
* Function: 视频设置页
*
*    1. 通过TRTCCloudManager来设置视频参数
*
*    2. 设置分辨率后，码率的设置范围以及默认值会根据分辨率进行调整
*
*/

#import "TRTCVideoSettingsViewController.h"
#import "MBProgressHUD.h"
#import "AppLocalized.h"

#import "TRTCVideoConfig.h"

@interface TRTCVideoSettingsViewController ()

@property (strong, nonatomic) TRTCSettingsSliderItem *bitrateItem;
@property (strong, nonatomic) TRTCSettingsSegmentItem *localRotation;
@property (strong, nonatomic) TRTCSettingsSegmentItem *encodeRotation;
@property (assign, nonatomic) CGSize blackNalSize;

@end

@implementation TRTCVideoSettingsViewController

- (NSString *)title {
    return TRTCLocalize(@"Demo.TRTC.Live.video");
}

- (void)viewDidLoad {
    [super viewDidLoad];

    TRTCVideoConfig *config = self.trtcCloudManager.videoConfig;
    __weak __typeof(self) wSelf = self;
    
    self.bitrateItem = [[TRTCSettingsSliderItem alloc]
                        initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.setBitrate")
                        value:0 min:0 max:0 step:0
                        continuous:YES
                        action:^(float bitrate) {
        [wSelf onSetBitrate:bitrate];
    }];
    
    self.localRotation = [[TRTCSettingsSegmentItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.previewRotation")
                                                                  items:@[@"0", @"90", @"180", @"270"]
                                                          selectedIndex:0
                                                                 action:^(NSInteger index) {
                             [wSelf onSelectLocalRotation:index];
    }];
    
    
    self.encodeRotation = [[TRTCSettingsSegmentItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.encodeRotation")
                                                                   items:@[@"0", @"90", @"180", @"270"]
                                                           selectedIndex:0
                                                                  action:^(NSInteger index) {
                              [wSelf onSelectEncodeRotation:index];
    }];
        
    self.items = @[
        [[TRTCSettingsSelectorItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.setResolution")
                                                  items:TRTCVideoConfig.resolutionNames
                                          selectedIndex:config.resolutionIndex
                                                 action:^(NSInteger index) {
            [wSelf onSelectResolutionIndex:index];
        }],
        
        [[TRTCSettingsSelectorItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.setFps")
                                                  items:TRTCVideoConfig.fpsList
                                          selectedIndex:config.fpsIndex
                                                 action:^(NSInteger index) {
            [wSelf onSelectFpsIndex:index];
        }],
        self.bitrateItem,
        [[TRTCSettingsSegmentItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.setPicPreferen")
                                                 items:@[TRTCLocalize(@"Demo.TRTC.Live.priorFlow"), TRTCLocalize(@"Demo.TRTC.Live.priorClear")]
                                         selectedIndex:config.qosPreferenceIndex
                                                action:^(NSInteger index) {
            [wSelf onSelectQosPreferenceIndex:index];
        }],
        [[TRTCSettingsSegmentItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.pictureDir")
                                                 items:@[TRTCLocalize(@"Demo.TRTC.Live.horMode"), TRTCLocalize(@"Demo.TRTC.Live.verMode")]
                                         selectedIndex:config.videoEncConfig.resMode
                                                action:^(NSInteger index) {
            [wSelf onSelectResolutionModelIndex:index];
        }],
        [[TRTCSettingsSegmentItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.fillMode")
                                                 items:@[TRTCLocalize(@"Demo.TRTC.Live.fill"), TRTCLocalize(@"Demo.TRTC.Live.fit")]
                                         selectedIndex:config.localRenderParams.fillMode
                                                action:^(NSInteger index) {
            [wSelf onSelectFillModeIndex:index];
        }],
        
        self.localRotation,
        self.encodeRotation,
        
        [[TRTCSettingsSegmentItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.preMirror")
                                                 items:@[TRTCLocalize(@"Demo.TRTC.Live.autoMirror"),
                                                         TRTCLocalize(@"Demo.TRTC.Live.enableMirror"),
                                                         TRTCLocalize(@"Demo.TRTC.Live.disableMirror"),
                                                         ] selectedIndex:0 action:^(NSInteger index) {
            [wSelf onSelectLocalMirrorIndex:index];
        }],
        
        [[TRTCSettingsSwitchItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.remoteMirror")
                                                 isOn:config.isRemoteMirrorEnabled
                                               action:^(BOOL isOn) {
            [wSelf onEnableRemoteMirror:isOn];
        }],
        [[TRTCSettingsSwitchItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.enableWaterMark") isOn:config.isWaterMarkEnabled
                                               action:^(BOOL isOn) {
            [wSelf onEnableWatermark:isOn];
        }],
        [[TRTCSettingsSwitchItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.pauseCapture")
                                                 isOn:config.isScreenCapturePaused
                                               action:^(BOOL isOn) {
            [wSelf onPauseScreenCapture:isOn];
        }],
        [[TRTCSettingsSwitchItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.sharpnessEnhancement") isOn:config.isSharpnessEnhancementEnabled action:^(BOOL isOn) {
            [wSelf onEnableSharpnessEnhancement:isOn];
        }],
        [[TRTCSettingsSwitchItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.videoMuteImage")
                                                 isOn:config.isVideoMuteImage
                                               action:^(BOOL isOn) {
            [wSelf onEnableVideoMuteImage:isOn];
        }],
        
        [[TRTCSettingsSwitchItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.videoTimestampWaterMark")
                                                 isOn:config.isTimestampWaterMark
                                               action:^(BOOL isOn) {
            [wSelf onEnableTimestampWaterMark:isOn];
        }],
        
        [[TRTCSettingsButtonItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.localVideoSnapshot") buttonTitle:TRTCLocalize(@"Demo.TRTC.Live.snapshot") action:^{
            [wSelf snapshotLocalVideo];
        }],
    ];
    [self updateBitrateItemWithResolution:config.videoEncConfig.videoResolution];
}

- (void)viewWillAppear:(BOOL)animated {
    if (self.trtcCloudManager.gSensorEnabled) {
        self.localRotation.selectedIndex = 0;
        self.encodeRotation.selectedIndex = 0;
    }
    [self.tableView reloadData];
}

- (void)showText:(NSString *)text {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.label.text = text;
    [hud showAnimated:YES];
    [hud hideAnimated:YES afterDelay:1];
}

#pragma mark - Actions

- (void)onSelectResolutionIndex:(NSInteger)index {
    TRTCVideoResolution resolution = [TRTCVideoConfig.resolutions[index] integerValue];
    [self.trtcCloudManager setResolution:resolution];
    [self updateBitrateItemWithResolution:resolution];
}

- (void)onSelectFpsIndex:(NSInteger)index {
    [self.trtcCloudManager setVideoFps:[TRTCVideoConfig.fpsList[index] intValue]];
}

- (void)onSetBitrate:(float)bitrate {
    [self.trtcCloudManager setVideoBitrate:bitrate];
}

- (void)onSelectLocalRotation:(NSInteger)index {
    if (index && self.trtcCloudManager.gSensorEnabled) {
        [self.trtcCloudManager setGSensorEnabled:false];
        [self showText:TRTCLocalize(@"Demo.TRTC.gSenorClose")];
    }
    [self.trtcCloudManager setLocalVideoRotation:index];
}

- (void)onSelectEncodeRotation:(NSInteger)index {
    if (index && self.trtcCloudManager.gSensorEnabled) {
        [self.trtcCloudManager setGSensorEnabled:false];
        [self showText:TRTCLocalize(@"Demo.TRTC.gSenorClose")];
    }
    [self.trtcCloudManager setEncodeVideoRotation:index];
}

- (void)onSelectQosPreferenceIndex:(NSInteger)index {
    TRTCVideoQosPreference qos = index == 0 ? TRTCVideoQosPreferenceSmooth : TRTCVideoQosPreferenceClear;
    [self.trtcCloudManager setQosPreference:qos];
}

- (void)onSelectResolutionModelIndex:(NSInteger)index {
    TRTCVideoResolutionMode mode = index == 0 ? TRTCVideoResolutionModeLandscape : TRTCVideoResolutionModePortrait;
    [self.trtcCloudManager setResolutionMode:mode];
}

- (void)onSelectFillModeIndex:(NSInteger)index {
    TRTCVideoFillMode mode = index == 0 ? TRTCVideoFillMode_Fill : TRTCVideoFillMode_Fit;
    [self.trtcCloudManager setVideoFillMode:mode];
}

- (void)onSelectLocalMirrorIndex:(NSInteger)index {
    [self.trtcCloudManager setLocalMirror:index];
}

- (void)onEnableRemoteMirror:(BOOL)isOn {
    [self.trtcCloudManager setEncodeMirrorEnable:isOn];
}

- (void)onEnableWatermark:(BOOL)isOn {
    if (isOn) {
        UIImage *image = [UIImage imageNamed:@"watermark"];
        [self.trtcCloudManager setWaterMark:image inRect:CGRectMake(0.7, 0.1, 0.2, 0)];
    } else {
        [self.trtcCloudManager setWaterMark:nil inRect:CGRectZero];
    }
}

- (void)onPauseScreenCapture:(BOOL)isPaused {
    [self.trtcCloudManager setIsVideoPause:isPaused];
}

- (void)onEnableVideoMuteImage:(BOOL)isEnabled {
    [self.trtcCloudManager enableVideoMuteImage:isEnabled];
}

- (void)onEnableSharpnessEnhancement:(BOOL)isOn {
    [self.trtcCloudManager enableSharpnessEnhancement:isOn];
}

- (void)onEnableTimestampWaterMark:(BOOL)isOn {
    [self.trtcCloudManager enableTimestampWaterMark:isOn];
}

- (void)snapshotLocalVideo {
    __weak __typeof(self) wSelf = self;
    [self.trtcCloudManager snapshotLocalVideoWithUserId:nil type:TRTCVideoStreamTypeBig completionBlock:^(TXImage *image) {
        if (image) {
            [wSelf shareImage:image];
        } else {
            [self showText:TRTCLocalize(@"Demo.TRTC.Live.noImage")];
        }
    }];
}

- (void)shareImage:(UIImage *)image {
    UIActivityViewController *vc = [[UIActivityViewController alloc]
                                    initWithActivityItems:@[image]
                                    applicationActivities:nil];
    [self presentViewController:vc animated:YES completion:nil];
}


- (void)updateBitrateItemWithResolution:(TRTCVideoResolution)resolution {
    TRTCBitrateRange *range = [TRTCVideoConfig bitrateRangeOf:resolution
                                                        scene:TRTCAppSceneLIVE];
    self.bitrateItem.maxValue = range.maxBitrate;
    self.bitrateItem.minValue = range.minBitrate;
    self.bitrateItem.step = range.step;
    self.bitrateItem.sliderValue = range.defaultBitrate;

    [self.trtcCloudManager setVideoBitrate:(int)range.defaultBitrate];
    [self.tableView reloadData];
}

@end
