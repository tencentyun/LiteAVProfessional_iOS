/*
* Module:   V2SettingsBaseCell, V2SettingsBaseItem
*
* Function: 基础框架类。V2SettingsBaseViewController的Cell基类
*
*    1. V2SettingsBaseItem用于存储cell中的数据，以及传导cell中的控件action
*
*    2. V2SettingsBaseCell定义了左侧的titleLabel，子类中可重载setupUI来添加其它控件
*
*/

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class V2SettingsBaseItem;

@interface V2SettingsBaseCell : UITableViewCell

@property (strong, nonatomic) V2SettingsBaseItem *item;
@property (strong, nonatomic, readonly) UILabel *titleLabel;

#pragma mark - To be overriden

- (void)setupUI;

- (void)didUpdateItem:(V2SettingsBaseItem *)item;

- (void)didSelect;

@end


@interface V2SettingsBaseItem : NSObject

@property (strong, nonatomic) NSString *title;
@property (nonatomic, readonly) CGFloat height;

@property (class, nonatomic, readonly) NSString *bindedCellId;

#pragma mark - To be overriden
@property (class, nonatomic, readonly) Class bindedCellClass;
@property (nonatomic, readonly) NSString *bindedCellId;

@end




@interface V2SettingsSwitchCell : V2SettingsBaseCell

@end


@interface V2SettingsSwitchItem : V2SettingsBaseItem

@property (nonatomic) BOOL isOn;
@property (copy, nonatomic, readonly, nullable) void (^action)(BOOL);

- (instancetype)initWithTitle:(NSString *)title isOn:(BOOL)isOn action:(void (^ _Nullable)(BOOL))action;

@end





@interface V2SettingsSliderCell : V2SettingsBaseCell

@end


@interface V2SettingsSliderItem : V2SettingsBaseItem

@property (nonatomic) float sliderValue;
@property (nonatomic) float minValue;
@property (nonatomic) float maxValue;
@property (nonatomic) float step;
@property (nonatomic) BOOL continuous;
@property (copy, nonatomic, readonly) void (^action)(float);

- (instancetype)initWithTitle:(NSString *)title
                        value:(float)value
                          min:(float)min
                          max:(float)max
                         step:(float)step
                   continuous:(BOOL)continuous
                       action:(void (^)(float))action;

@end





@interface V2SettingsSegmentCell : V2SettingsBaseCell

@end


@interface V2SettingsSegmentItem : V2SettingsBaseItem

@property (strong, nonatomic) NSArray<NSString *> *items;
@property (nonatomic) NSInteger selectedIndex;
@property (copy, nonatomic, readonly, nullable) void (^action)(NSInteger);

- (instancetype)initWithTitle:(NSString *)title
                        items:(NSArray<NSString *> *)items
                selectedIndex:(NSInteger)index
                       action:(void(^ _Nullable)(NSInteger index))action;

@end





@interface V2SettingsSelectorCell : V2SettingsBaseCell

@end


@interface V2SettingsSelectorItem : V2SettingsBaseItem

@property (strong, nonatomic) NSArray<NSString *> *items;
@property (nonatomic) NSInteger selectedIndex;

@property (copy, nonatomic, readonly) void (^action)(NSInteger);

- (instancetype)initWithTitle:(NSString *)title
                        items:(NSArray<NSString *> *)items
                selectedIndex:(NSInteger)index
                       action:(void (^)(NSInteger))action;

@end





@interface V2SettingsButtonCell : V2SettingsBaseCell

@end


@interface V2SettingsButtonItem : V2SettingsBaseItem

@property (copy, nonatomic, readonly) void (^action)();
@property (copy, nonatomic) NSString *buttonTitle;

- (instancetype)initWithTitle:(NSString *)title buttonTitle:(NSString *)buttonTitle action:(void (^)())action;

@end

NS_ASSUME_NONNULL_END
