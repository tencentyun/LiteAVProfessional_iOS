//
//  TRTCEffectSettingContainerVC.m
//  TXLiteAVDemo
//
//  Created by origin 李 on 2021/12/23.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "TRTCEffectSettingContainerVC.h"
#import "TRTCEffectSettingsViewController.h"
#import "TRTCEffectManager.h"
#import "TRTCCloud.h"
#import "ColorMacro.h"
#import "TRTCMixedSoundSettingVC.h"
#import "AppLocalized.h"

@interface TRTCEffectSettingContainerVC ()
@property(strong, nonatomic) TRTCEffectSettingsViewController *audioEffectSettingVC;
@property(strong, nonatomic) TRTCMixedSoundSettingVC *mixedSoundSettingVC;
@end

@implementation TRTCEffectSettingContainerVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.scrollEnable = NO;
    self.titleColorSelected = [UIColor whiteColor];
    self.titleColorNormal = [UIColor whiteColor];
    self.menuViewStyle = WMMenuViewStyleLine;
    self.menuViewLayoutMode = WMMenuViewLayoutModeScatter;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numbersOfChildControllersInPageController:(WMPageController *)pageController {
    return 2;
}

- (NSString *)pageController:(WMPageController *)pageController titleAtIndex:(NSInteger)index {
    switch (index % 2) {
        case 0: return TRTCLocalize(@"Demo.TRTC.audio.soundeffect") ;
        case 1: return TRTCLocalize(@"Demo.TRTC.audio.externalMix");
    }
    return @"NONE";
}

- (UIViewController *)pageController:(WMPageController *)pageController viewControllerAtIndex:(NSInteger)index {
    switch (index % 2) {
        case 0: return self.audioEffectSettingVC;
        case 1: return self.mixedSoundSettingVC;
    }
    return [[UIViewController alloc] init];
}

- (CGFloat)menuView:(WMMenuView *)menu widthForItemAtIndex:(NSInteger)index {
    CGFloat width = [super menuView:menu widthForItemAtIndex:index];
    return width + 20;
}

- (CGRect)pageController:(WMPageController *)pageController preferredFrameForMenuView:(WMMenuView *)menuView {
    menuView.backgroundColor =  UIColorFromRGB(0x13233F);
    CGFloat leftMargin = self.showOnNavigationBar ? 50 : 0;
    CGFloat originY = self.showOnNavigationBar ? 0 : CGRectGetMaxY(self.navigationController.navigationBar.frame);
    return CGRectMake(leftMargin, originY, self.view.frame.size.width - 2*leftMargin, 44);
}

- (CGRect)pageController:(WMPageController *)pageController preferredFrameForContentView:(WMScrollView *)contentView {
    CGFloat originY = CGRectGetMaxY([self pageController:pageController preferredFrameForMenuView:self.menuView]);
    return CGRectMake(0, originY, self.view.frame.size.width, self.view.frame.size.height - originY);
}



- (TRTCEffectSettingsViewController *)audioEffectSettingVC {
    if (!_audioEffectSettingVC) {
        _audioEffectSettingVC = [[TRTCEffectSettingsViewController alloc] initWithManager:[[TRTCEffectManager alloc] initWithTrtc:[TRTCCloud sharedInstance]]];
        _audioEffectSettingVC.modalPresentationStyle = UIModalPresentationPageSheet;
    }
    return _audioEffectSettingVC;
}

-(TRTCMixedSoundSettingVC *)mixedSoundSettingVC {
    if (!_mixedSoundSettingVC) {
        _mixedSoundSettingVC = [[TRTCMixedSoundSettingVC alloc] initWithTRTCCloud:[TRTCCloud sharedInstance]];
        _mixedSoundSettingVC.modalPresentationStyle = UIModalPresentationPageSheet;
    }
    return _mixedSoundSettingVC;
}
@end
