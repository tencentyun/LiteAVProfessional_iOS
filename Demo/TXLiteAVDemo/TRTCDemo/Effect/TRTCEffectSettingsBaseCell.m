/*
* Module:   TRTCEffectSettingsBaseItem, TRTCEffectSettingsBaseCell
*
* Function: 基础框架类。TRTCSettingsBaseViewController的Cell基类
*
*    1. TRTCEffectSettingsBaseItem用于存储cell中的数据，以及传导cell中的控件action
*
*    2. TRTCEffectSettingsBaseCell定义了左侧的titleLabel，子类中可重载setupUI来添加其它控件
*
*/

#import "TRTCEffectSettingsBaseCell.h"
#import "Masonry.h"
#import "ColorMacro.h"

@interface TRTCEffectSettingsBaseCell ()

@property (strong, nonatomic) UILabel *titleLabel;

@end

@implementation TRTCEffectSettingsBaseCell

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

- (void)setItem:(TRTCEffectSettingsBaseItem *)item {
    _item = item;
    self.titleLabel.text = item.title;
    [self didUpdateItem:item];
}

#pragma mark - Overridable

- (void)setupUI {
    self.backgroundColor = UIColor.clearColor;
    
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    self.titleLabel.textColor = UIColorFromRGB(0x939393);
    [self.contentView addSubview:self.titleLabel];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.contentView);
        make.leading.equalTo(self.contentView).offset(18);
    }];
}

- (void)didUpdateItem:(TRTCEffectSettingsBaseItem *)item {
}

- (void)didSelect {
}

@end

@implementation TRTCEffectSettingsBaseItem

- (CGFloat)height {
    return 50;
}

+ (Class)bindedCellClass {
    return [TRTCEffectSettingsBaseCell class];
}

+ (NSString *)bindedCellId {
    return [[self bindedCellClass] description];
}

- (NSString *)bindedCellId {
    return [TRTCEffectSettingsBaseItem bindedCellId];
}

@end
