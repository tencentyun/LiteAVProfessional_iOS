/*
 * Module:   RTCSettingsBaseItem, RTCSettingsBaseCell
 *
 * Function: 基础框架类。RTCSettingsBaseViewController的Cell基类
 *
 *    1. RTCSettingsBaseItem用于存储cell中的数据，以及传导cell中的控件action
 *
 *    2. RTCSettingsBaseCell定义了左侧的titleLabel，子类中可重载setupUI来添加其它控件
 *
 */

#import "RTCSettingsBaseCell.h"

#import "AppLocalized.h"
#import "ColorMacro.h"
#import "Masonry.h"
#import "UIButton+RTC.h"
#import "UILabel+RTC.h"
#import "UISegmentedControl+RTC.h"
#import "UISlider+RTC.h"
#import "UIView+Additions.h"

@interface RTCSettingsBaseCell ()

@property(strong, nonatomic) UILabel *titleLabel;

@end

@implementation RTCSettingsBaseCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        [self setupUI];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self setupUI];
    }
    return self;
}

- (void)setItem:(RTCSettingsBaseItem *)item {
    _item                = item;
    self.titleLabel.text = item.title;
    [self didUpdateItem:item];
}

#pragma mark - Overridable

- (void)setupUI {
    self.backgroundColor = UIColor.clearColor;

    self.titleLabel = [UILabel rtc_titleLabel];
    [self.contentView addSubview:self.titleLabel];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.contentView);
        make.leading.equalTo(self.contentView).offset(18);
    }];
}

- (void)didUpdateItem:(RTCSettingsBaseItem *)item {
}

- (void)didSelect {
}

@end

@implementation RTCSettingsBaseItem

- (CGFloat)height {
    return 50;
}

+ (Class)bindedCellClass {
    return [RTCSettingsBaseCell class];
}

+ (NSString *)bindedCellId {
    return [[self bindedCellClass] description];
}

- (NSString *)bindedCellId {
    return [RTCSettingsBaseItem bindedCellId];
}

@end

@interface RTCSettingsSwitchCell ()

@property(nonatomic, strong) UISwitch *switcher;

@end

@implementation RTCSettingsSwitchCell

- (void)setupUI {
    [super setupUI];

    self.switcher = [[UISwitch alloc] init];
    [self.switcher addTarget:self action:@selector(onClickSwitch:) forControlEvents:UIControlEventValueChanged];
    self.switcher.onTintColor = UIColorFromRGB(0x05a764);

    [self.contentView addSubview:self.switcher];
    [self.switcher mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.contentView);
        make.trailing.equalTo(self.contentView).offset(-18);
    }];
}

- (void)didUpdateItem:(RTCSettingsBaseItem *)item {
    if ([item isKindOfClass:[RTCSettingsSwitchItem class]]) {
        RTCSettingsSwitchItem *switchItem = (RTCSettingsSwitchItem *)item;
        self.switcher.on                  = switchItem.isOn;
    }
}

- (void)onClickSwitch:(id)sender {
    RTCSettingsSwitchItem *switchItem = (RTCSettingsSwitchItem *)self.item;
    switchItem.isOn                   = self.switcher.isOn;
    if (switchItem.action) {
        switchItem.action(self.switcher.isOn);
    }
}

@end

@implementation RTCSettingsSwitchItem

- (instancetype)initWithTitle:(NSString *)title isOn:(BOOL)isOn action:(void (^_Nullable)(BOOL))action {
    if (self = [super init]) {
        self.title = title;
        _isOn      = isOn;
        _action    = action;
    }
    return self;
}

+ (Class)bindedCellClass {
    return [RTCSettingsSwitchCell class];
}

- (NSString *)bindedCellId {
    return [RTCSettingsSwitchItem bindedCellId];
}

@end

@interface RTCSettingsSliderCell ()

@property(strong, nonatomic) UISlider *         slider;
@property(strong, nonatomic) UILabel *          valueLabel;
@property(strong, nonatomic) NSNumberFormatter *numFormatter;

@end

@implementation RTCSettingsSliderCell

- (void)setupUI {
    [super setupUI];

    self.slider = [UISlider rtc_slider];
    [self.slider addTarget:self action:@selector(onSliderValueChange:) forControlEvents:UIControlEventValueChanged];
    [self.contentView addSubview:self.slider];

    self.valueLabel                           = [UILabel rtc_contentLabel];
    self.valueLabel.textAlignment             = NSTextAlignmentRight;
    self.valueLabel.adjustsFontSizeToFitWidth = YES;
    [self.contentView addSubview:self.valueLabel];

    [self.slider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.contentView);
        make.trailing.equalTo(self.valueLabel.mas_leading).offset(-5);
        make.width.mas_equalTo(160);
    }];

    [self.valueLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.contentView);
        make.trailing.equalTo(self.contentView).offset(-18);
        make.width.mas_equalTo(36);
    }];

    self.numFormatter                       = [[NSNumberFormatter alloc] init];
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

- (void)didUpdateItem:(RTCSettingsBaseItem *)item {
    if ([item isKindOfClass:[RTCSettingsSliderItem class]]) {
        RTCSettingsSliderItem *sliderItem = (RTCSettingsSliderItem *)item;
        if (0 == sliderItem.step) sliderItem.step = 1.f;
        self.slider.minimumValue = sliderItem.minValue / sliderItem.step;
        self.slider.maximumValue = sliderItem.maxValue / sliderItem.step;
        self.slider.value        = sliderItem.sliderValue / sliderItem.step;
        self.slider.continuous   = sliderItem.continuous;
        self.valueLabel.text     = [self.numFormatter stringFromNumber:@(sliderItem.sliderValue)];
    }

    [item addObserver:self forKeyPath:@"sliderValue" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey, id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"sliderValue"]) {
        RTCSettingsSliderItem *item = (RTCSettingsSliderItem *)self.item;
        if (0 == item.step) item.step = 1.f;
        self.slider.value    = item.sliderValue / item.step;
        self.valueLabel.text = [self.numFormatter stringFromNumber:@(item.sliderValue)];
    }
}

- (void)onSliderValueChange:(UISlider *)slider {
    RTCSettingsSliderItem *sliderItem = (RTCSettingsSliderItem *)self.item;
    float                  value      = slider.value * sliderItem.step;

    self.valueLabel.text   = [self.numFormatter stringFromNumber:@(value)];
    sliderItem.sliderValue = value;
    sliderItem.action(value);
}

@end

@implementation RTCSettingsSliderItem

- (instancetype)initWithTitle:(NSString *)title value:(float)value min:(float)min max:(float)max step:(float)step continuous:(BOOL)continuous action:(void (^)(float))action {
    if (self = [super init]) {
        self.title   = title;
        _sliderValue = value;
        _minValue    = min;
        _maxValue    = max;
        _step        = step == 0 ? 1 : step;
        _continuous  = continuous;
        _action      = action;
    }
    return self;
}

+ (Class)bindedCellClass {
    return [RTCSettingsSliderCell class];
}

- (NSString *)bindedCellId {
    return [RTCSettingsSliderItem bindedCellId];
}

@end

@interface RTCSettingsSegmentCell ()

@property(strong, nonatomic) UISegmentedControl *segment;

@end

@implementation RTCSettingsSegmentCell

- (void)setupUI {
    [super setupUI];

    self.segment = [UISegmentedControl rtc_segment];
    [self.segment addTarget:self action:@selector(onSegmentChange:) forControlEvents:UIControlEventValueChanged];

    [self.contentView addSubview:self.segment];
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(9);
        make.top.equalTo(self.contentView).offset(15);
    }];
    [self.segment mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.contentView).offset(-9);
        make.bottom.equalTo(self.contentView).offset(-9);
    }];
}

- (void)didUpdateItem:(RTCSettingsBaseItem *)item {
    if ([item isKindOfClass:[RTCSettingsSegmentItem class]]) {
        RTCSettingsSegmentItem *segmentItem = (RTCSettingsSegmentItem *)item;
        [self.segment removeAllSegments];
        [segmentItem.items enumerateObjectsUsingBlock:^(NSString *_Nonnull item, NSUInteger idx, BOOL *_Nonnull stop) {
            [self.segment insertSegmentWithTitle:item atIndex:idx animated:NO];
        }];
        self.segment.selectedSegmentIndex = segmentItem.selectedIndex;
    }
}

- (void)onSegmentChange:(id)sender {
    RTCSettingsSegmentItem *segmentItem = (RTCSettingsSegmentItem *)self.item;
    segmentItem.selectedIndex           = self.segment.selectedSegmentIndex;
    if (segmentItem.action) {
        segmentItem.action(self.segment.selectedSegmentIndex);
    }
}

@end

@interface RTCSettingsSegmentItem ()

@property(nonatomic, assign) BOOL singleRow;

@end

@implementation RTCSettingsSegmentItem

- (instancetype)initWithTitle:(NSString *)title items:(NSArray<NSString *> *)items selectedIndex:(NSInteger)index action:(void (^_Nullable)(NSInteger index))action {
    if (self = [super init]) {
        self.title                         = title;
        _items                             = items;
        _selectedIndex                     = index;
        _action                            = action;
        UISegmentedControl *segmentControl = [[UISegmentedControl alloc] initWithItems:items];
        [segmentControl rtc_setupApperance];
        [segmentControl sizeToFit];
        CGSize size = segmentControl.frame.size;
        _singleRow  = size.width < [UIScreen mainScreen].bounds.size.width * 0.66666;
    }
    return self;
}

+ (Class)bindedCellClass {
    return [RTCSettingsSegmentCell class];
}

- (CGFloat)height {
    return _singleRow ? [super height] : 70;
}

- (NSString *)bindedCellId {
    return [RTCSettingsSegmentItem bindedCellId];
}

@end

@interface RTCSettingsSelectorCell ()

@property(nonatomic, strong) UILabel *itemLabel;

@end

@implementation RTCSettingsSelectorCell

- (void)setupUI {
    [super setupUI];

    self.itemLabel = [UILabel rtc_contentLabel];
    [self.contentView addSubview:self.itemLabel];

    UIImageView *arrowView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"arrow"]];
    [self.contentView addSubview:arrowView];

    [self.itemLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.contentView);
        make.trailing.equalTo(arrowView).offset(-20);
    }];
    [arrowView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.contentView);
        make.trailing.equalTo(self.contentView).offset(-18);
    }];

    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didSelect)];
    [self.contentView addGestureRecognizer:tapGesture];
}

- (void)didUpdateItem:(RTCSettingsBaseItem *)item {
    if ([item isKindOfClass:[RTCSettingsSelectorItem class]]) {
        RTCSettingsSelectorItem *selectorItem = (RTCSettingsSelectorItem *)item;
        if (selectorItem.selectedIndex < selectorItem.items.count) {
            self.itemLabel.text = selectorItem.items[selectorItem.selectedIndex];
        }
    }
}

- (void)didSelect {
    RTCSettingsSelectorItem *selectorItem = (RTCSettingsSelectorItem *)self.item;

    void (^actionHandler)(UIAlertAction *_Nonnull action) = ^(UIAlertAction *_Nonnull action) {
        self.itemLabel.text = action.title;
        [self onSelectItem:action.title];
    };
    UIAlertControllerStyle style = UIAlertControllerStyleActionSheet;
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        style = UIAlertControllerStyleAlert;
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:selectorItem.title message:nil preferredStyle:style];
    for (NSString *item in selectorItem.items) {
        [alert addAction:[UIAlertAction actionWithTitle:item style:UIAlertActionStyleDefault handler:actionHandler]];
    }
    [alert addAction:[UIAlertAction actionWithTitle:V2Localize(@"V2.Live.LinkMicNew.cancel") style:UIAlertActionStyleCancel handler:nil]];

    [self.tx_viewController presentViewController:alert animated:YES completion:nil];
}

- (void)onSelectItem:(NSString *)item {
    RTCSettingsSelectorItem *selectorItem = (RTCSettingsSelectorItem *)self.item;
    NSInteger                index        = [selectorItem.items indexOfObject:item];
    if (index != NSNotFound) {
        selectorItem.selectedIndex = index;
        selectorItem.action(index);
    }
}

@end

@implementation RTCSettingsSelectorItem

- (instancetype)initWithTitle:(NSString *)title items:(NSArray<NSString *> *)items selectedIndex:(NSInteger)index action:(void (^)(NSInteger))action {
    if (self = [super init]) {
        self.title     = title;
        _items         = items;
        _selectedIndex = index;
        _action        = action;
    }
    return self;
}

+ (Class)bindedCellClass {
    return [RTCSettingsSelectorCell class];
}

- (NSString *)bindedCellId {
    return [RTCSettingsSelectorItem bindedCellId];
}

@end

@interface RTCSettingsButtonCell ()

@property(nonatomic, strong) UIButton *button;

@end

@implementation RTCSettingsButtonCell

- (void)setupUI {
    [super setupUI];

    self.button = [UIButton rtc_cellButtonWithTitle:TRTCLocalize(@"Demo.TRTC.Live.send")];
    [self.button addTarget:self action:@selector(onClickSendButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.button];
    [self.button mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.contentView);
        make.trailing.equalTo(self.contentView).offset(-18);
    }];
}

- (void)didUpdateItem:(RTCSettingsBaseItem *)item {
    if ([item isKindOfClass:[RTCSettingsButtonItem class]]) {
        RTCSettingsButtonItem *buttonItem = (RTCSettingsButtonItem *)item;
        [self.button setTitle:buttonItem.buttonTitle forState:UIControlStateNormal];
    }
}

- (void)onClickSendButton:(id)sender {
    RTCSettingsButtonItem *buttonItem = (RTCSettingsButtonItem *)self.item;
    buttonItem.action();
}

@end

@implementation RTCSettingsButtonItem

- (instancetype)initWithTitle:(NSString *)title buttonTitle:(NSString *)buttonTitle action:(void (^)())action {
    if (self = [super init]) {
        self.title   = title;
        _buttonTitle = buttonTitle;
        _action      = action;
    }
    return self;
}

+ (Class)bindedCellClass {
    return [RTCSettingsButtonCell class];
}

- (NSString *)bindedCellId {
    return [RTCSettingsButtonItem bindedCellId];
}

@end
