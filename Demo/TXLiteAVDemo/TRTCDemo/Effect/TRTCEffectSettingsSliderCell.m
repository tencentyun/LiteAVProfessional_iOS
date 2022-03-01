/*
* Module:   TRTCSettingsSliderCell
*
* Function: 配置列表Cell，右侧是一个Slider
*
*/

#import "TRTCEffectSettingsSliderCell.h"
#import "Masonry.h"
#import "ColorMacro.h"
#import "UIImage+Additions.h"

@interface TRTCEffectSettingsSliderCell ()

@property (strong, nonatomic) UISlider *slider;
@property (strong, nonatomic) UILabel *valueLabel;
@property (strong, nonatomic) NSNumberFormatter *numFormatter;

@end

@implementation TRTCEffectSettingsSliderCell

- (void)setupUI {
    [super setupUI];
    self.slider = [[UISlider alloc] init];
    self.slider.minimumTrackTintColor = UIColorFromRGB(0x05a764);
    UIImage *icon = [UIImage imageWithColor:UIColorFromRGB(0x05a764)
                                       size:CGSizeMake(18, 18)
                                cornerInset:UICornerInsetMake(9, 9, 9, 9)];
    [self.slider setThumbImage:icon forState:UIControlStateNormal];
    [self.slider addTarget:self action:@selector(onSliderValueChange:) forControlEvents:UIControlEventValueChanged];
    [self.contentView addSubview:self.slider];

    self.valueLabel = [[UILabel alloc] init];
    self.valueLabel.font = [UIFont systemFontOfSize:15];
    self.valueLabel.textColor = UIColorFromRGB(0x939393);
    self.valueLabel.textAlignment = NSTextAlignmentRight;
    self.valueLabel.adjustsFontSizeToFitWidth = YES;
    [self.contentView addSubview:self.valueLabel];

    [self.slider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.contentView);
        make.trailing.equalTo(self.valueLabel.mas_leading).offset(-5);
        make.width.mas_equalTo(180);
    }];
    
    [self.valueLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.contentView);
        make.trailing.equalTo(self.contentView).offset(-18);
        make.width.mas_equalTo(36);
    }];
    
    self.numFormatter = [[NSNumberFormatter alloc] init];
    self.numFormatter.minimumFractionDigits = 0;
    self.numFormatter.maximumFractionDigits = 1;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self.item removeObserver:self forKeyPath:@"sliderValue"];
}

- (void)dealloc {
    [self.item removeObserver:self forKeyPath:@"sliderValue"];
}

- (void)didUpdateItem:(TRTCEffectSettingsBaseItem *)item {
    if ([item isKindOfClass:[TRTCEffectSettingsSliderItem class]]) {
        TRTCEffectSettingsSliderItem *sliderItem = (TRTCEffectSettingsSliderItem *)item;
        if (0 == sliderItem.step) sliderItem.step = 1.f;
        self.slider.minimumValue = sliderItem.minValue / sliderItem.step;
        self.slider.maximumValue = sliderItem.maxValue / sliderItem.step;
        self.slider.value = sliderItem.sliderValue / sliderItem.step;
        self.slider.continuous = sliderItem.continuous;
        self.valueLabel.text = [self.numFormatter stringFromNumber:@(sliderItem.sliderValue)];
    }
    
    [item addObserver:self forKeyPath:@"sliderValue" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"sliderValue"]) {
        TRTCEffectSettingsSliderItem *item = (TRTCEffectSettingsSliderItem *) self.item;
        if (0 == item.step) item.step = 1.f;
        self.slider.value = item.sliderValue / item.step;
        self.valueLabel.text = [self.numFormatter stringFromNumber:@(item.sliderValue)];
    }
}

- (void)onSliderValueChange:(UISlider *)slider {
    TRTCEffectSettingsSliderItem *sliderItem = (TRTCEffectSettingsSliderItem *)self.item;
    float value = slider.value * sliderItem.step;
    
    self.valueLabel.text = [self.numFormatter stringFromNumber:@(value)];
    sliderItem.sliderValue = value;
    sliderItem.action(value);
}

@end


@implementation TRTCEffectSettingsSliderItem

- (instancetype)initWithTitle:(NSString *)title
                        value:(float)value
                          min:(float)min
                          max:(float)max
                         step:(float)step
                   continuous:(BOOL)continuous
                       action:(void (^)(float))action {
    if (self = [super init]) {
        self.title = title;
        _sliderValue = value;
        _minValue = min;
        _maxValue = max;
        _step = step == 0 ? 1 : step;
        _continuous = continuous;
        _action = action;
    }
    return self;
}

+ (Class)bindedCellClass {
    return [TRTCEffectSettingsSliderCell class];
}

- (NSString *)bindedCellId {
    return [TRTCEffectSettingsSliderItem bindedCellId];
}

@end

