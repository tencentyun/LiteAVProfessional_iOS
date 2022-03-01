/*
 * Module:   LebSettingsBaseCell, LebSettingsBaseItem
 *
 * Function: 基础框架类。LebSettingsBaseViewController的Cell基类
 *
 *    1. LebSettingsBaseItem用于存储cell中的数据，以及传导cell中的控件action
 *
 *    2. LebSettingsBaseCell定义了左侧的titleLabel，子类中可重载setupUI来添加其它控件
 *
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class LebSettingsBaseItem;

@interface LebSettingsBaseCell : UITableViewCell

@property(strong, nonatomic) LebSettingsBaseItem *item;
@property(strong, nonatomic, readonly) UILabel *  titleLabel;

#pragma mark - To be overriden

- (void)setupUI;

- (void)didUpdateItem:(LebSettingsBaseItem *)item;

- (void)didSelect;

@end

@interface LebSettingsBaseItem : NSObject

@property(strong, nonatomic) NSString *title;
@property(nonatomic, readonly) CGFloat height;

@property(class, nonatomic, readonly) NSString *bindedCellId;

#pragma mark - To be overriden
@property(class, nonatomic, readonly) Class bindedCellClass;
@property(nonatomic, readonly) NSString *   bindedCellId;

@end

@interface LebSettingsSwitchCell : LebSettingsBaseCell

@end

@interface LebSettingsSwitchItem : LebSettingsBaseItem

@property(nonatomic) BOOL isOn;
@property(copy, nonatomic, readonly, nullable) void (^action)(BOOL);

- (instancetype)initWithTitle:(NSString *)title isOn:(BOOL)isOn action:(void (^_Nullable)(BOOL))action;

@end

@interface LebSettingsSliderCell : LebSettingsBaseCell

@end

@interface LebSettingsSliderItem : LebSettingsBaseItem

@property(nonatomic) float sliderValue;
@property(nonatomic) float minValue;
@property(nonatomic) float maxValue;
@property(nonatomic) float step;
@property(nonatomic) BOOL  continuous;
@property(copy, nonatomic, readonly) void (^action)(float);

- (instancetype)initWithTitle:(NSString *)title value:(float)value min:(float)min max:(float)max step:(float)step continuous:(BOOL)continuous action:(void (^)(float))action;

@end

@interface LebSettingsSegmentCell : LebSettingsBaseCell

@end

@interface LebSettingsSegmentItem : LebSettingsBaseItem

@property(strong, nonatomic) NSArray<NSString *> *items;
@property(nonatomic) NSInteger                    selectedIndex;
@property(copy, nonatomic, readonly, nullable) void (^action)(NSInteger);

- (instancetype)initWithTitle:(NSString *)title items:(NSArray<NSString *> *)items selectedIndex:(NSInteger)index action:(void (^_Nullable)(NSInteger index))action;

@end

@interface LebSettingsSelectorCell : LebSettingsBaseCell

@end

@interface LebSettingsSelectorItem : LebSettingsBaseItem

@property(strong, nonatomic) NSArray<NSString *> *items;
@property(nonatomic) NSInteger                    selectedIndex;

@property(copy, nonatomic, readonly) void (^action)(NSInteger);

- (instancetype)initWithTitle:(NSString *)title items:(NSArray<NSString *> *)items selectedIndex:(NSInteger)index action:(void (^)(NSInteger))action;

@end

@interface LebSettingsButtonCell : LebSettingsBaseCell

@end

@interface LebSettingsButtonItem : LebSettingsBaseItem

@property(copy, nonatomic, readonly) void (^action)();
@property(copy, nonatomic) NSString *buttonTitle;

- (instancetype)initWithTitle:(NSString *)title buttonTitle:(NSString *)buttonTitle action:(void (^)())action;

@end

@interface LebSettingsTextFieldCell : LebSettingsBaseCell

@end

@interface LebSettingsTextFieldItem : LebSettingsBaseItem

@property(nonatomic) BOOL isOn;
@property(copy, nonatomic, readonly, nullable) void (^action)(BOOL, NSInteger);

- (instancetype)initWithTitle:(NSString *)title isOn:(BOOL)isOn action:(void (^_Nullable)(BOOL, NSInteger))action;

@end

NS_ASSUME_NONNULL_END
