/*
 * Module:   UIButton(RTC)
 *
 * Function: 标准化UIButton控件，用于text button和icon button
 *           RTCIconButton用于图片的contentMode
 *
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIButton (RTC)

+ (instancetype)rtc_cellButtonWithTitle:(NSString *)title;

+ (instancetype)rtc_iconButtonWithImage:(UIImage *)image;

- (void)setupBackground;

@end

NS_ASSUME_NONNULL_END
