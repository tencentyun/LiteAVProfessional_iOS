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

#import "AppLocalized.h"
#import "MBProgressHUD.h"
#import "TCUtil.h"
#import "TRTCVideoConfig.h"

@interface TRTCVideoSettingsViewController ()

@property(strong, nonatomic) TRTCSettingsSliderItem *  bitrateItem;
@property(strong, nonatomic) TRTCSettingsSliderItem *  subStreamBitrateItem;
@property(strong, nonatomic) TRTCSettingsSegmentItem * localRotation;
@property(strong, nonatomic) TRTCSettingsSegmentItem * encodeRotation;
@property(strong, nonatomic) TRTCSettingsSelectorItem *acquisitionResolution;
@property(strong, nonatomic) TRTCSettingsSelectorItem *mainResolution;
@property(strong, nonatomic) TRTCSettingsSelectorItem *subResolution;
@property(strong, nonatomic) TRTCSettingsSelectorItem *mainSetFps;
@property(strong, nonatomic) TRTCSettingsSelectorItem *subSetFps;
@property(strong, nonatomic) TRTCSettingsSegmentItem * picPreferen;
@property(strong, nonatomic) TRTCSettingsSegmentItem * pictureDir;
@property(strong, nonatomic) TRTCSettingsSegmentItem * fillMode;
@property(strong, nonatomic) TRTCSettingsSegmentItem * preMirror;
@property(strong, nonatomic) TRTCSettingsSwitchItem *  remoteMirror;
@property(strong, nonatomic) TRTCSettingsSwitchItem *  enableWaterMark;
@property(strong, nonatomic) TRTCSettingsSwitchItem *  pauseScreenCapture;
@property(strong, nonatomic) TRTCSettingsSwitchItem *  sharpnessEnhancement;
@property(strong, nonatomic) TRTCSettingsSwitchItem *  videoMuteImage;
@property(strong, nonatomic) TRTCSettingsSwitchItem *  videoTimestampWaterMark;
@property(strong, nonatomic) TRTCSettingsButtonItem *  localVideoSnapshot;
@property(strong, nonatomic) TRTCSettingsSwitchItem *  hardcoding265;
@property(strong, nonatomic) TRTCSettingsSwitchItem *  videoCapture;
@property(strong, nonatomic) TRTCSettingsSwitchItem *  pushVideo;
@property(strong, nonatomic) TRTCSettingsSwitchItem *  blackNal;
@property(strong, nonatomic) TRTCSettingsSegmentItem * blackNalSizeItem;
@property(strong, nonatomic) TRTCSettingsSegmentItem * localMirror;
@property(strong, nonatomic) TRTCSettingsSegmentItem * beautyItem;
@property(strong, nonatomic) TRTCSettingsSliderItem *  brightness;

@property(assign, nonatomic) CGSize blackNalSize;

@end

@implementation TRTCVideoSettingsViewController

- (NSString *)title {
    return TRTCLocalize(@"Demo.TRTC.Live.video");
}

- (void)viewDidLoad {
    [super viewDidLoad];

    TRTCVideoConfig *     config = self.trtcCloudManager.videoConfig;
    __weak __typeof(self) wSelf  = self;

    self.bitrateItem = [[TRTCSettingsSliderItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.setBitrate")
                                                               value:0
                                                                 min:0
                                                                 max:0
                                                                step:0
                                                          continuous:YES
                                                              action:^(float bitrate) {
                                                                  [wSelf onSetBitrate:bitrate];
                                                              }];

    self.subStreamBitrateItem = [[TRTCSettingsSliderItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Meeting.substreamBitrate")
                                                                        value:0
                                                                          min:0
                                                                          max:0
                                                                         step:0
                                                                   continuous:NO
                                                                       action:^(float bitrate) {
                                                                           [wSelf onSetSubStreamBitrate:bitrate];
                                                                       }];

    self.localRotation = [[TRTCSettingsSegmentItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.previewRotation")
                                                                  items:@[ @"0", @"90", @"180", @"270" ]
                                                          selectedIndex:0
                                                                 action:^(NSInteger index) {
                                                                     [wSelf onSelectLocalRotation:index];
                                                                 }];

    self.encodeRotation = [[TRTCSettingsSegmentItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.encodeRotation")
                                                                   items:@[ @"0", @"90", @"180", @"270" ]
                                                           selectedIndex:0
                                                                  action:^(NSInteger index) {
                                                                      [wSelf onSelectEncodeRotation:index];
                                                                  }];

    self.mainResolution = [[TRTCSettingsSelectorItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.setResolution")
                                                                    items:TRTCVideoConfig.resolutionNames
                                                            selectedIndex:config.resolutionIndex
                                                                   action:^(NSInteger index) {
                                                                       [wSelf onSelectResolutionIndex:index];
                                                                   }];

    self.mainSetFps              = [[TRTCSettingsSelectorItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.setFps")
                                                                items:TRTCVideoConfig.fpsList
                                                        selectedIndex:config.fpsIndex
                                                               action:^(NSInteger index) {
                                                                   [wSelf onSelectFpsIndex:index];
                                                               }];
    self.picPreferen             = [[TRTCSettingsSegmentItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.setPicPreferen")
                                                                items:@[ TRTCLocalize(@"Demo.TRTC.Live.priorFlow"), TRTCLocalize(@"Demo.TRTC.Live.priorClear") ]
                                                        selectedIndex:config.qosPreferenceIndex
                                                               action:^(NSInteger index) {
                                                                   [wSelf onSelectQosPreferenceIndex:index];
                                                               }];
    self.pictureDir              = [[TRTCSettingsSegmentItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.pictureDir")
                                                               items:@[ TRTCLocalize(@"Demo.TRTC.Live.horMode"), TRTCLocalize(@"Demo.TRTC.Live.verMode") ]
                                                       selectedIndex:config.videoEncConfig.resMode
                                                              action:^(NSInteger index) {
                                                                  [wSelf onSelectResolutionModelIndex:index];
                                                              }];
    self.fillMode                = [[TRTCSettingsSegmentItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.fillMode")
                                                             items:@[ TRTCLocalize(@"Demo.TRTC.Live.fill"), TRTCLocalize(@"Demo.TRTC.Live.fit") ]
                                                     selectedIndex:config.localRenderParams.fillMode
                                                            action:^(NSInteger index) {
                                                                [wSelf onSelectFillModeIndex:index];
                                                            }];
    self.preMirror               = [[TRTCSettingsSegmentItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.preMirror")
                                                              items:@[
                                                                  TRTCLocalize(@"Demo.TRTC.Live.autoMirror"),
                                                                  TRTCLocalize(@"Demo.TRTC.Live.enableMirror"),
                                                                  TRTCLocalize(@"Demo.TRTC.Live.disableMirror"),
                                                              ]
                                                      selectedIndex:0
                                                             action:^(NSInteger index) {
                                                                 [wSelf onSelectLocalMirrorIndex:index];
                                                             }];
    self.remoteMirror            = [[TRTCSettingsSwitchItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.remoteMirror")
                                                                 isOn:config.isRemoteMirrorEnabled
                                                               action:^(BOOL isOn) {
                                                                   [wSelf onEnableRemoteMirror:isOn];
                                                               }];
    self.enableWaterMark         = [[TRTCSettingsSwitchItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.enableWaterMark")
                                                                    isOn:config.isWaterMarkEnabled
                                                                  action:^(BOOL isOn) {
                                                                      [wSelf onEnableWatermark:isOn];
                                                                  }];
    self.pauseScreenCapture            = [[TRTCSettingsSwitchItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.pauseScreenCapture")
                                                                 isOn:config.isScreenCapturePaused
                                                               action:^(BOOL isOn) {
                                                                   [wSelf onPauseScreenCapture:isOn];
                                                               }];
    self.sharpnessEnhancement    = [[TRTCSettingsSwitchItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.sharpnessEnhancement")
                                                                         isOn:config.isSharpnessEnhancementEnabled
                                                                       action:^(BOOL isOn) {
                                                                           [wSelf onEnableSharpnessEnhancement:isOn];
                                                                       }];
    self.videoMuteImage          = [[TRTCSettingsSwitchItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.videoMuteImage")
                                                                   isOn:config.isVideoMuteImage
                                                                 action:^(BOOL isOn) {
                                                                     [wSelf onEnableVideoMuteImage:isOn];
                                                                 }];
    self.videoTimestampWaterMark = [[TRTCSettingsSwitchItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.videoTimestampWaterMark")
                                                                            isOn:config.isTimestampWaterMark
                                                                          action:^(BOOL isOn) {
                                                                              [wSelf onEnableTimestampWaterMark:isOn];
                                                                          }];
    self.localVideoSnapshot = [[TRTCSettingsSelectorItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.localVideoSnapshot") items:@[TRTCLocalize(@"Demo.TRTC.Live.streamSnapshot"), TRTCLocalize(@"Demo.TRTC.Live.snapshot")] selectedIndex:0 action:^(NSInteger index) {
        [wSelf snapshotLocalVideo:index];
    }];
    
    self.acquisitionResolution   = [[TRTCSettingsSelectorItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.collectSolution")
                                                                           items:TRTCVideoConfig.captureResolutionNames
                                                                   selectedIndex:config.captureResolutionIndex
                                                                          action:^(NSInteger index) {
                                                                              [wSelf onSelectCaptureResolutionIndex:index];
                                                                          }];

    self.subResolution = [[TRTCSettingsSelectorItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.subResolution")
                                                                   items:TRTCVideoConfig.resolutionNames
                                                           selectedIndex:config.subStreamResolutionIndex
                                                                  action:^(NSInteger index) {
                                                                      [wSelf onSelectSubStreamResolutionIndex:index];
                                                                  }];
    self.subSetFps     = [[TRTCSettingsSelectorItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Meeting.subFramerate")
                                                               items:TRTCVideoConfig.fpsList
                                                       selectedIndex:config.subStreamFpsIndex
                                                              action:^(NSInteger index) {
                                                                  [wSelf onSelectSubStreamFpsIndex:index];
                                                              }];
    self.hardcoding265 = [[TRTCSettingsSwitchItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Meeting.265HardCoding")
                                                                  isOn:config.isH265Enabled
                                                                action:^(BOOL isOn) {
                                                                    [wSelf onEnableHEVCEncode:isOn];
                                                                }];

    self.videoCapture     = [[TRTCSettingsSwitchItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.turnOnCapture")
                                                                 isOn:config.isEnabled
                                                               action:^(BOOL isOn) {
                                                                   [wSelf onEnableVideo:isOn];
                                                               }];
    self.pushVideo        = [[TRTCSettingsSwitchItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.turnOnPush")
                                                              isOn:!config.isMuted
                                                            action:^(BOOL isOn) {
                                                                [wSelf onMuteVideo:!isOn];
                                                            }];
    self.blackNal         = [[TRTCSettingsSwitchItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.turnOnBlackFrame")
                                                             isOn:NO
                                                           action:^(BOOL isOn) {
                                                               [wSelf onEnableBlackNal:isOn];
                                                           }];
    self.blackNalSizeItem = [[TRTCSettingsSegmentItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.blackFrameRatio")
                                                                     items:@[ @"默认64*64", @"竖屏16比9" ]
                                                             selectedIndex:0
                                                                    action:^(NSInteger index) {
                                                                        [wSelf onBlackNalSizeIndex:index];
                                                                    }];
    self.localMirror      = [[TRTCSettingsSegmentItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.previewMirror")
                                                                items:TRTCVideoConfig.localMirrorTypeNames
                                                        selectedIndex:config.localRenderParams.mirrorType
                                                               action:^(NSInteger index) {
                                                                   [wSelf onSelectLocalMirror:index];
                                                               }];

    self.beautyItem = [[TRTCSettingsSegmentItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.beauty")
                                                               items:TRTCVideoConfig.formatNames
                                                       selectedIndex:config.formatIndex
                                                              action:^(NSInteger index) {
                                                                  [wSelf onUpdatePreprocessFormatIndex:index];
                                                              }];

    self.brightness = [[TRTCSettingsSliderItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.brightness")
                                                              value:config.brightness
                                                                min:-1
                                                                max:1
                                                               step:0.1
                                                         continuous:YES
                                                             action:^(float brightness) {
                                                                 [wSelf onUpdateBrightness:brightness];
                                                             }];

    if (DEBUGSwitch) {
        [self.items addObject:self.brightness];
        self.items = [@[
            self.acquisitionResolution,
            self.mainResolution,
            self.subResolution,
            self.mainSetFps,
            self.subSetFps,
            self.bitrateItem,
            self.subStreamBitrateItem,
            self.picPreferen,
            self.pictureDir,
            self.fillMode,
            self.hardcoding265,
            self.videoCapture,
            self.pushVideo,
            self.pauseScreenCapture,
            self.videoMuteImage,
            self.blackNal,
            self.blackNalSizeItem,
            self.localMirror,
            self.remoteMirror,
            self.enableWaterMark,
            self.videoTimestampWaterMark,
            self.sharpnessEnhancement,
            self.beautyItem,
            self.brightness,
            self.localRotation,
            self.encodeRotation,
            self.localVideoSnapshot,
        ] mutableCopy];

    } else {
        self.items = [@[
            self.mainResolution,
            self.mainSetFps,
            self.bitrateItem,
            self.picPreferen,
            self.pictureDir,
            self.fillMode,
            self.localRotation,
            self.encodeRotation,
            self.localMirror,
            self.remoteMirror,
            self.enableWaterMark,
            self.pauseScreenCapture,
            self.sharpnessEnhancement,
            self.localVideoSnapshot,
        ] mutableCopy];
    }

    [self updateBitrateItemWithResolution:config.videoEncConfig.videoResolution];
}

- (void)viewWillAppear:(BOOL)animated {
    if (self.trtcCloudManager.gSensorEnabled) {
        self.localRotation.selectedIndex  = 0;
        self.encodeRotation.selectedIndex = 0;
    }
    [self.tableView reloadData];
}

- (void)showText:(NSString *)text {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode           = MBProgressHUDModeText;
    hud.label.text     = text;
    [hud showAnimated:YES];
    [hud hideAnimated:YES afterDelay:1];
}

#pragma mark - Actions
- (void)onEnableVideo:(BOOL)isOn {
    [self.trtcCloudManager setVideoEnabled:isOn];
}
- (void)onEnableHEVCEncode:(BOOL)isOn {
    [self.trtcCloudManager enableHEVCEncode:isOn];
}
- (void)onSelectResolutionIndex:(NSInteger)index {
    TRTCVideoResolution resolution = [TRTCVideoConfig.resolutions[index] integerValue];
    [self.trtcCloudManager setResolution:resolution];
    [self updateBitrateItemWithResolution:resolution];
}

- (void)onSelectSubStreamFpsIndex:(NSInteger)index {
    [self.trtcCloudManager setSubStreamVideoFps:[TRTCVideoConfig.fpsList[index] intValue]];
}

- (void)onSelectSubStreamResolutionIndex:(NSInteger)index {
    TRTCVideoResolution resolution = [TRTCVideoConfig.resolutions[index] integerValue];
    [self.trtcCloudManager setSubStreamResolution:resolution];
    [self updateSubStreamBitrateItemWithResolution:resolution];
}

- (void)onSelectCaptureResolutionIndex:(NSInteger)index {
    [self.trtcCloudManager setCaptureResolution:index];
}

- (void)onSetSubStreamBitrate:(float)bitrate {
    [self.trtcCloudManager setSubStreamVideoBitrate:bitrate];
}

- (void)onMuteVideo:(BOOL)isMuted {
    NSString *mainRoomId = self.trtcCloudManager.params.roomId ? [@(self.trtcCloudManager.params.roomId) stringValue] : self.trtcCloudManager.params.strRoomId;
    if ([self.trtcCloudManager.currentPublishingRoomId isEqualToString:mainRoomId]) {
        //若当前在主房间中推流，则调用TRTCCloud切换视频上行
        [self.trtcCloudManager setVideoMuted:isMuted];
    } else {
        //否则找到对应的TRTCSubCloud切换上行
        [self.trtcCloudManager pushVideoStreamInSubRoom:self.trtcCloudManager.currentPublishingRoomId push:!isMuted];
    }
}

- (void)onEnableBlackNal:(BOOL)isEnable {
    [self.trtcCloudManager enableBlackStream:isEnable size:self.blackNalSize];
}

- (BOOL)isSupportEncodeH265 {
    if (@available(iOS 11.0, macOS 10.13, *)) {
        static BOOL            isSupported = NO;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            isSupported = [[AVAssetExportSession allExportPresets] containsObject:AVAssetExportPresetHEVCHighestQuality];
        });
        return isSupported;
    }
    return NO;
}

- (void)onSelectLocalMirror:(NSInteger)index {
    [self.trtcCloudManager setLocalMirrorType:index];
}

- (void)onUpdateBrightness:(CGFloat)brightness {
    [self.trtcCloudManager setCustomBrightness:brightness];
}

- (void)onBlackNalSizeIndex:(NSInteger)index {
    self.blackNalSize = index == 0 ? CGSizeZero : CGSizeMake(90, 160);
}

- (void)onUpdatePreprocessFormatIndex:(NSInteger)index {
    TRTCVideoPixelFormat format = [TRTCVideoConfig.formats[index] integerValue];
    [self.trtcCloudManager setCustomProcessFormat:format];
}

- (BOOL)isSupportDecodeH265 {
#if defined(__MAC_10_13) || defined(__IPHONE_11_0)
    if (@available(iOS 11.0, macOS 10.13, *)) {
        return YES;
    }
#endif
    return NO;
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
    [self.trtcCloudManager pauseScreenCapture:isPaused];
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

- (void)snapshotLocalVideo:(NSInteger)index {
    __weak __typeof(self) wSelf = self;
    [self.trtcCloudManager.trtcCloud snapshotVideo:nil
                                        type:TRTCVideoStreamTypeBig
                                   sourceType:(TRTCSnapshotSourceType)index
                             completionBlock:^(TXImage *image) {
        if (image && [image isKindOfClass:[TXImage class]]) {
            UIImage *activityImage = image.shareActivityImage;
            if (activityImage) {
                [wSelf shareImage:activityImage];
                return;
            }
        }
        [self showText:TRTCLocalize(@"Demo.TRTC.Live.noImage")];
    }];
}

- (void)shareImage:(UIImage *)image {
    UIActivityViewController *vc = [[UIActivityViewController alloc] initWithActivityItems:@[ image ] applicationActivities:nil];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)updateBitrateItemWithResolution:(TRTCVideoResolution)resolution {
    TRTCBitrateRange *range      = [TRTCVideoConfig bitrateRangeOf:resolution scene:self.trtcCloudManager.scene];
    self.bitrateItem.maxValue    = range.maxBitrate;
    self.bitrateItem.minValue    = range.minBitrate;
    self.bitrateItem.step        = range.step;
    self.bitrateItem.sliderValue = range.defaultBitrate;

    [self.trtcCloudManager setVideoBitrate:(int)range.defaultBitrate];
    [self.tableView reloadData];
}

- (void)updateSubStreamBitrateItemWithResolution:(TRTCVideoResolution)resolution {
    TRTCBitrateRange *range               = [TRTCVideoConfig bitrateRangeOf:resolution scene:self.trtcCloudManager.scene];
    self.subStreamBitrateItem.maxValue    = range.maxBitrate;
    self.subStreamBitrateItem.minValue    = range.minBitrate;
    self.subStreamBitrateItem.step        = range.step;
    self.subStreamBitrateItem.sliderValue = range.defaultBitrate;

    [self.trtcCloudManager setSubStreamVideoBitrate:(int)range.defaultBitrate];
    [self.tableView reloadData];
}

@end
