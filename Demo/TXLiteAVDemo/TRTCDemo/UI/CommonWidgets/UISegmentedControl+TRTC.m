/*
* Module:   UISegmentedControl(TRTC)
*
* Function: 标准化UISegmentedControl控件
*
*/

#import "UISegmentedControl+TRTC.h"
#import "ColorMacro.h"

@implementation UISegmentedControl(TRTC_EX)

+ (instancetype)trtc_segment {
    UISegmentedControl *segment = [[UISegmentedControl alloc] init];
    [segment trtc_setupApperance];

    return segment;
}

- (void)trtc_setupApperance {
    
    if (@available(iOS 13.0, *)) {
//        [self setTitleTextAttributes:@{ NSForegroundColorAttributeName : UIColor.whiteColor }
//                               forState:UIControlStateSelected];
//        [self setTitleTextAttributes:@{ NSForegroundColorAttributeName : UIColorFromRGB(0x2364db) }
//                               forState:UIControlStateNormal];
//        self.selectedSegmentTintColor = UIColorFromRGB(0x2364db);
        
        [self setTitleTextAttributes:@{ NSForegroundColorAttributeName : UIColorFromRGB(0x2364db) }
                               forState:UIControlStateSelected];
        [self setTitleTextAttributes:@{ NSForegroundColorAttributeName : UIColorFromRGB(0x999999) }
                               forState:UIControlStateNormal];
//        self.selectedSegmentTintColor = UIColorFromRGB(0x2364db);

        
    } else {
        [self setTitleTextAttributes:@{ NSForegroundColorAttributeName : UIColorFromRGB(0x2364db) }
                                    forState:UIControlStateNormal];
        [self setTitleTextAttributes:@{ NSForegroundColorAttributeName : UIColor.whiteColor }
                               forState:UIControlStateSelected];
    }
}

@end
