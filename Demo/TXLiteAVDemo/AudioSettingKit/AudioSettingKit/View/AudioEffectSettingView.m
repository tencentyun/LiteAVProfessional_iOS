//
//  AudioEffectSettingView.m
//  TCAudioSettingKit
//
//  Created by abyyxwang on 2020/5/26.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "AudioEffectSettingView.h"
#import "AudioEffectSettingViewModel.h"
#import "TCAudioScrollMenuView.h"
#import "TCMusicSelectItemView.h"
#import "TCMusicSelectView.h"
#import "TCMusicSelectedModel.h"
#import "TCSlideItemView.h"
#import "TCASKitTheme.h"
#import <Masonry/Masonry.h>

#define IS_IPhoneXSeries                                                                                \
    ({                                                                                                  \
        BOOL isPhoneX = NO;                                                                             \
        if (@available(iOS 11.0, *)) {                                                                  \
            isPhoneX = [[UIApplication sharedApplication] delegate].window.safeAreaInsets.bottom > 0.0; \
        }                                                                                               \
        (isPhoneX);                                                                                     \
    })

#define kSafeAreaBottom 34
#define kDefaultHeight  526

@interface AudioEffectSettingView () <TCMusicSelectItemDelegate, TCMusicSelectedDelegate, TCSlideItemDelegate, TCMusicPlayStatusDelegate, TCSlideBgmItemDelegate> {
    BOOL                       _isViewReady;  // 视图布局是否完成
    AudioEffectSettingViewType _currentType;
    BOOL                       _isShow;
}

@property(nonatomic, strong) AudioEffectSettingViewModel *viewModel;

@property(nonatomic, strong) TCASKitTheme *theme;

// 视图相关属性
@property(nonatomic, strong) UIScrollView *mainContainer;
@property(nonatomic, strong) UIView       *headerContainer;
@property(nonatomic, strong) UILabel      *titleLabel;
@property(nonatomic, strong) UIButton     *closeButton;

@property(nonatomic, strong) TCMusicSelectItemView *musicSelectItemView;

@property(nonatomic, strong) UIStackView        *slideContainer;
@property(nonatomic, strong) TCSlideBgmItemView *bgmPlayView;
@property(nonatomic, strong) TCSlideItemView    *musicVolumView;
@property(nonatomic, strong) TCSlideItemView    *personVolumView;
@property(nonatomic, strong) TCSlideItemView    *personPitchView;
@property(nonatomic, strong) TCSlideItemView    *bgmRateView;
@property(nonatomic, strong) TCSlideItemView    *localVolumeView;
@property(nonatomic, strong) TCSlideItemView    *remoteVolumeView;
@property(nonatomic, strong) UIView             *bgmLoopView;

@property(nonatomic, strong) UIStackView           *collectionContainer;
@property(nonatomic, strong) TCAudioScrollMenuView *voiceChangeView;
@property(nonatomic, strong) TCAudioScrollMenuView *reverberationView;

@property(nonatomic, strong) TCMusicSelectView     *musiceSelectView;

@property(nonatomic, strong) TCMusicSelectedModel  *currentMusic;

@property(nonatomic, assign) BOOL debugMode;
@end

@implementation AudioEffectSettingView

- (instancetype)initWithType:(AudioEffectSettingViewType)type theme:(TCASKitTheme *)theme {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self->_theme          = theme;
        self->_currentType    = type;
        CGFloat bottom_height = IS_IPhoneXSeries ? kSafeAreaBottom : 0;
        self.frame            = CGRectMake(0, [UIScreen mainScreen].bounds.size.height - kDefaultHeight - bottom_height, [UIScreen mainScreen].bounds.size.width, kDefaultHeight + bottom_height);
        [self createViewModel];
        [self setupInitStyle];
        [self bindInteraction];
        self.debugMode = NO;
    }
    return self;
}

- (instancetype)initWithType:(AudioEffectSettingViewType)type {
    return [self initWithType:type theme:nil];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self createViewModel];
        self->_currentType = AudioEffectSettingViewCustom;
        [self createViewModel];
        [self setupInitStyle];
        [self bindInteraction];
        self.debugMode = NO;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self createViewModel];
        self->_currentType = AudioEffectSettingViewCustom;
        [self setupInitStyle];
        [self bindInteraction];
        self.debugMode = NO;
    }
    return self;
}

- (void)setIsDebugMode {
    self.debugMode = YES;
}

- (void)setupInitStyle {
    self.hidden = YES;
    self.alpha  = 0.0;
    [self initBackgroundColor];
}

- (void)createViewModel {
    self.viewModel          = [[AudioEffectSettingViewModel alloc] init];
    self.viewModel.delegate = self;
}

#pragma mark - public method 实现

+ (CGFloat)height {
    return kDefaultHeight;
}

- (void)show {
    if (self->_isShow) {
        return;
    }
    self->_isShow = YES;
    self.alpha    = 0.0;
    self.hidden   = YES;
    [UIView animateWithDuration:0.3
                     animations:^{
                         self.alpha  = 1.0;
                         self.hidden = NO;
                     }];
    if (self.delegate && [self.delegate respondsToSelector:@selector(onEffectViewHidden:)]) {
        [self.delegate onEffectViewHidden:NO];
    }
}

- (void)hide {
    if (!self->_isShow) {
        return;
    }
    self->_isShow = NO;
    self.alpha    = 1.0;
    self.hidden   = NO;
    if (self.musiceSelectView.isHidden == NO) {
        [self.musiceSelectView hide];
    }
    [UIView animateWithDuration:0.3
                     animations:^{
                         self.alpha  = 0.0;
                         self.hidden = YES;
                     }];
    if (self.delegate && [self.delegate respondsToSelector:@selector(onEffectViewHidden:)]) {
        [self.delegate onEffectViewHidden:YES];
    }
}

- (void)setAudioEffectManager:(TXAudioEffectManager *)manager {
    [self.viewModel setAudioEffectManager:manager];
}

- (void)stopPlay {
    [self.viewModel stopPlay];
}

- (void)recoveryVoiceSetting {
    [self.viewModel recoveryVoiceSetting];
}

#pragma mark - 视图属性懒加载
- (TCASKitTheme *)theme {
    if (!_theme) {
        _theme = [[TCASKitTheme alloc] init];
    }
    return _theme;
}

- (UIScrollView *)mainContainer {
    if (!_mainContainer) {
        _mainContainer                 = [[UIScrollView alloc] initWithFrame:CGRectZero];
        _mainContainer.backgroundColor = UIColor.clearColor;
        _mainContainer.contentInset    = UIEdgeInsetsMake(0, 0, 20, 0);
    }
    return _mainContainer;
}

- (UIView *)headerContainer {
    if (!_headerContainer) {
        _headerContainer                 = [[UIView alloc] initWithFrame:CGRectZero];
        _headerContainer.backgroundColor = UIColor.clearColor;
    }
    return _headerContainer;
}

- (UIStackView *)slideContainer {
    if (!_slideContainer) {
        _slideContainer              = [[UIStackView alloc] initWithFrame:CGRectZero];
        _slideContainer.axis         = UILayoutConstraintAxisVertical;
        _slideContainer.spacing      = 30.0;
        _slideContainer.alignment    = UIStackViewAlignmentFill;
        _slideContainer.distribution = UIStackViewDistributionEqualCentering;
    }
    return _slideContainer;
}

- (UIStackView *)collectionContainer {
    if (!_collectionContainer) {
        _collectionContainer              = [[UIStackView alloc] initWithFrame:CGRectZero];
        _collectionContainer.axis         = UILayoutConstraintAxisVertical;
        _collectionContainer.spacing      = 20.0;
        _collectionContainer.alignment    = UIStackViewAlignmentFill;
        _collectionContainer.distribution = UIStackViewDistributionEqualCentering;
    }
    return _collectionContainer;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        UILabel *label  = [[UILabel alloc] initWithFrame:CGRectZero];
        label.text      = [self.theme localizedString:@"ASKit.MainMenu.Title"];
        label.font      = [self.theme themeFontWithSize:16.0];
        label.textColor = self.theme.normalFontColor;
        _titleLabel     = label;
    }
    return _titleLabel;
}

- (UIButton *)closeButton {
    if (!_closeButton) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setTitle:[self.theme localizedString:@"ASKit.Common.Close"] forState:UIControlStateNormal];
        button.titleLabel.font = [self.theme themeFontWithSize:16.0];
        [button setTitleColor:[self.theme normalFontColor] forState:UIControlStateNormal];
        _closeButton = button;
    }
    return _closeButton;
}

- (TCMusicSelectItemView *)musicSelectItemView {
    if (!_musicSelectItemView) {
        _musicSelectItemView = [[TCMusicSelectItemView alloc] init];
    }
    return _musicSelectItemView;
}

- (TCSlideItemView *)musicVolumView {
    if (!_musicVolumView) {
        TCSlideItemView *slideView = [[TCSlideItemView alloc] init];
        slideView.title            = [self.theme localizedString:@"ASKit.MainMenu.MusicVolum"];
        slideView.icon             = [self.theme imageNamed:@"VoiceSetting_volum"];
        slideView.defaultValue     = 100.0;
        slideView.delegate         = self;
        _musicVolumView            = slideView;
    }
    return _musicVolumView;
}

- (TCSlideItemView *)personVolumView {
    if (!_personVolumView) {
        TCSlideItemView *slideView = [[TCSlideItemView alloc] init];
        slideView.title            = [self.theme localizedString:@"ASKit.MainMenu.PersonVolum"];
        slideView.icon             = [self.theme imageNamed:@"VoiceSetting_volum"];
        slideView.defaultValue     = 100.0;
        slideView.delegate         = self;
        _personVolumView           = slideView;
    }
    return _personVolumView;
}

- (TCSlideItemView *)personPitchView {
    if (!_personPitchView) {
        TCSlideItemView *slideView = [[TCSlideItemView alloc] init];
        slideView.title            = [self.theme localizedString:@"ASKit.MainMenu.PersonPitch"];
        slideView.minValue         = -1.0;
        slideView.maxVlaue         = 1.0;
        slideView.defaultValue     = 0.0;
        slideView.delegate         = self;
        slideView.isFloatAccuracy  = YES;
        _personPitchView           = slideView;
    }
    return _personPitchView;
}

- (TCSlideBgmItemView *)bgmPlayView {
    if (!_bgmPlayView) {
        TCSlideBgmItemView *bgmSlideView = [[TCSlideBgmItemView alloc] init];
        bgmSlideView.title               = [self.theme localizedString:@"ASKit.MainMenu.PlayBGM"];
        bgmSlideView.minValue            = 0;
        bgmSlideView.maxVlaue            = 100;
        bgmSlideView.defaultValue        = 0;
        bgmSlideView.delegate            = self;
        bgmSlideView.bgmDelegate         = self;
        bgmSlideView.isFloatAccuracy     = NO;
        _bgmPlayView                     = bgmSlideView;
    }
    return _bgmPlayView;
}

- (TCSlideItemView *)bgmRateView {
    if (!_bgmRateView) {
        TCSlideItemView *slideView = [[TCSlideItemView alloc] init];
        slideView.title            = [self.theme localizedString:@"ASKit.MainMenu.BGMRate"];
        slideView.minValue         = 0.5;
        slideView.maxVlaue         = 2;
        slideView.defaultValue     = 1;
        slideView.delegate         = self;
        slideView.isFloatAccuracy  = YES;
        _bgmRateView               = slideView;
    }
    return _bgmRateView;
}

- (TCSlideItemView *)localVolumeView {
    if (!_localVolumeView) {
        TCSlideItemView *slideView = [[TCSlideItemView alloc] init];
        slideView.title            = [self.theme localizedString:@"ASKit.MainMenu.LocalVolume"];
        slideView.minValue         = 0;
        slideView.maxVlaue         = 100;
        slideView.defaultValue     = 100;
        slideView.delegate         = self;
        slideView.isFloatAccuracy  = NO;
        _localVolumeView           = slideView;
    }
    return _localVolumeView;
}

- (TCSlideItemView *)remoteVolumeView {
    if (!_remoteVolumeView) {
        TCSlideItemView *slideView = [[TCSlideItemView alloc] init];
        slideView.title            = [self.theme localizedString:@"ASKit.MainMenu.RemoteVolume"];
        slideView.minValue         = 0;
        slideView.maxVlaue         = 100;
        slideView.defaultValue     = 100;
        slideView.delegate         = self;
        slideView.isFloatAccuracy  = NO;
        _remoteVolumeView          = slideView;
    }
    return _remoteVolumeView;
}

- (UIView *)bgmLoopView {
    if (!_bgmLoopView) {
        UIView *view    = [[UIView alloc] initWithFrame:CGRectZero];
        UILabel *label  = [[UILabel alloc] init];
        label.text      = [self.theme localizedString:@"ASKit.MainMenu.LoopPlay"];
        label.font      = [self.theme themeFontWithSize:16.0];
        label.textColor = self.theme.normalFontColor;
        [view addSubview:label];
        [label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(view);
            make.left.equalTo(view).offset(20);
        }];
        UISwitch *on    = [[UISwitch alloc] initWithFrame:CGRectZero];
        on.onTintColor  = [UIColor blueColor];
        on.tintColor    = [UIColor blueColor];
        [view addSubview:on];
        [on mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(view).offset(-20);
            make.centerY.equalTo(view);
        }];
        _bgmLoopView = view;
    }
    return _bgmLoopView;
}

- (UISwitch *)bgmLoopView_on {
    UISwitch *on = nil;
    for (UIView *subview in self.bgmLoopView.subviews) {
        if ([subview isKindOfClass:[UISwitch class]]) {
            on = (UISwitch *) subview;
            break;
        }
    }
    return on;
}

- (TCAudioScrollMenuView *)voiceChangeView {
    if (!_voiceChangeView) {
        TCAudioScrollMenuView *view = [[TCAudioScrollMenuView alloc] init];
        view.title                  = [self.theme localizedString:@"ASKit.MainMenu.VoiceChangeTitle"];
        view.dataSource             = self.viewModel.voiceChangeSources;
        _voiceChangeView            = view;
    }
    return _voiceChangeView;
}

- (TCAudioScrollMenuView *)reverberationView {
    if (!_reverberationView) {
        TCAudioScrollMenuView *view = [[TCAudioScrollMenuView alloc] init];
        view.title                  = [self.theme localizedString:@"ASKit.MainMenu.Reverberation"];
        view.dataSource             = self.viewModel.reverberationSources;
        _reverberationView          = view;
    }
    return _reverberationView;
}

- (TCMusicSelectView *)musiceSelectView {
    if (!_musiceSelectView) {
        _musiceSelectView          = [[TCMusicSelectView alloc] initWithViewModel:self.viewModel];
        _musiceSelectView.frame    = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 280);  // 提前设置frame，方便切圆角
        _musiceSelectView.delegate = self;
    }
    return _musiceSelectView;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    [super setBackgroundColor:UIColor.clearColor];
    self.mainContainer.backgroundColor    = backgroundColor;
    self.musiceSelectView.backgroundColor = backgroundColor;
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
    [self addSubview:self.mainContainer];
    [self.mainContainer addSubview:self.headerContainer];
    [self.headerContainer addSubview:self.titleLabel];
    [self.headerContainer addSubview:self.closeButton];

    [self.mainContainer addSubview:self.musicSelectItemView];
    
    if (self.debugMode) {
        [self.slideContainer addArrangedSubview:self.bgmPlayView];
        [self.slideContainer addArrangedSubview:self.bgmLoopView];
        [self.slideContainer addArrangedSubview:self.bgmRateView];
    }
    [self.slideContainer addArrangedSubview:self.musicVolumView];
    [self.slideContainer addArrangedSubview:self.personVolumView];
    [self.slideContainer addArrangedSubview:self.personPitchView];
    if (self.debugMode) {
        [self.slideContainer addArrangedSubview:self.localVolumeView];
        [self.slideContainer addArrangedSubview:self.remoteVolumeView];
    }
    [self.mainContainer addSubview:self.slideContainer];

    [self.collectionContainer addArrangedSubview:self.voiceChangeView];
    [self.collectionContainer addArrangedSubview:self.reverberationView];
    [self.mainContainer addSubview:self.collectionContainer];

    [self addSubview:self.musiceSelectView];
}

/// 构造视图约束
- (void)activateConstraints {
    [self.mainContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self);
        make.top.equalTo(self);
        make.bottom.equalTo(self);
    }];
    [self activeConstraintsOfTitleContainer];
    [self activeConstraintsOfMusicSelectItem];
    [self activeConstraintsOfSlideContainer];
    [self activeConstraintsOfCollectionContainer];
    [self activeConstraintsOfMusicSelectView];
}

- (void)activeConstraintsOfTitleContainer {
    [self.headerContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.centerX.equalTo(self.mainContainer);
        make.height.mas_equalTo(56);
    }];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.headerContainer.mas_centerX);
        make.centerY.equalTo(self.headerContainer.mas_centerY);
    }];
    [self.titleLabel sizeToFit];
    [self.closeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.headerContainer.mas_centerY);
        make.right.equalTo(self.headerContainer.mas_right).offset(-20.0);
    }];
    [self.closeButton sizeToFit];
}

- (void)activeConstraintsOfMusicSelectItem {
    [self.musicSelectItemView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.headerContainer.mas_bottom);
        make.left.right.centerX.equalTo(self.mainContainer);
        make.height.mas_equalTo(52);
    }];
}

- (void)activeConstraintsOfSlideContainer {
    [self.slideContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.musicSelectItemView.mas_bottom).offset(14.0);
        make.left.right.centerX.equalTo(self.mainContainer);
    }];
    [self.musicVolumView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(24.0);
        make.width.equalTo(self.slideContainer.mas_width);
    }];
    [self.personVolumView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(24.0);
        make.width.equalTo(self.slideContainer.mas_width);
    }];
    [self.personPitchView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(24.0);
        make.width.equalTo(self.slideContainer.mas_width);
    }];
    if (self.debugMode) {
        [self.bgmPlayView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(24.0);
            make.width.equalTo(self.slideContainer.mas_width);
        }];
        [self.bgmLoopView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(24.0);
            make.width.equalTo(self.slideContainer.mas_width);
        }];
        [self.bgmRateView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(24.0);
            make.width.equalTo(self.slideContainer.mas_width);
        }];
        [self.localVolumeView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(24.0);
            make.width.equalTo(self.slideContainer.mas_width);
        }];
        [self.remoteVolumeView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(24.0);
            make.width.equalTo(self.slideContainer.mas_width);
        }];
    }
}

- (void)activeConstraintsOfCollectionContainer {
    [self.collectionContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.slideContainer.mas_bottom).offset(30);
        make.left.right.centerX.bottom.equalTo(self.mainContainer);
    }];
    [self.voiceChangeView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(90.0);
        make.width.equalTo(self.mas_width);
    }];
    [self.reverberationView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(90.0);
        make.width.equalTo(self.mas_width);
    }];
}

- (void)activeConstraintsOfMusicSelectView {
    [self.musiceSelectView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self);
        make.height.mas_equalTo(280);
        make.bottom.equalTo(self.mas_bottom);
    }];
}

/// 绑定视图交互
- (void)bindInteraction {
    [self.closeButton addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchUpInside];
    self.musicSelectItemView.delegate = self;
}

/// 设置视图样式
- (void)setupStyle {
    // 切圆角
    UIBezierPath *maskPath  = [UIBezierPath bezierPathWithRoundedRect:self.bounds byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii:CGSizeMake(10, 10)];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame         = self.bounds;
    maskLayer.path          = maskPath.CGPath;
    self.layer.mask         = maskLayer;
}

- (void)initBackgroundColor {
    // 设置背景色
    self.backgroundColor                  = UIColor.clearColor;
    self.mainContainer.backgroundColor    = self.theme.backgroundColor;
    self.musiceSelectView.backgroundColor = self.theme.backgroundColor;
}

#pragma mark - 视图操作响应代理
- (void)didClickItem {
    [self.musiceSelectView show];
}

- (void)didClickPausButton:(BOOL)isPause {
    if (isPause) {
        [self.viewModel pausePlay];
        [self.bgmPlayView setSliderUserInteractionEnabled:false];
    } else {
        [self.viewModel resumePlay];
        [self.bgmPlayView setSliderUserInteractionEnabled:true];
    }
}

- (void)resetMusicButton {
    [self resetBgmSelectItemStatus];
}

- (void)bgmSliderPauseMusic {
    [self.viewModel pausePlay];
}

- (void)bgmSliderResumeMusic {
    [self.viewModel resumePlay];
}

- (void)selectViewChangeState:(TCMusicSelectView *)view {
    self.mainContainer.hidden = !view.isHidden;
}

- (void)didSelectMusic:(TCMusicSelectedModel *)music isSelected:(BOOL)isSelected {
    [self.musicSelectItemView selectMusic:music.musicName];
    self.currentMusic = music;
    [self.bgmPlayView setSliderUserInteractionEnabled:true];
    [self.musiceSelectView hide];
}

- (void)slideItemView:(TCSlideItemView *)view slideValueDidChanged:(CGFloat)value {
    if (view == self.musicVolumView) {
        // 设置音乐音量大小
        [self.viewModel setMusicVolum:value];
        
        self.localVolumeView.defaultValue = value;
        self.remoteVolumeView.defaultValue = value;
        [self slideItemView:self.localVolumeView slideValueDidChanged:value];
        [self slideItemView:self.remoteVolumeView slideValueDidChanged:value];
    }
    else if (view == self.personVolumView) {
        // 设置人声音量大小
        [self.viewModel setVoiceVolum:value];
    }
    else if (view == self.personPitchView) {
        // 设置音调大小
        [self.viewModel setPitchVolum:value];
    }
    else if (view == self.bgmRateView) {
        // 设置BGM速率
        [self.viewModel setBGMRate:value];
    }
    else if (view == self.localVolumeView) {
        // 设置本地音量
        [self.viewModel setLocalVolume:value];
    }
    else if (view == self.remoteVolumeView) {
        // 设置远程音量
        [self.viewModel setRemoteVolume:value];
    }
    else if (view == self.bgmPlayView) {
        // 设置播放进度
        [self.viewModel setProgress:value/100.];
    }
}

- (void)resetAudioSetting {
    [self.viewModel resetStatus];
}

- (void)resetBgmSelectItemStatus {
    [self.viewModel stopPlay];
    [self.musicSelectItemView selectMusic:@""];
    [self.bgmPlayView setSliderUserInteractionEnabled:false];
    [self.bgmPlayView resetProgress];
}

- (void)onPlayingWithCurrent:(NSInteger)currentSec total:(NSInteger)totalSec {
    NSString *currentStr  = [self switchSecondToTimeStr:currentSec];
    NSString *totalString = [self switchSecondToTimeStr:totalSec];
    //防止UI绘制在非主线执行
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.musicSelectItemView refreshMusicPlayingProgress:[NSString stringWithFormat:@"%@/%@", currentStr, totalString]];
        [self.bgmPlayView refreshMusicPlayingProgress:currentSec total:totalSec];
    });
}

- (void)onStopPlayerMusic {
    [self.musicSelectItemView selectMusic:@""];
}

- (void)onCompletePlayMusic {
    if (self.debugMode && self.bgmLoopView_on.isOn && self.currentMusic != nil) {
        self.currentMusic.action(YES);
        [self.musicSelectItemView selectMusic:self.currentMusic.musicName];
        
        [self slideItemView:self.musicVolumView slideValueDidChanged:self.musicVolumView.defaultValue];
    }
    else {
        [self.musicSelectItemView completeStatus];
    }
}

- (NSString *)switchSecondToTimeStr:(NSInteger)secondNum {
    NSInteger min          = secondNum / 60;
    NSString *minString    = min > 9 ? [NSString stringWithFormat:@"%ld", min] : [NSString stringWithFormat:@"0%ld", (long)min];
    NSInteger sec          = secondNum % 60;
    NSString *secondString = sec > 9 ? [NSString stringWithFormat:@"%ld", sec] : [NSString stringWithFormat:@"0%ld", (long)sec];
    return [NSString stringWithFormat:@"%@:%@", minString, secondString];
}

- (BOOL)isShow {
    return _isShow;
}
@end
