//
//  VideoCutView.h
//  DeviceManageIOSApp
//
//  Created by rushanting on 2017/5/11.
//  Copyright © 2017年 tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "VideoRangeSlider.h"

/**
 视频编辑的裁剪view
 */

@protocol VideoCutViewDelegate <NSObject>

- (void)onVideoLeftCutChanged:(VideoRangeSlider*)sender;
- (void)onVideoRightCutChanged:(VideoRangeSlider*)sender;
- (void)onVideoCenterRepeatChanged:(VideoRangeSlider*)sender;

- (void)onVideoCutChangedEnd:(VideoRangeSlider*)sender;
- (void)onVideoCutChange:(VideoRangeSlider*)sender seekToPos:(CGFloat)pos;
- (void)onVideoCenterRepeatEnd:(VideoRangeSlider*)sender;

- (void)onEffectDelete:(VideoColorInfo *)info;
@end

@interface VideoCutView : UIView

@property (nonatomic, strong)  VideoRangeSlider *videoRangeSlider;  //缩略图条
@property (nonatomic, weak) id<VideoCutViewDelegate> delegate;
@property (nonatomic, strong)  NSMutableArray  *imageList;         //缩略图列表
@property (nonatomic, readonly) NSUInteger  coloredCount; // 染色的个数

- (id)initWithFrame:(CGRect)frame videoPath:(NSString *)videoPath  orVideoAsset:(AVAsset *)videoAsset;
- (id)initWithFrame:(CGRect)frame pictureList:(NSArray *)pictureList  duration:(CGFloat)duration fps:(float)fps;
- (void)updateFrame:(CGFloat)duration;

- (void)stopGetImageList;

- (void)setPlayTime:(CGFloat)time;
- (void)setCenterPanHidden:(BOOL)isHidden;
- (void)setCenterPanFrame:(CGFloat)time;
- (void)setEffectDeleteBtnHidden:(BOOL)isHidden;

- (void)startColoration:(UIColor *)color alpha:(CGFloat)alpha;
- (void)stopColoration;
- (void)removeLastColoration;
@end
