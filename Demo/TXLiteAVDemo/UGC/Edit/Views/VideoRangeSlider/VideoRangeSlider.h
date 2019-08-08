//
//  VideoRangeSlider.h
//  SAVideoRangeSliderExample
//
//  Created by annidyfeng on 2017/4/18.
//  Copyright © 2017年 Andrei Solovjev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RangeContent.h"

/**
 视频缩略条拉条
 */
@interface VideoColorInfo : NSObject
@property (nonatomic,strong) UIView *colorView;
@property (nonatomic,assign) CGFloat startPos;
@property (nonatomic,assign) CGFloat endPos;
@end

@protocol VideoRangeSliderDelegate;

@interface VideoRangeSlider : UIView

@property (weak) id<VideoRangeSliderDelegate> delegate;

@property (nonatomic) UIScrollView  *bgScrollView;
@property (nonatomic) UIView   *middleLine;
@property (nonatomic) RangeContentConfig* appearanceConfig;
@property (nonatomic) RangeContent *rangeContent;
@property (nonatomic) CGFloat        durationMs;
@property (nonatomic) float          fps;
@property (nonatomic) CGFloat        currentPos;
@property (readonly)  CGFloat        leftPos;
@property (readonly)  CGFloat        rightPos;
@property (readonly)  CGFloat        centerPos;
@property (nonatomic,readonly) NSUInteger coloredCount;

- (void)setImageList:(NSArray *)images;
- (void)updateImage:(UIImage *)image atIndex:(NSUInteger)index;

//中心滑块
- (void)setCenterPanHidden:(BOOL)isHidden;
- (void)setCenterPanFrame:(CGFloat)time;

//涂色
- (void)startColoration:(UIColor *)color alpha:(CGFloat)alpha;
- (void)stopColoration;
/// 删除最后一个被染色的块
/// @return 被删除的染色信息
- (VideoColorInfo *)removeLastColoration;
@end


@protocol VideoRangeSliderDelegate <NSObject>
- (void)onVideoRangeLeftChanged:(VideoRangeSlider *)sender;
- (void)onVideoRangeLeftChangeEnded:(VideoRangeSlider *)sender;
- (void)onVideoRangeCenterChanged:(VideoRangeSlider *)sender;
- (void)onVideoRangeCenterChangeEnded:(VideoRangeSlider *)sender;
- (void)onVideoRangeRightChanged:(VideoRangeSlider *)sender;
- (void)onVideoRangeRightChangeEnded:(VideoRangeSlider *)sender;
- (void)onVideoRangeLeftAndRightChanged:(VideoRangeSlider *)sender;
- (void)onVideoRange:(VideoRangeSlider *)sender seekToPos:(CGFloat)pos;
@end
