//
//  VideoTextFiled.h
//  DeviceManageIOSApp
//
//  Created by rushanting on 2017/5/22.
//  Copyright © 2017年 tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
@class VideoPasterView;


@protocol VideoPasterViewDelegate <NSObject>
- (void)onPasterViewTap:(VideoPasterView *)pasterView;
- (void)onRemovePasterView:(VideoPasterView*)pasterView;
@end

@interface VideoPasterView : UIView

@property (nonatomic, weak) id<VideoPasterViewDelegate> delegate;
@property (nonatomic, strong)    UIImageView *pasterImageView;
@property (nonatomic, assign)    CGFloat   rotateAngle;
@property (nonatomic, assign)    UIImage*  staticImage;

- (void)setImageList:(NSArray *)imageList imageDuration:(float)duration;

- (CGRect)pasterFrameOnView:(UIView*)view;

@end

