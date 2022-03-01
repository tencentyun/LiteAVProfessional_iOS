/*
 * Module:   UILabel(TRTC)
 *
 * Function: 标准化UILabel控件，用于title和content
 *
 */

#import "ColorMacro.h"
#import "UILabel+TRTC.h"

@implementation UILabel (TRTC_EX)

+ (instancetype)trtc_titleLabel {
    UILabel *label  = [[UILabel alloc] init];
    label.font      = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    label.textColor = [UIColor whiteColor];
    return label;
}

+ (instancetype)trtc_contentLabel {
    UILabel *label  = [[UILabel alloc] init];
    label.font      = [UIFont systemFontOfSize:15];
    label.textColor = UIColorFromRGB(0x939393);
    return label;
}

@end
