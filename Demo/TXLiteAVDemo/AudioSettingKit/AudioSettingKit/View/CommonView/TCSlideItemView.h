//
//  TCSlideItemView.h
//  TCAudioSettingKit
//
//  Created by abyyxwang on 2020/5/27.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class TCSlideItemView;
@protocol TCSlideItemDelegate <NSObject>

- (void)slideItemView:(TCSlideItemView *)view slideValueDidChanged:(CGFloat)value;

@end

@protocol TCSlideBgmItemDelegate <NSObject>

- (void)resetMusicButton;
- (void)bgmSliderPauseMusic;
- (void)bgmSliderResumeMusic;
@end

@interface TCSlideItemView : UIView

@property(nonatomic, strong) NSString *title;
@property(nonatomic, strong) UIImage * icon;
@property(nonatomic, assign) CGFloat   minValue;
@property(nonatomic, assign) CGFloat   maxVlaue;
@property(nonatomic, assign) CGFloat   defaultValue;
@property(nonatomic, strong) UIColor * maxColor;
@property(nonatomic, strong) UIColor * minColor;
@property(nonatomic, assign) BOOL      isFloatAccuracy;

@property(nonatomic, weak) id<TCSlideItemDelegate> delegate;

@end

@interface TCSlideBgmItemView : TCSlideItemView
@property(nonatomic, weak) id<TCSlideBgmItemDelegate> bgmDelegate;
- (void)refreshMusicPlayingProgress:(NSInteger)currentSec total:(NSInteger)totalSec;
- (void)resetProgress;
- (void)setSliderUserInteractionEnabled:(BOOL)isUserInteractionEnabled;

@end
NS_ASSUME_NONNULL_END
