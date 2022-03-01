//
//  TRTCCdnPlayerSettingsViewController.m
//  TXLiteAVDemo
//
//  Created by origin 李 on 2021/8/19.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "AppLocalized.h"
#import "TRTCCdnPlayerSettingsViewController.h"
@interface TRTCCdnPlayerSettingsViewController ()

@end

@implementation TRTCCdnPlayerSettingsViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  [self setupBackgroudColor];
  self.title = TRTCLocalize(@"Demo.TRTC.Live.CDNSetting");

  TRTCCdnPlayerConfig *config = self.manager.config;
  __weak __typeof(self) wSelf = self;

  self.items = [@[
    [[TRTCSettingsSegmentItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.LiveRotation")
                                             items:@[ @"0", @"90", @"180", @"270" ]
                                     selectedIndex:[self indexOfOrientation:config.orientation]
                                            action:^(NSInteger index) {
                                              [wSelf onSelectRotationIndex:index];
                                            }],
    [[TRTCSettingsSegmentItem alloc]
        initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.fillMode")
                items:@[ TRTCLocalize(@"Demo.TRTC.Live.fill"), TRTCLocalize(@"Demo.TRTC.Live.fit") ]
        selectedIndex:config.renderMode
               action:^(NSInteger index) {
                 [wSelf onSelectRenderModeIndex:index];
               }],
    [[TRTCSettingsSegmentItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.bufferMode")
                                             items:@[
                                               TRTCLocalize(@"Demo.TRTC.Live.bModeFast"),
                                               TRTCLocalize(@"Demo.TRTC.Live.bModeSmooth"),
                                               TRTCLocalize(@"Demo.TRTC.Live.bModeAuto")
                                             ]
                                     selectedIndex:config.cacheType
                                            action:^(NSInteger index) {
                                              [wSelf onSelectCacheTypeIndex:index];
                                            }]
  ] mutableCopy];
}

#pragma mark - Action

- (void)onSelectRotationIndex:(NSInteger)index {
  [self.manager setOrientation:[self orientationOfIndex:index]];
}

- (void)onSelectRenderModeIndex:(NSInteger)index {
  [self.manager setRenderMode:index];
}

- (void)onSelectCacheTypeIndex:(NSInteger)index {
  [self.manager setCacheType:index];
}

#pragma mark - Private

- (NSInteger)indexOfOrientation:(TX_Enum_Type_HomeOrientation)orientation {
  switch (orientation) {
    case HOME_ORIENTATION_DOWN:
      return 0;
    case HOME_ORIENTATION_RIGHT:
      return 1;
    case HOME_ORIENTATION_UP:
      return 2;
    case HOME_ORIENTATION_LEFT:
      return 3;
  }
}

- (TX_Enum_Type_HomeOrientation)orientationOfIndex:(NSInteger)index {
  NSArray *orientations = @[
    @(HOME_ORIENTATION_DOWN), @(HOME_ORIENTATION_RIGHT), @(HOME_ORIENTATION_UP),
    @(HOME_ORIENTATION_LEFT)
  ];
  return [orientations[index] integerValue];
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

@end

