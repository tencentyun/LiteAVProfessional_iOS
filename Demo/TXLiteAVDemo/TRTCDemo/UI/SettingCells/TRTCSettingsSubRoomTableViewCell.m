/*
 * Module:   TRTCSettingsSubRoomTableViewCell
 *
 * Function: 子房间配置列表Cell，右边是一个开关，可以控制是否在该子房间推送音视频流
 */

#import "TRTCSettingsSubRoomTableViewCell.h"

#import "AppLocalized.h"
#import "ColorMacro.h"
#import "Masonry.h"
#import "UIButton+TRTC.h"

@interface TRTCSettingsSubRoomTableViewCell ()

@property(strong, nonatomic) UIButton *leaveRoom;
@property(strong, nonatomic) UILabel * pushLabel;
@end

@implementation TRTCSettingsSubRoomTableViewCell

- (void)setupUI {
    [super setupUI];

    self.leaveRoom = [UIButton trtc_cellButtonWithTitle:TRTCLocalize(@"Demo.TRTC.Live.exitRoom")];
    [self.leaveRoom addTarget:self action:@selector(onClickLeaveRoom) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.leaveRoom];
    [self.leaveRoom mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.contentView);
        make.trailing.equalTo(self.contentView).offset(-18);
    }];

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

    _relatedItem = [[TRTCSettingsSubRoomCellTableViewItem alloc] init];
}

- (void)onClickLeaveRoom {
    TRTCSettingsSubRoomCellTableViewItem *item = (TRTCSettingsSubRoomCellTableViewItem *)self.item;
    if (item.actionB) {
        item.actionB(nil);
    }
}

- (void)setCellSelected:(BOOL)isSelected {
    self.pushSwitch.on    = isSelected;
    self.relatedItem.isOn = isSelected;
}

- (void)didUpdateItem:(TRTCSettingsBaseItem *)item {
    self.relatedItem = (TRTCSettingsSubRoomCellTableViewItem *)item;
    if ([item isKindOfClass:[TRTCSettingsSubRoomCellTableViewItem class]]) {
        self.pushSwitch.on = self.relatedItem.isOn;
    }
}

- (void)onClickSwitch:(id)sender {
    TRTCSettingsSubRoomCellTableViewItem *switchItem = (TRTCSettingsSubRoomCellTableViewItem *)self.item;
    switchItem.isOn                                  = self.pushSwitch.isOn;
    if (switchItem.actionA) {
        switchItem.actionA(self.pushSwitch.isOn, self);
    }
}

@end

@implementation TRTCSettingsSubRoomCellTableViewItem

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
        _subRoomId   = roomId;
    }
    return self;
}

+ (Class)bindedCellClass {
    return [TRTCSettingsSubRoomTableViewCell class];
}

- (NSString *)bindedCellId {
    return [TRTCSettingsSubRoomCellTableViewItem bindedCellId];
}

@end
