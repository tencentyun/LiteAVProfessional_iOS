/*
 * Module:   UILabel(TRTC)
 *
 * Function: 标准化UILabel控件，用于title和content
 *
 */

#import "ColorMacro.h"
#import "UILabel+V2.h"

@implementation UILabel (TRTC)

+ (instancetype)v2_titleLabel {
    UILabel *label  = [[UILabel alloc] init];
    label.font      = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    label.textColor = UIColorFromRGB(0x939393);
    return label;
}

+ (instancetype)v2_contentLabel {
    UILabel *label  = [[UILabel alloc] init];
    label.font      = [UIFont systemFontOfSize:15];
    label.textColor = UIColorFromRGB(0x939393);
    return label;
}

@end
