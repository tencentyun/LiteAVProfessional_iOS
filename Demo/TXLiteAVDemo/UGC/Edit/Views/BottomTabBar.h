//
//  BottomTabBar.h
//  DeviceManageIOSApp
//
//  Created by rushanting on 2017/5/11.
//  Copyright © 2017年 tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 视频编辑底栏
 */

@protocol BottomTabBarDelegate <NSObject>

- (void)onCutBtnClicked;
- (void)onTimeBtnClicked;
- (void)onFilterBtnClicked;
- (void)onMusicBtnClicked;
- (void)onEffectBtnClicked;
- (void)onTextBtnClicked;
- (void)onPasterBtnClicked;

@end

@interface BottomTabBar : UIView

@property (nonatomic, weak) id<BottomTabBarDelegate> delegate;

@end
