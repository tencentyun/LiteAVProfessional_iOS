/*
 * Module:   V2SettingsBaseItem, V2SettingsBaseCell
 *
 * Function: 基础框架类。V2SettingsBaseViewController的Cell基类
 *
 *    1. V2SettingsBaseItem用于存储cell中的数据，以及传导cell中的控件action
 *
 *    2. V2SettingsBaseCell定义了左侧的titleLabel，子类中可重载setupUI来添加其它控件
 *
 */

#import "V2SettingsBaseCell.h"

#import "AppLocalized.h"
#import "ColorMacro.h"
#import "Masonry.h"
#import "UIButton+V2.h"
#import "UILabel+V2.h"
#import "UISegmentedControl+V2.h"
#import "UISlider+V2.h"
#import "UITextField+V2.h"
#import "UIView+Additions.h"

@interface V2SettingsBaseCell ()

@property(strong, nonatomic) UILabel *titleLabel;

@end

@implementation V2SettingsBaseCell

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

- (void)setItem:(V2SettingsBaseItem *)item {
    _item                = item;
    self.titleLabel.text = item.title;
    [self didUpdateItem:item];
}

#pragma mark - Overridable

- (void)setupUI {
    self.backgroundColor = UIColor.clearColor;

    self.titleLabel = [UILabel v2_titleLabel];
    [self.contentView addSubview:self.titleLabel];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.contentView);
        make.leading.equalTo(self.contentView).offset(18);
    }];
}

- (void)didUpdateItem:(V2SettingsBaseItem *)item {
}

- (void)didSelect {
}

@end

@implementation V2SettingsBaseItem

- (CGFloat)height {
    return 50;
}

+ (Class)bindedCellClass {
    return [V2SettingsBaseCell class];
}

+ (NSString *)bindedCellId {
    return [[self bindedCellClass] description];
}

- (NSString *)bindedCellId {
    return [V2SettingsBaseItem bindedCellId];
}

@end

@interface V2SettingsSwitchCell ()

@property(strong, nonatomic) UISwitch *switcher;

@end

@implementation V2SettingsSwitchCell

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

- (void)didUpdateItem:(V2SettingsBaseItem *)item {
    if ([item isKindOfClass:[V2SettingsSwitchItem class]]) {
        V2SettingsSwitchItem *switchItem = (V2SettingsSwitchItem *)item;
        self.switcher.on                 = switchItem.isOn;
    }
}

- (void)onClickSwitch:(id)sender {
    V2SettingsSwitchItem *switchItem = (V2SettingsSwitchItem *)self.item;
    switchItem.isOn                  = self.switcher.isOn;
    if (switchItem.action) {
        switchItem.action(self.switcher.isOn);
    }
}

@end

@implementation V2SettingsSwitchItem

- (instancetype)initWithTitle:(NSString *)title isOn:(BOOL)isOn action:(void (^_Nullable)(BOOL))action {
    if (self = [super init]) {
        self.title = title;
        _isOn      = isOn;
        _action    = action;
    }
    return self;
}

+ (Class)bindedCellClass {
    return [V2SettingsSwitchCell class];
}

- (NSString *)bindedCellId {
    return [V2SettingsSwitchItem bindedCellId];
}

@end

@interface V2SettingsSliderCell ()

@property(strong, nonatomic) UISlider *         slider;
@property(strong, nonatomic) UILabel *          valueLabel;
@property(strong, nonatomic) NSNumberFormatter *numFormatter;

@end

@implementation V2SettingsSliderCell

- (void)setupUI {
    [super setupUI];

    self.slider = [UISlider v2_slider];
    [self.slider addTarget:self action:@selector(onSliderValueChange:) forControlEvents:UIControlEventValueChanged];
    [self.contentView addSubview:self.slider];

    self.valueLabel                           = [UILabel v2_contentLabel];
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

- (void)didUpdateItem:(V2SettingsBaseItem *)item {
    if ([item isKindOfClass:[V2SettingsSliderItem class]]) {
        V2SettingsSliderItem *sliderItem = (V2SettingsSliderItem *)item;
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
        V2SettingsSliderItem *item = (V2SettingsSliderItem *)self.item;
        if (0 == item.step) item.step = 1.f;
        self.slider.value    = item.sliderValue / item.step;
        self.valueLabel.text = [self.numFormatter stringFromNumber:@(item.sliderValue)];
    }
}

- (void)onSliderValueChange:(UISlider *)slider {
    V2SettingsSliderItem *sliderItem = (V2SettingsSliderItem *)self.item;
    float                 value      = slider.value * sliderItem.step;

    self.valueLabel.text   = [self.numFormatter stringFromNumber:@(value)];
    sliderItem.sliderValue = value;
    sliderItem.action(value);
}

@end

@implementation V2SettingsSliderItem

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
    return [V2SettingsSliderCell class];
}

- (NSString *)bindedCellId {
    return [V2SettingsSliderItem bindedCellId];
}

@end

@interface V2SettingsSegmentCell ()

@property(strong, nonatomic) UISegmentedControl *segment;

@end

@implementation V2SettingsSegmentCell

- (void)setupUI {
    [super setupUI];

    self.segment = [UISegmentedControl v2_segment];
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

- (void)didUpdateItem:(V2SettingsBaseItem *)item {
    if ([item isKindOfClass:[V2SettingsSegmentItem class]]) {
        V2SettingsSegmentItem *segmentItem = (V2SettingsSegmentItem *)item;
        [self.segment removeAllSegments];
        [segmentItem.items enumerateObjectsUsingBlock:^(NSString *_Nonnull item, NSUInteger idx, BOOL *_Nonnull stop) {
            [self.segment insertSegmentWithTitle:item atIndex:idx animated:NO];
        }];
        self.segment.selectedSegmentIndex = segmentItem.selectedIndex;
    }
}

- (void)onSegmentChange:(id)sender {
    V2SettingsSegmentItem *segmentItem = (V2SettingsSegmentItem *)self.item;
    segmentItem.selectedIndex          = self.segment.selectedSegmentIndex;
    if (segmentItem.action) {
        segmentItem.action(self.segment.selectedSegmentIndex);
    }
}

@end

@interface                        V2SettingsSegmentItem ()
@property(assign, nonatomic) BOOL singleRow;
@end

@implementation V2SettingsSegmentItem

- (instancetype)initWithTitle:(NSString *)title items:(NSArray<NSString *> *)items selectedIndex:(NSInteger)index action:(void (^_Nullable)(NSInteger index))action {
    if (self = [super init]) {
        self.title                         = title;
        _items                             = items;
        _selectedIndex                     = index;
        _action                            = action;
        UISegmentedControl *segmentControl = [[UISegmentedControl alloc] initWithItems:items];
        [segmentControl v2_setupApperance];
        [segmentControl sizeToFit];
        CGSize size = segmentControl.frame.size;
        _singleRow  = size.width < [UIScreen mainScreen].bounds.size.width * 0.66666;
    }
    return self;
}

+ (Class)bindedCellClass {
    return [V2SettingsSegmentCell class];
}

- (CGFloat)height {
    return _singleRow ? [super height] : 70;
}

- (NSString *)bindedCellId {
    return [V2SettingsSegmentItem bindedCellId];
}

@end

@interface V2SettingsSelectorCell ()

@property(strong, nonatomic) UILabel *itemLabel;

@end

@implementation V2SettingsSelectorCell

- (void)setupUI {
    [super setupUI];

    self.itemLabel = [UILabel v2_contentLabel];
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

- (void)didUpdateItem:(V2SettingsBaseItem *)item {
    if ([item isKindOfClass:[V2SettingsSelectorItem class]]) {
        V2SettingsSelectorItem *selectorItem = (V2SettingsSelectorItem *)item;
        if (selectorItem.selectedIndex < selectorItem.items.count) {
            self.itemLabel.text = selectorItem.items[selectorItem.selectedIndex];
        }
    }
}

- (void)didSelect {
    V2SettingsSelectorItem *selectorItem = (V2SettingsSelectorItem *)self.item;

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
    V2SettingsSelectorItem *selectorItem = (V2SettingsSelectorItem *)self.item;
    NSInteger               index        = [selectorItem.items indexOfObject:item];
    if (index != NSNotFound) {
        selectorItem.selectedIndex = index;
        selectorItem.action(index);
    }
}

@end

@implementation V2SettingsSelectorItem

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
    return [V2SettingsSelectorCell class];
}

- (NSString *)bindedCellId {
    return [V2SettingsSelectorItem bindedCellId];
}

@end

@interface V2SettingsButtonCell ()

@property(strong, nonatomic) UIButton *button;

@end

@implementation V2SettingsButtonCell

- (void)setupUI {
    [super setupUI];

    self.button = [UIButton v2_cellButtonWithTitle:TRTCLocalize(@"Demo.TRTC.Live.send")];
    [self.button addTarget:self action:@selector(onClickSendButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.button];
    [self.button mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.contentView);
        make.trailing.equalTo(self.contentView).offset(-18);
    }];
}

- (void)didUpdateItem:(V2SettingsBaseItem *)item {
    if ([item isKindOfClass:[V2SettingsButtonItem class]]) {
        V2SettingsButtonItem *buttonItem = (V2SettingsButtonItem *)item;
        [self.button setTitle:buttonItem.buttonTitle forState:UIControlStateNormal];
    }
}

- (void)onClickSendButton:(id)sender {
    V2SettingsButtonItem *buttonItem = (V2SettingsButtonItem *)self.item;
    buttonItem.action();
}

@end

@implementation V2SettingsButtonItem

- (instancetype)initWithTitle:(NSString *)title buttonTitle:(NSString *)buttonTitle action:(void (^)())action {
    if (self = [super init]) {
        self.title   = title;
        _buttonTitle = buttonTitle;
        _action      = action;
    }
    return self;
}

+ (Class)bindedCellClass {
    return [V2SettingsButtonCell class];
}

- (NSString *)bindedCellId {
    return [V2SettingsButtonItem bindedCellId];
}

@end

@interface V2SettingsMessageCell () <UITextFieldDelegate>

@property(strong, nonatomic) UITextField *messageText;
@property(strong, nonatomic) UIButton *   sendButton;

@end

@implementation V2SettingsMessageCell

- (void)setupUI {
    [super setupUI];

    self.sendButton = [UIButton v2_cellButtonWithTitle:@"发送"];
    [self.sendButton addTarget:self action:@selector(onClickSendButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.sendButton];
    [self.sendButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.contentView);
        make.trailing.equalTo(self.contentView).offset(-18);
    }];

    self.messageText = [UITextField v2_textFieldWithDelegate:self];
    [self.contentView addSubview:self.messageText];
    [self.messageText mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.contentView);
        make.trailing.equalTo(self.sendButton.mas_leading).offset(-5);
        make.width.mas_equalTo(140);
    }];
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(9);
        make.top.equalTo(self.contentView).offset(15);
    }];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onTextChange) name:UITextFieldTextDidChangeNotification object:self.messageText];
}

- (void)onClickSendButton:(id)sender {
    V2SettingsMessageItem *item = (V2SettingsMessageItem *)self.item;
    if (item.action) {
        item.action(self.messageText.text ?: @"");
    }
    [self.messageText resignFirstResponder];
}

- (void)onTextChange {
    V2SettingsMessageItem *messageItem = (V2SettingsMessageItem *)self.item;
    messageItem.content                = self.messageText.text;
}

- (void)didUpdateItem:(V2SettingsBaseItem *)item {
    V2SettingsMessageItem *messageItem = (V2SettingsMessageItem *)item;
    [self.sendButton setTitle:messageItem.actionTitle forState:UIControlStateNormal];
    self.messageText.text                  = messageItem.content;
    self.messageText.attributedPlaceholder = [UITextField v2_textFieldPlaceHolderFor:messageItem.placeHolder];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end

@implementation V2SettingsMessageItem

- (instancetype)initWithTitle:(NSString *)title placeHolder:(NSString *)placeHolder action:(void (^)(NSString *_Nullable content))action {
    return [self initWithTitle:title placeHolder:placeHolder content:nil actionTitle:@"发送" action:action];
}

- (instancetype)initWithTitle:(NSString *)title
                  placeHolder:(NSString *)placeHolder
                      content:(NSString *_Nullable)content
                  actionTitle:(nonnull NSString *)actionTitle
                       action:(void (^)(NSString *_Nullable content))action {
    if (self = [super init]) {
        self.title   = title;
        _placeHolder = placeHolder;
        _content     = content;
        _actionTitle = actionTitle;
        _action      = action;
    }
    return self;
}

+ (Class)bindedCellClass {
    return [V2SettingsMessageCell class];
}

- (NSString *)bindedCellId {
    return [V2SettingsMessageItem bindedCellId];
}

@end
