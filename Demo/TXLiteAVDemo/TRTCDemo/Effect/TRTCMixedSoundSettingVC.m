//
//  TRTCMixedSoundSettingVC.m
//  TXLiteAVDemo
//
//  Created by origin 李 on 2021/12/23.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "AppLocalized.h"
#import "ColorMacro.h"
#import "TCUtil.h"
#import "TRTCCloud.h"
#import "TRTCEffectManager.h"
#import "TRTCMixedSoundSettingVC.h"
#import "TRTCSettingsEffectMixedSoundCell.h"
#import "TRTCSettingsSliderCell.h"
#import "TRTCSettingsSwitchCell.h"

@interface TRTCMixedSoundSettingVC ()
@property(strong, nonatomic) TRTCCloud *trtcCloud;
@property(strong, nonatomic) TRTCSettingsEffectMixedSoundItem *mixedSoundItem;
@property(strong, nonatomic) TRTCSettingsSwitchItem *localPlayItem;
@property(strong, nonatomic) TRTCSettingsSwitchItem *remotePlayItem;
@property(strong, nonatomic) TRTCSettingsSliderItem *localvolume;
@property(strong, nonatomic) TRTCSettingsSliderItem *remotevolume;

@end

@implementation TRTCMixedSoundSettingVC
- (instancetype)initWithTRTCCloud:(TRTCCloud *)trtcCloud {
  if (self = [super init]) {
    self.trtcCloud = trtcCloud;
  }
  return self;
}

- (void)makeCustomRegistrition {
  [self.tableView registerClass:TRTCSettingsEffectMixedSoundItem.bindedCellClass
         forCellReuseIdentifier:TRTCSettingsEffectMixedSoundItem.bindedCellId];
  [self.tableView registerClass:TRTCSettingsSwitchItem.bindedCellClass
         forCellReuseIdentifier:TRTCSettingsSwitchItem.bindedCellId];
  [self.tableView registerClass:TRTCSettingsSliderItem.bindedCellClass
         forCellReuseIdentifier:TRTCSettingsSliderItem.bindedCellId];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.enablePublish = YES;
  self.enablePlayout = YES;
  self.publishVolume = 50;
  self.playoutVolume = 50;
  self.view.backgroundColor = UIColorFromRGB(0x13233F);
  @weakify(self) self.mixedSoundItem =
      [[TRTCSettingsEffectMixedSoundItem alloc] initWithTRTCCloud:self.trtcCloud
                                                       playAction:^{

                                                       }];
  self.mixedSoundItem.title = TRTCLocalize(@"Demo.TRTC.audio.externalMix");
  self.mixedSoundItem.settingPage = self;

  self.localPlayItem = [[TRTCSettingsSwitchItem alloc]
      initWithTitle:TRTCLocalize(@"Demo.TRTC.audio.localPlay")
               isOn:YES
             action:^(BOOL isOn) {
               @strongify(self)
               self.enablePlayout = isOn;
               [self.trtcCloud enableMixExternalAudioFrame:self.enablePublish
                                                   playout:self.enablePlayout];
             }];

  self.remotePlayItem = [[TRTCSettingsSwitchItem alloc]
      initWithTitle:TRTCLocalize(@"Demo.TRTC.audio.remotePlay")
               isOn:YES
             action:^(BOOL isOn) {
               @strongify(self)
               self.enablePublish = isOn;
               [self.trtcCloud enableMixExternalAudioFrame:self.enablePublish
                                                   playout:self.enablePlayout];
             }];

  self.localvolume = [[TRTCSettingsSliderItem alloc]
      initWithTitle:TRTCLocalize(@"Demo.TRTC.audio.localVolume")
              value:50
                min:0
                max:100
               step:1
         continuous:YES
             action:^(float bitrate) {
               @strongify(self)
               self.playoutVolume = bitrate;
               [self.trtcCloud setMixExternalAudioVolume:self.publishVolume
                                           playoutVolume:self.playoutVolume];
             }];

  self.remotevolume = [[TRTCSettingsSliderItem alloc]
      initWithTitle:TRTCLocalize(@"Demo.TRTC.audio.remoteVolume")
              value:50
                min:0
                max:100
               step:1
         continuous:YES
             action:^(float bitrate) {
               @strongify(self)
               self.publishVolume = bitrate;
               [self.trtcCloud setMixExternalAudioVolume:self.publishVolume
                                           playoutVolume:self.playoutVolume];
             }];
  self.items = [[NSMutableArray alloc] initWithCapacity:4];
  [self.items addObject:self.mixedSoundItem];
  [self.items addObject:self.localPlayItem];
  [self.items addObject:self.remotePlayItem];
  [self.items addObject:self.localvolume];
  [self.items addObject:self.remotevolume];
}

@end

