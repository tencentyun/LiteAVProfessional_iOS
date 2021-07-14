/*
* Module:   UISlider(TRTC)
*
* Function: 标准化UISlider控件
*
*/

#import "UISlider+TRTC.h"
#import "ColorMacro.h"
#import "UIImage+Additions.h"

@implementation UISlider(TRTC_EX)

+ (instancetype)trtc_slider {
    UISlider *slider = [[UISlider alloc] init];
    slider.minimumTrackTintColor = UIColorFromRGB(0x2364db);
    UIImage *icon = [UIImage imageWithColor:UIColorFromRGB(0x2364db)
                                       size:CGSizeMake(18, 18)
                                cornerInset:UICornerInsetMake(9, 9, 9, 9)];
    [slider setThumbImage:icon forState:UIControlStateNormal];
    return slider;
}

@end
