/*
* Module:   TRTCEffectSettingsBaseCell, TRTCEffectSettingsBaseItem
*
* Function: 基础框架类。TRTCSettingsBaseViewController的Cell基类
*
*    1. TRTCEffectSettingsBaseItem用于存储cell中的数据，以及传导cell中的控件action
*
*    2. TRTCEffectSettingsBaseCell定义了左侧的titleLabel，子类中可重载setupUI来添加其它控件
*
*/

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class TRTCEffectSettingsBaseItem;

@interface TRTCEffectSettingsBaseCell : UITableViewCell

@property (strong, nonatomic) TRTCEffectSettingsBaseItem *item;
@property (strong, nonatomic, readonly) UILabel *titleLabel;

#pragma mark - To be overriden

- (void)setupUI;

- (void)didUpdateItem:(TRTCEffectSettingsBaseItem *)item;

- (void)didSelect;

@end


@interface TRTCEffectSettingsBaseItem : NSObject

@property (strong, nonatomic) NSString *title;
@property (nonatomic, readonly) CGFloat height;

@property (class, nonatomic, readonly) NSString *bindedCellId;

#pragma mark - To be overridden
@property (class, nonatomic, readonly) Class bindedCellClass;
@property (nonatomic, readonly) NSString *bindedCellId;

@property (assign, nonatomic) NSInteger tag;

@end

NS_ASSUME_NONNULL_END
