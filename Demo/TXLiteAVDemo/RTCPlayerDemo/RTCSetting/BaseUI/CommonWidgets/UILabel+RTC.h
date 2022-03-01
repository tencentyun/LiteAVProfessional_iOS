/*
 * Module:   UILabel(RTC)
 *
 * Function: 标准化UILabel控件，用于title和content
 *
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UILabel (RTC)

+ (instancetype)rtc_titleLabel;

+ (instancetype)rtc_contentLabel;

@end

NS_ASSUME_NONNULL_END
