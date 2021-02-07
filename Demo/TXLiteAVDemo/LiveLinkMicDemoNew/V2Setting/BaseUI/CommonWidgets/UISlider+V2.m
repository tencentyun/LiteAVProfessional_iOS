/*
* Module:   UISlider(TRTC)
*
* Function: 标准化UISlider控件
*
*/

#import "UISlider+V2.h"
#import "ColorMacro.h"
#import "UIImage+Additions.h"

@implementation UISlider(TRTC)

+ (instancetype)v2_slider {
    UISlider *slider = [[UISlider alloc] init];
    slider.minimumTrackTintColor = UIColorFromRGB(0x05a764);
    UIImage *icon = [UIImage imageWithColor:UIColorFromRGB(0x05a764)
                                       size:CGSizeMake(18, 18)
                                cornerInset:UICornerInsetMake(9, 9, 9, 9)];
    [slider setThumbImage:icon forState:UIControlStateNormal];
    return slider;
}

@end
