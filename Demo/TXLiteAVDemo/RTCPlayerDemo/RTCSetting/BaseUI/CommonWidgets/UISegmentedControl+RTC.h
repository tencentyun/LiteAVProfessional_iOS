/*
 * Module:   UISegmentedControl(RTC)
 *
 * Function: 标准化UISegmentedControl控件
 *
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UISegmentedControl (RTC)

+ (instancetype)rtc_segment;
- (void)rtc_setupApperance;

@end

NS_ASSUME_NONNULL_END
