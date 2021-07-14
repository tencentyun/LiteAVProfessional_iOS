/*
* Module:   UISegmentedControl(TRTC)
*
* Function: 标准化UISegmentedControl控件
*
*/

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UISegmentedControl(TRTC_EX)

+ (instancetype)trtc_segment;
- (void)trtc_setupApperance;

@end

NS_ASSUME_NONNULL_END
