/*
 * Module:   UISegmentedControl(TRTC)
 *
 * Function: 标准化UISegmentedControl控件
 *
 */

#import "ColorMacro.h"
#import "UISegmentedControl+V2.h"

@implementation UISegmentedControl (TRTC)

+ (instancetype)v2_segment {
    UISegmentedControl *segment = [[UISegmentedControl alloc] init];
    [segment v2_setupApperance];

    return segment;
}

- (void)v2_setupApperance {
    UISegmentedControl *segment = [[UISegmentedControl alloc] init];
    // TODO: Uncomment this when RDM supports Xcode 11
    //    if (@available(iOS 13.0, *)) {
    //        segment.selectedSegmentTintColor = UIColorFromRGB(0x05a764);
    //    } else {
    //        segment.tintColor = UIColorFromRGB(0x05a764);
    //    }

    if (@available(iOS 13.0, *)) {
        [segment setTitleTextAttributes:@{NSForegroundColorAttributeName : UIColorFromRGB(0x05a764)} forState:UIControlStateSelected];
    } else {
        segment.tintColor = UIColorFromRGB(0x05a764);
        [segment setTitleTextAttributes:@{NSForegroundColorAttributeName : UIColor.whiteColor} forState:UIControlStateSelected];
    }
    [segment setTitleTextAttributes:@{NSForegroundColorAttributeName : UIColorFromRGB(0x939393)} forState:UIControlStateNormal];
}

@end
