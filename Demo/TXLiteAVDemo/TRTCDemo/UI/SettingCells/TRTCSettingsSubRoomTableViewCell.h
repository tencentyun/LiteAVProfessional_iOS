/*
 * Module:   TRTCSettingsSubRoomTableViewCell
 *
 * Function: 子房间配置列表Cell，右边是一个开关，可以控制是否在该子房间推送音视频流
 */

#import "TRTCCloudManager.h"
#import "TRTCSettingsBaseCell.h"
NS_ASSUME_NONNULL_BEGIN

@class TRTCSettingsSubRoomCellTableViewItem;

@interface                                                         TRTCSettingsSubRoomTableViewCell : TRTCSettingsBaseCell
@property(strong, nonatomic) UISwitch *                            pushSwitch;
@property(strong, nonatomic) TRTCSettingsSubRoomCellTableViewItem *relatedItem;

- (void)setCellSelected:(BOOL)isSelected;

@end

@interface                                        TRTCSettingsSubRoomCellTableViewItem : TRTCSettingsBaseItem
@property(nonatomic) BOOL                         isOn;
@property(nonatomic) NSString *                   subRoomId;
@property(nonatomic, strong) NSMutableDictionary *subUsersId;
@property(copy, nonatomic, nullable) NSString *   content;
@property(copy, nonatomic, nullable) NSString *   actionTitle;
@property(copy, nonatomic, readonly, nullable) void (^actionA)(BOOL, id);
@property(copy, nonatomic, readonly, nullable) void (^actionB)(NSString *_Nullable content);
- (instancetype)initWithRoomId:(NSString *)roomId
                          isOn:(BOOL)isOn
                       actionA:(void (^_Nullable)(BOOL b, id cell))actionA
                   actionTitle:(nonnull NSString *)actionTitle
                       actionB:(void (^)(NSString *_Nullable content))actionB;

@end

NS_ASSUME_NONNULL_END
