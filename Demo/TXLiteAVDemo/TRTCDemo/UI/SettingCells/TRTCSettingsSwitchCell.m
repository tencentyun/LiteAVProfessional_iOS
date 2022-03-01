/*
 * Module:   TRTCSettingsSwitchCell
 *
 * Function: 配置列表Cell，右侧是一个Switcher
 *
 */

#import "TRTCSettingsSwitchCell.h"

#import "ColorMacro.h"
#import "Masonry.h"

@interface TRTCSettingsSwitchCell ()

@property(strong, nonatomic) UISwitch *switcher;

@end

@implementation TRTCSettingsSwitchCell

- (void)setupUI {
    [super setupUI];

    self.switcher = [[UISwitch alloc] init];
    [self.switcher addTarget:self action:@selector(onClickSwitch:) forControlEvents:UIControlEventValueChanged];
    self.switcher.onTintColor = UIColorFromRGB(0x2364db);

    [self.contentView addSubview:self.switcher];
    [self.switcher mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.contentView);
        make.trailing.equalTo(self.contentView).offset(-18);
    }];
    [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(9);
        make.top.equalTo(self.contentView).offset(15);
    }];
}

- (void)didUpdateItem:(TRTCSettingsBaseItem *)item {
    if ([item isKindOfClass:[TRTCSettingsSwitchItem class]]) {
        TRTCSettingsSwitchItem *switchItem = (TRTCSettingsSwitchItem *)item;
        self.switcher.on                   = switchItem.isOn;
    }
}

- (void)onClickSwitch:(id)sender {
    TRTCSettingsSwitchItem *switchItem = (TRTCSettingsSwitchItem *)self.item;
    switchItem.isOn                    = self.switcher.isOn;
    if (switchItem.action) {
        switchItem.action(self.switcher.isOn);
    }
}

@end

@implementation TRTCSettingsSwitchItem

- (instancetype)initWithTitle:(NSString *)title isOn:(BOOL)isOn action:(void (^_Nullable)(BOOL))action {
    if (self = [super init]) {
        self.title = title;
        _isOn      = isOn;
        _action    = action;
    }
    return self;
}

+ (Class)bindedCellClass {
    return [TRTCSettingsSwitchCell class];
}

- (NSString *)bindedCellId {
    return [TRTCSettingsSwitchItem bindedCellId];
}

@end
