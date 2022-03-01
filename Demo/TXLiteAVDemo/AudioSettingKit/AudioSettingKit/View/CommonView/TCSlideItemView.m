//
//  TCSlideItemView.m
//  TCAudioSettingKit
//
//  Created by abyyxwang on 2020/5/27.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "TCSlideItemView.h"
#import <Masonry/Masonry.h>
#import "TCASKitTheme.h"

@interface TCSlideItemView () {
    BOOL _isViewReady;
}

@property(nonatomic, strong) TCASKitTheme *theme;

@property(nonatomic, strong) UILabel *    titleLabel;
@property(nonatomic, strong) UILabel *    volumValueLabel;
@property(nonatomic, strong) UIImageView *voiceIcon;
@property(nonatomic, strong) UISlider *   slideView;

@end

@implementation TCSlideItemView

- (instancetype)init {
    self = [super init];
    if (self) {
        self.maxVlaue     = 100;
        self.minValue     = 0;
        self.defaultValue = 50;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.maxVlaue     = 100;
        self.minValue     = 0;
        self.defaultValue = 50;
    }
    return self;
}

#pragma mark - setter方法重写
- (void)setIcon:(UIImage *)icon {
    _icon                = icon;
    self.voiceIcon.image = icon;
    if (self.slideView.superview) {
        CGFloat value = icon == nil ? 16.0 : 26.0;
        [self.slideView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.titleLabel.mas_right).offset(value);
        }];
    }
}

- (void)setMaxVlaue:(CGFloat)maxVlaue {
    _maxVlaue                   = maxVlaue;
    self.slideView.maximumValue = maxVlaue;
}

- (void)setMinValue:(CGFloat)minValue {
    _minValue                   = minValue;
    self.slideView.minimumValue = minValue;
}

- (void)setDefaultValue:(CGFloat)defaultValue {
    _defaultValue             = defaultValue;
    self.slideView.value      = defaultValue;
    self.volumValueLabel.text = [NSString stringWithFormat:@"%.0f", defaultValue];
}

- (void)setMaxColor:(UIColor *)maxColor {
    _maxColor                            = maxColor;
    self.slideView.maximumTrackTintColor = maxColor;
}

- (void)setMinColor:(UIColor *)minColor {
    _minColor                            = minColor;
    self.slideView.minimumTrackTintColor = minColor;
}

- (void)setTitle:(NSString *)title {
    _title               = title;
    self.titleLabel.text = title;
}

#pragma mark - 视图属性懒加载
- (TCASKitTheme *)theme {
    if (!_theme) {
        _theme = [[TCASKitTheme alloc] init];
    }
    return _theme;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        UILabel *label  = [[UILabel alloc] init];
        label.text      = [self.theme localizedString:@"ASKit.MainMenu.BGM"];
        label.font      = [self.theme themeFontWithSize:16.0];
        label.textColor = self.theme.normalFontColor;
        _titleLabel     = label;
    }
    return _titleLabel;
}

- (UIImageView *)voiceIcon {
    if (!_voiceIcon) {
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.contentMode  = UIViewContentModeScaleAspectFit;
        _voiceIcon             = imageView;
    }
    return _voiceIcon;
}

- (UISlider *)slideView {
    if (!_slideView) {
        _slideView                       = [[UISlider alloc] init];
        _slideView.maximumValue          = self.maxVlaue;
        _slideView.minimumValue          = self.minValue;
        _slideView.value                 = self.defaultValue;
        _slideView.minimumTrackTintColor = self.theme.sliderMinColor;
        _slideView.maximumTrackTintColor = self.theme.sliderMaxColor;
        [_slideView addTarget:self action:@selector(slideValueChanged:) forControlEvents:UIControlEventValueChanged];
    }
    return _slideView;
}

- (UILabel *)volumValueLabel {
    if (!_volumValueLabel) {
        UILabel *label      = [[UILabel alloc] init];
        label.text          = [NSString stringWithFormat:@"%.0f", self.defaultValue];
        label.font          = [self.theme themeFontWithSize:14.0];
        label.textColor     = self.theme.normalFontColor;
        label.alpha         = 0.5;
        label.textAlignment = NSTextAlignmentCenter;
        _volumValueLabel    = label;
    }
    return _volumValueLabel;
}

#pragma mark - 视图生命周期
- (void)didMoveToWindow {
    [super didMoveToWindow];
    if (self->_isViewReady) {
        return;
    }
    [self constructViewHierachy];
    [self activateConstraints];
    self->_isViewReady = YES;
    [self setupStyle];
}

#pragma mark - 构造视图层级,初始化布局
/// 构造视图层级
- (void)constructViewHierachy {
    [self addSubview:self.titleLabel];
    [self addSubview:self.slideView];
    [self addSubview:self.volumValueLabel];
    [self addSubview:self.voiceIcon];
}

/// 构造视图约束
- (void)activateConstraints {
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.mas_centerY);
        make.left.equalTo(self.mas_left).offset(20);
    }];
    [self.titleLabel sizeToFit];
    [self.voiceIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.mas_centerY);
        make.height.mas_equalTo(20);
        make.width.mas_equalTo(20);
        make.left.equalTo(self.titleLabel.mas_right).offset(4);
    }];
    [self.volumValueLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.mas_centerY);
        make.right.equalTo(self).offset(-20);
        make.width.mas_equalTo(30);
    }];
    CGFloat value = self.icon == nil ? 16.0 : 26.0;
    [self.slideView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.titleLabel.mas_right).offset(value);
        make.right.equalTo(self.volumValueLabel.mas_left).offset(-3.0);
        make.centerY.equalTo(self.mas_centerY);
    }];
}

/// 绑定视图交互
- (void)bindInteraction {
}
/// 设置视图样式
- (void)setupStyle {
}

#pragma mark - target-action
- (void)slideValueChanged:(UISlider *)sender {
    if (self.isFloatAccuracy) {
        CGFloat value             = 0.1 - fabsf(sender.value) < 0 ? sender.value : 0;
        self.volumValueLabel.text = [NSString stringWithFormat:@"%.1f", value];
    } else {
        CGFloat value             = 1 - fabsf(sender.value) < 0 ? sender.value : 0;
        self.volumValueLabel.text = [NSString stringWithFormat:@"%.0f", value];
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(slideItemView:slideValueDidChanged:)]) {
        [self.delegate slideItemView:self slideValueDidChanged:sender.value];
    }
}
@end


#pragma mark - TCSlideBgmItemView
@interface TCSlideBgmItemView () {
    BOOL _isViewReady;
}

@property(nonatomic, strong) UIButton *stopButton;
@property(nonatomic, strong) UILabel  *percentSign;
@end

@implementation TCSlideBgmItemView

- (UIButton *)stopButton {
    if (!_stopButton) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setImage:[UIImage imageNamed:@"audio_stop"] forState:UIControlStateNormal];
        button.imageView.contentMode = UIViewContentModeScaleAspectFit;
        button.tintColor = self.theme.normalFontColor;
        [button addTarget:self action:@selector(onClickStopButton:) forControlEvents:UIControlEventTouchUpInside];
        _stopButton = button;
    }
    return _stopButton;
}

- (UILabel *)percentSign {
    if (!_percentSign) {
        UILabel *label      = [[UILabel alloc] init];
        label.text          = @"%";
        label.font          = [self.theme themeFontWithSize:14.0];
        label.textColor     = self.theme.normalFontColor;
        label.alpha         = 0.5;
        label.textAlignment = NSTextAlignmentCenter;
        [label sizeToFit];
        _percentSign = label;
    }
    return _percentSign;
}

#pragma mark - 视图生命周期
- (void)didMoveToWindow {
    [super didMoveToWindow];
    if (self->_isViewReady) {
        return;
    }
    [self constructViewHierachy];
    [self activateConstraints];
    self->_isViewReady = YES;
    [self setupStyle];
    [self.slideView addTarget:self action:@selector(slideTouchOut:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
    [self.slideView addTarget:self action:@selector(slideTochDown:) forControlEvents:UIControlEventTouchDown];
    self.slideView.userInteractionEnabled = NO;
}

/// 构造视图层级
- (void)constructViewHierachy {
    [super constructViewHierachy];

    [self addSubview:self.stopButton];
    [self addSubview:self.percentSign];
}

/// 构造视图约束
- (void)activateConstraints {
    [super activateConstraints];
    
    
    [self.stopButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.mas_centerY);
        make.left.equalTo(self.titleLabel.mas_right).offset(10);
        make.size.mas_equalTo(CGSizeMake(30, 30));
    }];
    
    CGFloat value = self.icon == nil ? 16.0 : 26.0;
    [self.slideView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.stopButton.mas_right).offset(value);
        make.right.equalTo(self.volumValueLabel.mas_left).offset(-3.0);
        make.centerY.equalTo(self.mas_centerY);
    }];
    
    [self.percentSign mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.mas_centerY);
        make.left.equalTo(self.volumValueLabel.mas_right).offset(-5);
    }];
}

- (void)onClickStopButton:(UIButton *)button {
    if (self.bgmDelegate && [self.bgmDelegate respondsToSelector:@selector(resetMusicButton)]) {
        [self.bgmDelegate resetMusicButton];
    }
}

- (void)refreshMusicPlayingProgress:(NSInteger)currentSec total:(NSInteger)totalSec {
    self.slideView.value = currentSec * 100 / totalSec;
    self.volumValueLabel.text  = [NSString stringWithFormat:@"%ld", (currentSec * 100 / totalSec)];
}

- (void)resetProgress {
    [self.slideView setValue:0];
    self.volumValueLabel.text = @"0";
}

- (void)setSliderUserInteractionEnabled:(BOOL)isUserInteractionEnabled {
    self.slideView.userInteractionEnabled = isUserInteractionEnabled;
}

#pragma mark - target-action
- (void)slideValueChanged:(UISlider *)sender {
    if (self.isFloatAccuracy) {
        CGFloat value             = 0.1 - fabsf(sender.value) < 0 ? sender.value : 0;
        self.volumValueLabel.text = [NSString stringWithFormat:@"%.1f", value];
    } else {
        CGFloat value             = 1 - fabsf(sender.value) < 0 ? sender.value : 0;
        self.volumValueLabel.text = [NSString stringWithFormat:@"%.0f", value];
    }
}

- (void)slideTouchOut:(UISlider *)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(slideItemView:slideValueDidChanged:)]) {
        [self.delegate slideItemView:self slideValueDidChanged:sender.value];
        if (self.bgmDelegate && [self.bgmDelegate respondsToSelector:@selector(bgmSliderResumeMusic)]) {
            [self.bgmDelegate bgmSliderResumeMusic];
        }
    }
}

- (void)slideTochDown:(UISlider *)sender {
    if (self.bgmDelegate && [self.bgmDelegate respondsToSelector:@selector(bgmSliderPauseMusic)]) {
        [self.bgmDelegate bgmSliderPauseMusic];
    }
}
@end
