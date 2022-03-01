/*
 * Module:   UISegmentedControl(RTC)
 *
 * Function: 标准化UISegmentedControl控件
 *
 */

#import "ColorMacro.h"
#import "UISegmentedControl+Leb.h"

@implementation UISegmentedControl (RTC)

+ (instancetype)rtc_segment {
    UISegmentedControl *segment = [[UISegmentedControl alloc] init];
    [segment leb_setupApperance];

    return segment;
}

- (void)rtc_setupApperance {
    UISegmentedControl *segment = [[UISegmentedControl alloc] init];
    if (@available(iOS 13.0, *)) {
        [segment setTitleTextAttributes:@{NSForegroundColorAttributeName : UIColorFromRGB(0x05a764)} forState:UIControlStateSelected];
    } else {
        segment.tintColor = UIColorFromRGB(0x05a764);
        [segment setTitleTextAttributes:@{NSForegroundColorAttributeName : UIColor.whiteColor} forState:UIControlStateSelected];
    }
    [segment setTitleTextAttributes:@{NSForegroundColorAttributeName : UIColorFromRGB(0x939393)} forState:UIControlStateNormal];
}

@end
