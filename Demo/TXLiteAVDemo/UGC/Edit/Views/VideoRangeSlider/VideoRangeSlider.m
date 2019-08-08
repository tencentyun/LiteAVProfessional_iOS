//
//  VideoRangeSlider.m
//  SAVideoRangeSliderExample
//
//  Created by annidyfeng on 2017/4/18.
//  Copyright © 2017年 Andrei Solovjev. All rights reserved.
//

#import "VideoRangeSlider.h"
#import "UIView+Additions.h"
#import "UIView+CustomAutoLayout.h"
#import "VideoRangeConst.h"

@implementation VideoColorInfo

@end

@interface VideoRangeSlider()<RangeContentDelegate, UIScrollViewDelegate>

@property BOOL disableSeek;

@end

@implementation VideoRangeSlider
{
    NSMutableArray <VideoColorInfo *> *_colorInfos;
    BOOL  _startColor;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/


- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    self.bgScrollView = ({
        UIScrollView *scroll = [[UIScrollView alloc] initWithFrame:CGRectZero];
        [self addSubview:scroll];
        scroll.showsVerticalScrollIndicator = NO;
        scroll.showsHorizontalScrollIndicator = NO;
        scroll.scrollsToTop = NO;
        scroll.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        scroll.delegate = self;
        scroll;
    });
    self.middleLine = ({
        UIView *result = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 2, CGRectGetHeight(frame))];
        result.backgroundColor = [UIColor whiteColor];
        [self addSubview:result];
        result;
    });
    
    _colorInfos = [NSMutableArray array];
    _startColor = NO;
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.bgScrollView.width = self.width;
    self.middleLine.center = self.bgScrollView.center = CGPointMake(self.width/2, self.height/2);
    self.middleLine.bounds = CGRectMake(0, self.bgScrollView.top-4, 2, self.bgScrollView.height + 8);
}


- (void)setAppearanceConfig:(RangeContentConfig *)appearanceConfig
{
    _appearanceConfig = appearanceConfig;
}

- (void)setImageList:(NSArray *)images
{
    if (self.rangeContent) {
        [self.rangeContent removeFromSuperview];
    }
    if (_appearanceConfig) {
        self.rangeContent = [[RangeContent alloc] initWithImageList:images config:_appearanceConfig];
    } else {
        self.rangeContent = [[RangeContent alloc] initWithImageList:images];
    }
    self.rangeContent.delegate = self;
    
    [self.bgScrollView addSubview:self.rangeContent];
    self.bgScrollView.contentSize = [self.rangeContent intrinsicContentSize];
    self.bgScrollView.height = self.bgScrollView.contentSize.height;
    self.bgScrollView.contentInset = UIEdgeInsetsMake(0, self.width/2-self.rangeContent.pinWidth,
                                                      0, self.width/2-self.rangeContent.pinWidth);
    
    [self setCurrentPos:0];
}

- (void)updateImage:(UIImage *)image atIndex:(NSUInteger)index;
{
    self.rangeContent.imageViewList[index].image = image;
}

- (void)setCenterPanHidden:(BOOL)isHidden
{
    self.rangeContent.centerPin.hidden = isHidden;
}

- (void)setCenterPanFrame:(CGFloat)time
{
    self.rangeContent.centerPinCenterX = time / _durationMs * self.rangeContent.width;
    self.rangeContent.centerPin.center = CGPointMake( self.rangeContent.centerPinCenterX, self.rangeContent.centerPin.center.y);
}

- (void)startColoration:(UIColor *)color alpha:(CGFloat)alpha
{
    VideoColorInfo *info = [[VideoColorInfo alloc] init];
    info.colorView = [UIView new];
    info.colorView.backgroundColor = color;
    info.colorView.alpha = alpha;
    info.colorView.userInteractionEnabled = NO;
    info.startPos = _currentPos;
    [_colorInfos addObject:info];
    
    [self.rangeContent insertSubview:info.colorView belowSubview:self.rangeContent.leftPin];
    _startColor = YES;
}

- (void)stopColoration
{
    VideoColorInfo *info = [_colorInfos lastObject];
    info.endPos = _currentPos;

    if (_currentPos + 1.5/ _fps >= _durationMs) {
        info.colorView.frame = [self coloredFrameForStartTime:info.startPos endTime:_durationMs];
        info.endPos = _durationMs;
    } else {
        info.endPos = _currentPos;
    }
    _startColor = NO;
}

- (NSUInteger)coloredCount
{
    return [_colorInfos count];
}

- (VideoColorInfo *)removeLastColoration
{
    VideoColorInfo *info = [_colorInfos lastObject];
    [info.colorView removeFromSuperview];
    [_colorInfos removeObject:info];
    return info;
}

- (CGRect)coloredFrameForStartTime:(float)start endTime:(float)end {
    CGFloat boxWidth = self.rangeContent.imageListWidth / _durationMs; // 帧的宽度
    return CGRectMake(self.rangeContent.pinWidth + start * boxWidth, 0, (end - start) * boxWidth, self.rangeContent.height);
}

- (void)setDurationMs:(CGFloat)durationMs {
    //duration 发生变化的时候，更新下特效所在的位置
    if (_durationMs != durationMs) {
        for (VideoColorInfo *info in _colorInfos) {
            CGFloat x = self.rangeContent.pinWidth + info.startPos * self.rangeContent.imageListWidth / durationMs;
            CGFloat width = fabs(info.endPos - info.startPos) * self.rangeContent.imageListWidth / durationMs;
            info.colorView.frame = CGRectMake(x, 0, width, self.height);
        }
        _durationMs = durationMs;
    }
    
    _leftPos = 0;
    _rightPos = _durationMs;
    [self setCurrentPos:_currentPos];
    
    _leftPos =  self.durationMs * self.rangeContent.leftScale;
    _centerPos = self.durationMs * self.rangeContent.centerScale;
    _rightPos = self.durationMs * self.rangeContent.rightScale;
}

- (void)setCurrentPos:(CGFloat)currentPos
{
    _currentPos = currentPos;
    if (_durationMs <= 0) {
        return;
    }
    
    CGFloat duration = _durationMs - 1/_fps;
    
    CGFloat off = currentPos * self.rangeContent.imageListWidth / duration;
    //    off += self.rangeContent.leftPin.width;
    off -= self.bgScrollView.contentInset.left;
    
    self.disableSeek = YES;
    self.bgScrollView.contentOffset = CGPointMake(off, 0);
    
    VideoColorInfo *info = [_colorInfos lastObject];
    if (_startColor) {
        CGRect frame;
        if (_currentPos > info.startPos) {
            frame = [self coloredFrameForStartTime:info.startPos endTime:_currentPos];
        }else{
            frame = [self coloredFrameForStartTime:_currentPos endTime:info.startPos];
        }
        info.colorView.frame = frame;
    }
    self.disableSeek = NO;
}

#pragma Delegate -
#pragma TXVideoRangeContentDelegate

- (void)onRangeLeftChanged:(RangeContent *)sender
{
    _leftPos  = self.durationMs * sender.leftScale;
    _rightPos = self.durationMs * sender.rightScale;
    
    [self.delegate onVideoRangeLeftChanged:self];
}

- (void)onRangeLeftChangeEnded:(RangeContent *)sender
{
    _leftPos  = self.durationMs * sender.leftScale;
    _rightPos = self.durationMs * sender.rightScale;
    
    [self.delegate onVideoRangeLeftChangeEnded:self];
    
}

- (void)onRangeCenterChanged:(RangeContent *)sender
{
    _leftPos  = self.durationMs * sender.leftScale;
    _rightPos = self.durationMs * sender.rightScale;
    _centerPos =  self.durationMs * sender.centerScale;
    
    [self.delegate onVideoRangeCenterChanged:self];
}

- (void)onRangeCenterChangeEnded:(RangeContent *)sender
{
    _leftPos  = self.durationMs * sender.leftScale;
    _rightPos = self.durationMs * sender.rightScale;
    _centerPos =  self.durationMs * sender.centerScale;
    
    [self.delegate onVideoRangeCenterChangeEnded:self];
}

- (void)onRangeRightChanged:(RangeContent *)sender
{
    _leftPos  = self.durationMs * sender.leftScale;
    _rightPos = self.durationMs * sender.rightScale;
    
    [self.delegate onVideoRangeRightChanged:self];
}

- (void)onRangeRightChangeEnded:(RangeContent *)sender
{
    _leftPos  = self.durationMs * sender.leftScale;
    _rightPos = self.durationMs * sender.rightScale;
    
    [self.delegate onVideoRangeRightChangeEnded:self];
}

- (void)onRangeLeftAndRightChanged:(RangeContent *)sender
{
    _leftPos  = self.durationMs * sender.leftScale;
    _rightPos = self.durationMs * sender.rightScale;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat pos = scrollView.contentOffset.x;
    pos += scrollView.contentInset.left;
    if (pos < 0) pos = 0;
    if (pos > self.rangeContent.imageListWidth) pos = self.rangeContent.imageListWidth;
    
    _currentPos = self.durationMs * pos/self.rangeContent.imageListWidth;
    if (self.disableSeek == NO) {
//        NSLog(@"seek %f", _currentPos);
        [self.delegate onVideoRange:self seekToPos:self.currentPos];
    }
}
@end
