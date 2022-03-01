/*
 * Module:   LebSettingsBaseItem, LebSettingsBaseCell
 *
 * Function: 基础框架类。LebSettingsBaseViewController的Cell基类
 *
 *    1. LebSettingsBaseItem用于存储cell中的数据，以及传导cell中的控件action
 *
 *    2. LebSettingsBaseCell定义了左侧的titleLabel，子类中可重载setupUI来添加其它控件
 *
 */

#import "LebSettingsBaseCell.h"

#import "AppLocalized.h"
#import "ColorMacro.h"
#import "Masonry.h"
#import "UIButton+Leb.h"
#import "UILabel+Leb.h"
#import "UISegmentedControl+Leb.h"
#import "UISlider+Leb.h"
#import "UIView+Additions.h"
#import "MBProgressHUD.h"

@interface LebSettingsBaseCell ()

@property(strong, nonatomic) UILabel *titleLabel;

@end

@implementation LebSettingsBaseCell

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

- (void)setItem:(LebSettingsBaseItem *)item {
    _item                = item;
    self.titleLabel.text = item.title;
    [self didUpdateItem:item];
}

#pragma mark - Overridable

- (void)setupUI {
    self.backgroundColor = UIColor.clearColor;

    self.titleLabel = [UILabel leb_titleLabel];
    [self.contentView addSubview:self.titleLabel];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.contentView);
        make.leading.equalTo(self.contentView).offset(18);
    }];
}

- (void)didUpdateItem:(LebSettingsBaseItem *)item {
}

- (void)didSelect {
}

@end

@implementation LebSettingsBaseItem

- (CGFloat)height {
    return 50;
}

+ (Class)bindedCellClass {
    return [LebSettingsBaseCell class];
}

+ (NSString *)bindedCellId {
    return [[self bindedCellClass] description];
}

- (NSString *)bindedCellId {
    return [LebSettingsBaseItem bindedCellId];
}

@end

@interface LebSettingsSwitchCell ()

@property(strong, nonatomic) UISwitch *switcher;

@end

@implementation LebSettingsSwitchCell

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

- (void)didUpdateItem:(LebSettingsBaseItem *)item {
    if ([item isKindOfClass:[LebSettingsSwitchItem class]]) {
        LebSettingsSwitchItem *switchItem = (LebSettingsSwitchItem *)item;
        self.switcher.on                  = switchItem.isOn;
    }
}

- (void)onClickSwitch:(id)sender {
    LebSettingsSwitchItem *switchItem = (LebSettingsSwitchItem *)self.item;
    switchItem.isOn                   = self.switcher.isOn;
    if (switchItem.action) {
        switchItem.action(self.switcher.isOn);
    }
}

@end

@implementation LebSettingsSwitchItem

- (instancetype)initWithTitle:(NSString *)title isOn:(BOOL)isOn action:(void (^_Nullable)(BOOL))action {
    if (self = [super init]) {
        self.title = title;
        _isOn      = isOn;
        _action    = action;
    }
    return self;
}

+ (Class)bindedCellClass {
    return [LebSettingsSwitchCell class];
}

- (NSString *)bindedCellId {
    return [LebSettingsSwitchItem bindedCellId];
}

@end

@interface LebSettingsSliderCell ()

@property(strong, nonatomic) UISlider *         slider;
@property(strong, nonatomic) UILabel *          valueLabel;
@property(strong, nonatomic) NSNumberFormatter *numFormatter;

@end

@implementation LebSettingsSliderCell

- (void)setupUI {
    [super setupUI];

    self.slider = [UISlider leb_slider];
    [self.slider addTarget:self action:@selector(onSliderValueChange:) forControlEvents:UIControlEventValueChanged];
    [self.contentView addSubview:self.slider];

    self.valueLabel                           = [UILabel leb_contentLabel];
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

- (void)didUpdateItem:(LebSettingsBaseItem *)item {
    if ([item isKindOfClass:[LebSettingsSliderItem class]]) {
        LebSettingsSliderItem *sliderItem = (LebSettingsSliderItem *)item;
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
        LebSettingsSliderItem *item = (LebSettingsSliderItem *)self.item;
        if (0 == item.step) item.step = 1.f;
        self.slider.value    = item.sliderValue / item.step;
        self.valueLabel.text = [self.numFormatter stringFromNumber:@(item.sliderValue)];
    }
}

- (void)onSliderValueChange:(UISlider *)slider {
    LebSettingsSliderItem *sliderItem = (LebSettingsSliderItem *)self.item;
    float                  value      = slider.value * sliderItem.step;

    self.valueLabel.text   = [self.numFormatter stringFromNumber:@(value)];
    sliderItem.sliderValue = value;
    sliderItem.action(value);
}

@end

@implementation LebSettingsSliderItem

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
    return [LebSettingsSliderCell class];
}

- (NSString *)bindedCellId {
    return [LebSettingsSliderItem bindedCellId];
}

@end

@interface LebSettingsSegmentCell ()

@property(strong, nonatomic) UISegmentedControl *segment;

@end

@implementation LebSettingsSegmentCell

- (void)setupUI {
    [super setupUI];

    self.segment = [UISegmentedControl leb_segment];
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

- (void)didUpdateItem:(LebSettingsBaseItem *)item {
    if ([item isKindOfClass:[LebSettingsSegmentItem class]]) {
        LebSettingsSegmentItem *segmentItem = (LebSettingsSegmentItem *)item;
        [self.segment removeAllSegments];
        [segmentItem.items enumerateObjectsUsingBlock:^(NSString *_Nonnull item, NSUInteger idx, BOOL *_Nonnull stop) {
            [self.segment insertSegmentWithTitle:item atIndex:idx animated:NO];
        }];
        self.segment.selectedSegmentIndex = segmentItem.selectedIndex;
    }
}

- (void)onSegmentChange:(id)sender {
    LebSettingsSegmentItem *segmentItem = (LebSettingsSegmentItem *)self.item;
    segmentItem.selectedIndex           = self.segment.selectedSegmentIndex;
    if (segmentItem.action) {
        segmentItem.action(self.segment.selectedSegmentIndex);
    }
}

@end

@interface                        LebSettingsSegmentItem ()
@property(assign, nonatomic) BOOL singleRow;
@end

@implementation LebSettingsSegmentItem

- (instancetype)initWithTitle:(NSString *)title items:(NSArray<NSString *> *)items selectedIndex:(NSInteger)index action:(void (^_Nullable)(NSInteger index))action {
    if (self = [super init]) {
        self.title                         = title;
        _items                             = items;
        _selectedIndex                     = index;
        _action                            = action;
        UISegmentedControl *segmentControl = [[UISegmentedControl alloc] initWithItems:items];
        [segmentControl leb_setupApperance];
        [segmentControl sizeToFit];
        CGSize size = segmentControl.frame.size;
        _singleRow  = size.width < [UIScreen mainScreen].bounds.size.width * 0.66666;
    }
    return self;
}

+ (Class)bindedCellClass {
    return [LebSettingsSegmentCell class];
}

- (CGFloat)height {
    return _singleRow ? [super height] : 70;
}

- (NSString *)bindedCellId {
    return [LebSettingsSegmentItem bindedCellId];
}

@end

@interface LebSettingsSelectorCell ()

@property(strong, nonatomic) UILabel *itemLabel;

@end

@implementation LebSettingsSelectorCell

- (void)setupUI {
    [super setupUI];

    self.itemLabel = [UILabel leb_contentLabel];
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

- (void)didUpdateItem:(LebSettingsBaseItem *)item {
    if ([item isKindOfClass:[LebSettingsSelectorItem class]]) {
        LebSettingsSelectorItem *selectorItem = (LebSettingsSelectorItem *)item;
        if (selectorItem.selectedIndex < selectorItem.items.count) {
            self.itemLabel.text = selectorItem.items[selectorItem.selectedIndex];
        }
    }
}

- (void)didSelect {
    LebSettingsSelectorItem *selectorItem = (LebSettingsSelectorItem *)self.item;

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
    LebSettingsSelectorItem *selectorItem = (LebSettingsSelectorItem *)self.item;
    NSInteger                index        = [selectorItem.items indexOfObject:item];
    if (index != NSNotFound) {
        selectorItem.selectedIndex = index;
        selectorItem.action(index);
    }
}

@end

@implementation LebSettingsSelectorItem

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
    return [LebSettingsSelectorCell class];
}

- (NSString *)bindedCellId {
    return [LebSettingsSelectorItem bindedCellId];
}

@end

@interface LebSettingsButtonCell ()

@property(strong, nonatomic) UIButton *button;

@end

@implementation LebSettingsButtonCell

- (void)setupUI {
    [super setupUI];

    self.button = [UIButton leb_cellButtonWithTitle:TRTCLocalize(@"Demo.TRTC.Live.send")];
    [self.button addTarget:self action:@selector(onClickSendButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.button];
    [self.button mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.contentView);
        make.trailing.equalTo(self.contentView).offset(-18);
    }];
}

- (void)didUpdateItem:(LebSettingsBaseItem *)item {
    if ([item isKindOfClass:[LebSettingsButtonItem class]]) {
        LebSettingsButtonItem *buttonItem = (LebSettingsButtonItem *)item;
        [self.button setTitle:buttonItem.buttonTitle forState:UIControlStateNormal];
    }
}

- (void)onClickSendButton:(id)sender {
    LebSettingsButtonItem *buttonItem = (LebSettingsButtonItem *)self.item;
    buttonItem.action();
}

@end

@implementation LebSettingsButtonItem

- (instancetype)initWithTitle:(NSString *)title buttonTitle:(NSString *)buttonTitle action:(void (^)())action {
    if (self = [super init]) {
        self.title   = title;
        _buttonTitle = buttonTitle;
        _action      = action;
    }
    return self;
}

+ (Class)bindedCellClass {
    return [LebSettingsButtonCell class];
}

- (NSString *)bindedCellId {
    return [LebSettingsButtonItem bindedCellId];
}

@end


@interface LebSettingsTextFieldCell () <UITextFieldDelegate>

@property(strong, nonatomic) UISwitch *switcher;
@property(strong, nonatomic) UITextField *text;

@end

@implementation LebSettingsTextFieldCell

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
    
    self.text = [self createTextFieldWithDelegate:self];
    [self.contentView addSubview:self.text];
    [self.text mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.contentView);
        make.height.mas_equalTo(32);
        make.width.mas_equalTo(64);
        make.left.equalTo(self.titleLabel.mas_right);
    }];
}

- (void)didUpdateItem:(LebSettingsBaseItem *)item {
    if ([item isKindOfClass:[LebSettingsSwitchItem class]]) {
        LebSettingsSwitchItem *switchItem = (LebSettingsSwitchItem *)item;
        self.switcher.on                  = switchItem.isOn;
    }
}

- (void)onClickSwitch:(id)sender {
    [self.contentView endEditing:YES];
    LebSettingsTextFieldItem *switchItem = (LebSettingsTextFieldItem *)self.item;
    switchItem.isOn                   = self.switcher.isOn;
    if (switchItem.action) {
        NSInteger type = [self.text.text integerValue];
        if (self.switcher.isOn) {
            if (type != 5 && type != 242) {
                switchItem.isOn = NO;
                [self.switcher setOn:NO animated:YES];
                [self showText:V2Localize(@"V2.Live.LinkMicNew.seipayloadtypeinvalid")];
                return;
            }
        }
        switchItem.action(switchItem.isOn , type);
    }
}

- (UITextField *)createTextFieldWithDelegate:(id<UITextFieldDelegate>)delegate {
    UITextField *textField    = [[UITextField alloc] init];
    textField.borderStyle     = UITextBorderStyleRoundedRect;
    textField.textColor       = [UIColor blackColor];
    textField.font            = [UIFont systemFontOfSize:15];
    textField.keyboardType    = UIKeyboardTypeNumberPad;
    textField.delegate        = delegate;
    return textField;
}

- (void)showText:(NSString *)text {
    UIView *view = [UIApplication sharedApplication].delegate.window;
    MBProgressHUD *hud = [MBProgressHUD HUDForView:view];
    if (hud == nil) {
        hud = [MBProgressHUD showHUDAddedTo:view animated:NO];
    }
    hud.mode              = MBProgressHUDModeText;
    hud.label.text        = text;
    hud.label.numberOfLines = 0;
    hud.detailsLabel.text = nil;
    [hud showAnimated:YES];
    [hud hideAnimated:YES afterDelay:2];
}



#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    return YES;
}

@end

@implementation LebSettingsTextFieldItem

- (instancetype)initWithTitle:(NSString *)title isOn:(BOOL)isOn action:(void (^_Nullable)(BOOL, NSInteger))action{
    if (self = [super init]) {
        self.title = title;
        _isOn      = isOn;
        _action    = action;
    }
    return self;
}

+ (Class)bindedCellClass {
    return [LebSettingsTextFieldCell class];
}

- (NSString *)bindedCellId {
    return [LebSettingsTextFieldItem bindedCellId];
}

@end
