/*
 * Module:   TRTCSettingsMainRoomTableViewItem
 *
 * Function: 主房间配置列表Cell，右边是一个开关，可以控制是否在主房间推送音视频流
 */

#import "TRTCSettingsMainRoomTableViewCell.h"

#import "AppLocalized.h"
#import "ColorMacro.h"
#import "Masonry.h"
#import "TRTCCloud.h"
#import "UIButton+TRTC.h"
@interface TRTCSettingsMainRoomTableViewCell ()

@property(strong, nonatomic) UIButton * leaveRoom;
@property(strong, nonatomic) TRTCCloud *cloud;
@property(strong, nonatomic) UILabel *  pushLabel;
@end

@implementation TRTCSettingsMainRoomTableViewCell

- (void)setupUI {
    [super setupUI];

    self.pushSwitch = [[UISwitch alloc] init];
    [self.pushSwitch addTarget:self action:@selector(onClickSwitch:) forControlEvents:UIControlEventValueChanged];
    self.pushSwitch.onTintColor = UIColorFromRGB(0x05a764);

    [self.contentView addSubview:self.pushSwitch];
    [self.pushSwitch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.contentView);
        make.trailing.equalTo(self.contentView).offset(-100);
    }];

    self.pushLabel = [[UILabel alloc] init];
    [self.contentView addSubview:self.pushLabel];
    self.pushLabel.text            = TRTCLocalize(@"Demo.TRTC.Live.pushStream");
    self.pushLabel.textColor       = [UIColor whiteColor];
    self.pushLabel.backgroundColor = [UIColor clearColor];
    [self.pushLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.contentView);
        make.trailing.equalTo(self.contentView).offset(-180);
    }];

    _relatedItem = [[TRTCSettingsMainRoomTableViewItem alloc] init];
}

- (void)setCellSelected:(BOOL)isSelected {
    self.pushSwitch.on    = isSelected;
    self.relatedItem.isOn = isSelected;
}

- (void)didUpdateItem:(TRTCSettingsBaseItem *)item {
    self.relatedItem = (TRTCSettingsMainRoomTableViewItem *)item;
    if ([item isKindOfClass:[TRTCSettingsMainRoomTableViewItem class]]) {
        self.pushSwitch.on = self.relatedItem.isOn;
    }
}

- (void)onClickSwitch:(id)sender {
    TRTCSettingsMainRoomTableViewItem *switchItem = (TRTCSettingsMainRoomTableViewItem *)self.item;
    switchItem.isOn                               = self.pushSwitch.isOn;
    if (switchItem.actionA) {
        switchItem.actionA(self.pushSwitch.isOn, self);
    }
}

@end

@implementation TRTCSettingsMainRoomTableViewItem

- (instancetype)initWithRoomId:(NSString *)roomId
                          isOn:(BOOL)isOn
                       actionA:(void (^)(BOOL b, id cell))actionA
                   actionTitle:(nonnull NSString *)actionTitle
                       actionB:(void (^)(NSString *_Nullable))actionB {
    if (self = [super init]) {
        self.title   = roomId;
        _isOn        = isOn;
        _actionA     = actionA;
        _actionB     = actionB;
        _actionTitle = actionTitle;
    }
    return self;
}

+ (Class)bindedCellClass {
    return [TRTCSettingsMainRoomTableViewCell class];
}

- (NSString *)bindedCellId {
    return [TRTCSettingsMainRoomTableViewItem bindedCellId];
}

@end
