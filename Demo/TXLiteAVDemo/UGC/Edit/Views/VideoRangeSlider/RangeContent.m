//
//  VideoRangeContent.m
//  SAVideoRangeSliderExample
//
//  Created by annidyfeng on 2017/4/18.
//  Copyright © 2017年 Andrei Solovjev. All rights reserved.
//

#import "RangeContent.h"
#import "UIView+Additions.h"
#import "VideoRangeConst.h"


@implementation RangeContentConfig
- (id)init
{
    if (self = [super init]) {
        _pinWidth = PIN_WIDTH;
        _thumbHeight = THUMB_HEIGHT;
        _borderHeight = BORDER_HEIGHT;
        _leftPinImage = [UIImage imageNamed:@"left" inBundle:nil compatibleWithTraitCollection:nil];
        _centerPinImage = [UIImage imageNamed:@"center" inBundle:nil compatibleWithTraitCollection:nil];
        _rightPigImage = [UIImage imageNamed:@"right" inBundle:nil compatibleWithTraitCollection:nil];
    }
    
    return self;
}
@end

@interface RangeContent()

@end

@implementation RangeContent {
    CGFloat _imageWidth;
    RangeContentConfig* _appearanceConfig;
}


- (instancetype)initWithImageList:(NSArray *)images
{
    _imageList = images;
    _appearanceConfig = [RangeContentConfig new];
    
    CGRect frame = {.origin = CGPointZero, .size = [self intrinsicContentSize]};
    self = [super initWithFrame:frame];
    
    [self iniSubViews];
    
    return self;
}


- (instancetype)initWithImageList:(NSArray *)images config:(RangeContentConfig *)config
{
    _imageList = images;
    _appearanceConfig = config;
    
    CGRect frame = {.origin = CGPointZero, .size = [self intrinsicContentSize]};
    self = [super initWithFrame:frame];
    
    [self iniSubViews];
    
    return self;
}

- (void)iniSubViews
{
    CGRect frame = self.bounds;
    NSMutableArray *tmpList = [NSMutableArray new];
    for (int i = 0; i < _imageList.count; i++) {
        CGRect imgFrame = CGRectMake(_appearanceConfig.pinWidth + i*[self imageWidth],
                                     _appearanceConfig.borderHeight,
                                     [self imageWidth],
                                     _appearanceConfig.thumbHeight);
        UIImageView *imgView = [[UIImageView alloc] initWithFrame:imgFrame];
        imgView.clipsToBounds = YES;
        imgView.image = _imageList[i];
        imgView.contentMode = (_imageList.count > 1 ? UIViewContentModeScaleAspectFill : UIViewContentModeScaleAspectFit);
        [self addSubview:imgView];
        [tmpList addObject:imgView];
    }
    _imageViewList = tmpList;
    
    //    self.centerCover = ({
    //        UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
    //        [self addSubview:view];
    //        view.userInteractionEnabled = YES;
    //        UIPanGestureRecognizer *panGes = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleCenterPan:)];
    //        [view addGestureRecognizer:panGes];
    //        view.accessibilityIdentifier = @"center";
    //        view;
    //    });
    
    if (_appearanceConfig.leftCorverImage) {
        self.leftCover = [[UIImageView alloc] initWithImage:_appearanceConfig.leftCorverImage];
        self.leftCover.contentMode = UIViewContentModeCenter;
        self.leftCover.clipsToBounds = YES;

    }
    else {
        self.leftCover = [[UIImageView alloc] initWithFrame:CGRectZero];
        self.leftCover.backgroundColor = [UIColor blackColor];
        self.leftCover.alpha = 0.5;
    };
    [self addSubview:self.leftCover];

    
    if (_appearanceConfig.rightCoverImage) {
        self.rightCover = [[UIImageView alloc] initWithImage:_appearanceConfig.rightCoverImage];
        self.rightCover.contentMode = UIViewContentModeCenter;
        self.rightCover.clipsToBounds = YES;

    }
    else {
        self.rightCover = [[UIImageView alloc] initWithFrame:CGRectZero];
        self.rightCover.backgroundColor = [UIColor blackColor];
        self.rightCover.alpha = 0.5;
    }
    [self addSubview:self.rightCover];
    
    self.leftPin = ({
        UIImageView *imageView = [[UIImageView alloc] initWithImage:_appearanceConfig.leftPinImage];
        imageView.contentMode = UIViewContentModeScaleToFill;
        imageView.width = _appearanceConfig.pinWidth;
        [self addSubview:imageView];
        imageView.userInteractionEnabled = YES;
        UIPanGestureRecognizer *panGes = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleLeftPan:)];
        [imageView addGestureRecognizer:panGes];
        imageView;
    });
    
    self.centerPin = ({
        UIImageView *imageView = [[UIImageView alloc] initWithImage:_appearanceConfig.centerPinImage];
        imageView.contentMode = UIViewContentModeScaleToFill;
        imageView.width = _appearanceConfig.pinWidth;
        [self addSubview:imageView];
        imageView.userInteractionEnabled = YES;
        UIPanGestureRecognizer *panGes = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleCenterPan:)];
        [imageView addGestureRecognizer:panGes];
        imageView;
    });
    self.centerPin.hidden = YES;
    
    self.rightPin = ({
        UIImageView *imageView = [[UIImageView alloc] initWithImage:_appearanceConfig.rightPigImage];
        imageView.contentMode = UIViewContentModeScaleToFill;
        imageView.width = _appearanceConfig.pinWidth;
        [self addSubview:imageView];
        imageView.userInteractionEnabled = YES;
        UIPanGestureRecognizer *panGes = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleRightPan:)];
        [imageView addGestureRecognizer:panGes];
        imageView;
    });
    
    self.topBorder = ({
        UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
        [self addSubview:view];
        view.backgroundColor = [UIColor colorWithRed:0.14 green:0.80 blue:0.67 alpha:1];
        view;
    });
    
    self.bottomBorder = ({
        UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
        [self addSubview:view];
        view.backgroundColor = [UIColor colorWithRed:0.14 green:0.80 blue:0.67 alpha:1];
        view;
    });
    
    _leftPinCenterX = _appearanceConfig.pinWidth / 2;
    _centerPinCenterX = frame.size.width / 2;
    _rightPinCenterX = frame.size.width- _appearanceConfig.pinWidth / 2;
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake([self imageWidth] * self.imageList.count + 2 * _appearanceConfig.pinWidth, _appearanceConfig.thumbHeight + 2 * _appearanceConfig.borderHeight);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.leftPin.center = CGPointMake(self.leftPinCenterX, self.height / 2);
    self.centerPin.center = CGPointMake(self.centerPinCenterX, self.height / 2);
    self.rightPin.center = CGPointMake(self.rightPinCenterX, self.height / 2);
    
    self.topBorder.height = _appearanceConfig.borderHeight;
    self.topBorder.width = self.rightPinCenterX - self.leftPinCenterX;
    self.topBorder.y = 0;
    self.topBorder.x = self.leftPinCenterX;
    
    self.bottomBorder.height = _appearanceConfig.borderHeight;
    self.bottomBorder.width = self.rightPinCenterX - self.leftPinCenterX;
    self.bottomBorder.y = self.leftPin.bottom-_appearanceConfig.borderHeight;
    self.bottomBorder.x = self.leftPinCenterX;
    
    self.centerCover.height = _appearanceConfig.thumbHeight - 2 * _appearanceConfig.borderHeight;
    self.centerCover.width = self.rightPinCenterX - self.leftPinCenterX - _appearanceConfig.pinWidth;
    self.centerCover.y = _appearanceConfig.borderHeight;
    self.centerCover.x = self.leftPinCenterX + _appearanceConfig.pinWidth / 2;
    
    self.leftCover.height = _appearanceConfig.thumbHeight;
    self.leftCover.width = self.leftPinCenterX;
    self.leftCover.y = _appearanceConfig.borderHeight;
    self.leftCover.x = 0;
    
    self.rightCover.height = _appearanceConfig.thumbHeight;
    self.rightCover.width = self.width - self.rightPinCenterX;
    self.rightCover.y = _appearanceConfig.borderHeight;
    self.rightCover.x = self.rightPinCenterX;
}

#pragma mark - Gestures

- (void)handleLeftPan:(UIPanGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan || gesture.state == UIGestureRecognizerStateChanged || gesture.state == UIGestureRecognizerStateEnded) {
        
        CGPoint translation = [gesture translationInView:self];
        
        _leftPinCenterX += translation.x;
        if (_leftPinCenterX < _appearanceConfig.pinWidth / 2) {
            _leftPinCenterX = _appearanceConfig.pinWidth / 2;
        }
        
        if (_centerPin.isHidden){
            if (_rightPinCenterX - _leftPinCenterX <= _appearanceConfig.pinWidth) {
                _leftPinCenterX = _rightPinCenterX - _appearanceConfig.pinWidth;
            }
        }else{
            if (_centerPinCenterX - _leftPinCenterX <= _appearanceConfig.pinWidth) {
                _leftPinCenterX = _centerPinCenterX - _appearanceConfig.pinWidth;
            }
        }
  
        [gesture setTranslation:CGPointZero inView:self];
        
        [self setNeedsLayout];
        
        if (gesture.state == UIGestureRecognizerStateBegan) {
            if ([self.delegate respondsToSelector:@selector(onRangeLeftChangeBegin:)])
                [self.delegate onRangeLeftChangeBegin:self];
        }
        else if (gesture.state == UIGestureRecognizerStateChanged){
            if ([self.delegate respondsToSelector:@selector(onRangeLeftChanged:)])
                [self.delegate onRangeLeftChanged:self];
        }
        else {
            if ([self.delegate respondsToSelector:@selector(onRangeLeftChangeEnded:)])
                [self.delegate onRangeLeftChangeEnded:self];
        }

    }
}

- (void)handleCenterPan:(UIPanGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan || gesture.state == UIGestureRecognizerStateChanged || gesture.state == UIGestureRecognizerStateEnded) {
        
        CGPoint translation = [gesture translationInView:self];
        
        _centerPinCenterX += translation.x;
        if (_centerPinCenterX < _leftPinCenterX + _appearanceConfig.pinWidth) {
            _centerPinCenterX = _leftPinCenterX + _appearanceConfig.pinWidth;
        }
        if (_centerPinCenterX > _rightPinCenterX - _appearanceConfig.pinWidth) {
            _centerPinCenterX = _rightPinCenterX - _appearanceConfig.pinWidth;
        }
        
        [gesture setTranslation:CGPointZero inView:self];
        
        [self setNeedsLayout];
        
        if (gesture.state == UIGestureRecognizerStateBegan) {
            if ([self.delegate respondsToSelector:@selector(onRangeCenterChangeBegin:)])
                [self.delegate onRangeCenterChangeBegin:self];
        }
        else if (gesture.state == UIGestureRecognizerStateChanged){
            if ([self.delegate respondsToSelector:@selector(onRangeCenterChanged:)])
                [self.delegate onRangeCenterChanged:self];
        }
        else {
            if ([self.delegate respondsToSelector:@selector(onRangeCenterChangeEnded:)])
                [self.delegate onRangeCenterChangeEnded:self];
        }
        
    }
}


- (void)handleRightPan:(UIPanGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan || gesture.state == UIGestureRecognizerStateChanged || gesture.state == UIGestureRecognizerStateEnded) {
        
        CGPoint translation = [gesture translationInView:self];
        
        _rightPinCenterX += translation.x;
        if (_rightPinCenterX > self.width - _appearanceConfig.pinWidth / 2) {
            _rightPinCenterX = self.width - _appearanceConfig.pinWidth / 2;
        }
        
        if (_centerPin.isHidden) {
            if (_rightPinCenterX-_leftPinCenterX <= _appearanceConfig.pinWidth) {
                _rightPinCenterX = _leftPinCenterX + _appearanceConfig.pinWidth;
            }
        }else{
            if (_rightPinCenterX-_centerPinCenterX <= _appearanceConfig.pinWidth) {
                _rightPinCenterX = _centerPinCenterX + _appearanceConfig.pinWidth;
            }
        }
        
        [gesture setTranslation:CGPointZero inView:self];
        
        [self setNeedsLayout];
        
        
        if (gesture.state == UIGestureRecognizerStateBegan) {
            if ([self.delegate respondsToSelector:@selector(onRangeRightChangeBegin:)])
                [self.delegate onRangeRightChangeBegin:self];
        }
        else if (gesture.state == UIGestureRecognizerStateChanged) {
            if ([self.delegate respondsToSelector:@selector(onRangeRightChanged:)])
                [self.delegate onRangeRightChanged:self];
        }
        else {
            if ([self.delegate respondsToSelector:@selector(onRangeRightChangeEnded:)])
                [self.delegate onRangeRightChangeEnded:self];
        }
    }
}


//- (void)handleCenterPan:(UIPanGestureRecognizer *)gesture
//{
//
//    if (gesture.state == UIGestureRecognizerStateBegan || gesture.state == UIGestureRecognizerStateChanged) {
//
//        CGPoint translation = [gesture translationInView:self];
//
//        _leftPinCenterX += translation.x;
//        _rightPinCenterX += translation.x;
//
//        if (_rightPinCenterX > self.width - _appearanceConfig.pinWidth || _leftPinCenterX < _appearanceConfig.pinWidth / 2){
//            _leftPinCenterX -= translation.x;
//            _rightPinCenterX -= translation.x;
//        }
//
//        [gesture setTranslation:CGPointZero inView:self];
//
//        [self setNeedsLayout];
//
//        if ([self.delegate respondsToSelector:@selector(onRangeLeftAndRightChanged:)])
//            [self.delegate onRangeLeftAndRightChanged:self];
//
//    }
//}

- (CGFloat)pinWidth
{
    return _appearanceConfig.pinWidth;
}

- (CGFloat)imageWidth
{
    UIImage *img = self.imageList[0];
    if (self.imageList.count == 1) {
        return MIN(img.size.width, [UIScreen mainScreen].bounds.size.width - 2 * _appearanceConfig.pinWidth);
    }
    _imageWidth = img.size.width/img.size.height*_appearanceConfig.thumbHeight;
    return _imageWidth;
}

- (CGFloat)imageListWidth {
    return self.imageList.count * [self imageWidth];
}

- (CGFloat)leftScale {
    CGFloat imagesLength = [self imageWidth] * self.imageViewList.count;
    return MAX(0, (_leftPinCenterX - _appearanceConfig.pinWidth / 2) / imagesLength);
}

- (CGFloat)rightScale {
    CGFloat imagesLength = [self imageWidth] * self.imageViewList.count;
    return MAX(0, (_rightPinCenterX - _appearanceConfig.pinWidth / 2 - _appearanceConfig.pinWidth) / imagesLength);
}

- (CGFloat)centerScale {
    CGFloat imagesLength = [self imageWidth] * self.imageViewList.count;
    return MAX(0, (_centerPinCenterX - _appearanceConfig.pinWidth / 2 - _appearanceConfig.pinWidth) / imagesLength);
}
@end
