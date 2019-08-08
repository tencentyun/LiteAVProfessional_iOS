//
//  FilterSettingView.h
//  DeviceManageIOSApp
//
//  Created by rushanting on 2017/5/11.
//  Copyright © 2017年 tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 视频编辑滤镜view
 */

@protocol FilterSettingViewDelegate <NSObject>

- (void)onSetFilterWithImage:(UIImage*)image;
- (void)onSetBeautyDepth:(float)beautyDepth WhiteningDepth:(float)whiteningDepth;

@end

@interface FilterSettingView : UIView

@property (nonatomic, weak) id<FilterSettingViewDelegate> delegate;



@end
