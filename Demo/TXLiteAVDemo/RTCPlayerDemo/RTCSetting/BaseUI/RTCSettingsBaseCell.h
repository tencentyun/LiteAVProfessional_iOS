/*
 * Module:   RTCSettingsBaseCell, RTCSettingsBaseItem
 *
 * Function: 基础框架类。RTCSettingsBaseViewController的Cell基类
 *
 *    1. RTCSettingsBaseItem用于存储cell中的数据，以及传导cell中的控件action
 *
 *    2. RTCSettingsBaseCell定义了左侧的titleLabel，子类中可重载setupUI来添加其它控件
 *
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class RTCSettingsBaseItem;

@interface RTCSettingsBaseCell : UITableViewCell

@property(nonatomic, strong) RTCSettingsBaseItem *item;
@property(nonatomic, strong, readonly) UILabel *  titleLabel;

#pragma mark - To be overriden

- (void)setupUI;

- (void)didUpdateItem:(RTCSettingsBaseItem *)item;

- (void)didSelect;

@end

@interface RTCSettingsBaseItem : NSObject

@property(nonatomic, strong) NSString *title;
@property(nonatomic, readonly) CGFloat height;

@property(class, nonatomic, readonly) NSString *bindedCellId;

#pragma mark - To be overriden
@property(class, nonatomic, readonly) Class bindedCellClass;
@property(nonatomic, readonly) NSString *   bindedCellId;

@end

@interface RTCSettingsSwitchCell : RTCSettingsBaseCell

@end

@interface RTCSettingsSwitchItem : RTCSettingsBaseItem

@property(nonatomic, assign) BOOL isOn;
@property(nonatomic, copy, readonly, nullable) void (^action)(BOOL);

- (instancetype)initWithTitle:(NSString *)title isOn:(BOOL)isOn action:(void (^_Nullable)(BOOL))action;

@end

@interface RTCSettingsSliderCell : RTCSettingsBaseCell

@end

@interface RTCSettingsSliderItem : RTCSettingsBaseItem

@property(nonatomic, assign) float sliderValue;
@property(nonatomic, assign) float minValue;
@property(nonatomic, assign) float maxValue;
@property(nonatomic, assign) float step;
@property(nonatomic, assign) BOOL  continuous;
@property(nonatomic, copy, readonly) void (^action)(float);

- (instancetype)initWithTitle:(NSString *)title value:(float)value min:(float)min max:(float)max step:(float)step continuous:(BOOL)continuous action:(void (^)(float))action;

@end

@interface RTCSettingsSegmentCell : RTCSettingsBaseCell

@end

@interface RTCSettingsSegmentItem : RTCSettingsBaseItem

@property(nonatomic, strong) NSArray<NSString *> *items;
@property(nonatomic, assign) NSInteger            selectedIndex;
@property(nonatomic, copy, readonly, nullable) void (^action)(NSInteger);

- (instancetype)initWithTitle:(NSString *)title items:(NSArray<NSString *> *)items selectedIndex:(NSInteger)index action:(void (^_Nullable)(NSInteger index))action;

@end

@interface RTCSettingsSelectorCell : RTCSettingsBaseCell

@end

@interface RTCSettingsSelectorItem : RTCSettingsBaseItem

@property(nonatomic, strong) NSArray<NSString *> *items;
@property(nonatomic, assign) NSInteger            selectedIndex;

@property(nonatomic, copy, readonly) void (^action)(NSInteger);

- (instancetype)initWithTitle:(NSString *)title items:(NSArray<NSString *> *)items selectedIndex:(NSInteger)index action:(void (^)(NSInteger))action;

@end

@interface RTCSettingsButtonCell : RTCSettingsBaseCell

@end

@interface RTCSettingsButtonItem : RTCSettingsBaseItem

@property(nonatomic, copy, readonly) void (^action)();
@property(nonatomic, copy, nonatomic) NSString *buttonTitle;

- (instancetype)initWithTitle:(NSString *)title buttonTitle:(NSString *)buttonTitle action:(void (^)())action;

@end

NS_ASSUME_NONNULL_END
