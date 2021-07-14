//
//  TRTCRemoteView.m
//  TXLiteAVDemo
//
//  Created by bluedang on 2021/5/18.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "TRTCVideoView.h"
#import "UIView+Additions.h"
#import "ColorMacro.h"
#import "Masonry.h"

@interface TRTCVideoView ()<UIGestureRecognizerDelegate>
@property (nonatomic, assign) CGPoint touchPoint;
@end


@implementation TRTCVideoView

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapView)];
    tapGesture.delegate = self;
    [self addGestureRecognizer:tapGesture];
    
    _audioVolumeIndicator = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    _audioVolumeIndicator.progressTintColor = UIColorFromRGB(0x2364db);
    _audioVolumeIndicator.progress = 0.5;
    [self addSubview:_audioVolumeIndicator];
    
    self.userConfig = [[TRTCRemoteUserConfig alloc] init];
}

- (void)onTapView {
    if ([self.delegate respondsToSelector:@selector(onViewTap:)]) {
        [self.delegate onViewTap:self];
    }
}

- (void)setAudioVolumeRadio:(float)volumeRadio {
    _audioVolumeIndicator.progress = volumeRadio;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGSize size = self.frame.size;
    _audioVolumeIndicator.frame = CGRectMake(0, size.height - 2, size.width, 2);
}

- (void)showText:(NSString *)text {    
    const NSInteger tag = 1801;
    UILabel *label = [self viewWithTag:tag];
    if (!label) {
        label = [[UILabel alloc] init];
        label.font = [UIFont systemFontOfSize:17];
        label.minimumScaleFactor = 0.3;
        label.textColor = [UIColor whiteColor];
        label.tag = tag;
        label.adjustsFontSizeToFitWidth = true;
        label.textAlignment = NSTextAlignmentCenter;
        [self addSubview:label];
        [label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self);
            make.width.equalTo(self).multipliedBy(0.7);
        }];
    }
    label.text = text;
}


#pragma mark - touchs

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    _touchPoint = self.center;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
        
    UITouch *touch = [touches anyObject];
    
    // 当前触摸点
    CGPoint currentPoint = [touch locationInView:self.superview];
    // 上一个触摸点
    CGPoint previousPoint = [touch previousLocationInView:self.superview];
    
    // 当前view的中点
    CGPoint center = self.center;
    
    center.x += (currentPoint.x - previousPoint.x);
    center.y += (currentPoint.y - previousPoint.y);
    
    if (center.x < self.width / 2) {
        center.x = self.width / 2;
    }
    
    if (center.x > self.superview.frame.size.width - self.width / 2) {
        center.x = self.superview.frame.size.width - self.width / 2;
    }
    
    if (center.y < self.height / 2) {
        center.y = self.height / 2;
    }
    
    if (center.y > self.superview.frame.size.height - self.height / 2) {
        center.y = self.superview.frame.size.height - self.height / 2;
    }
    
    // 修改当前view的中点(中点改变view的位置就会改变)
    self.center = center;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    CGPoint center = self.center;
    
    if (fabs(center.x - _touchPoint.x) > 0.000001f || fabs(center.y - _touchPoint.y) > 0.0000001f)
        return;
}


#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

@end
