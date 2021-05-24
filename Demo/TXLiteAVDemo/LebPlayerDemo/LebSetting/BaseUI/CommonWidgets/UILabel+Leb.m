/*
* Module:   UILabel(TRTC)
*
* Function: 标准化UILabel控件，用于title和content
*
*/

#import "UILabel+Leb.h"
#import "ColorMacro.h"

@implementation UILabel(TRTC)

+ (instancetype)leb_titleLabel {
    UILabel *label = [[UILabel alloc] init];
    label.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    label.textColor = UIColorFromRGB(0x939393);
    return label;
}

+ (instancetype)leb_contentLabel {
    UILabel *label = [[UILabel alloc] init];
    label.font = [UIFont systemFontOfSize:15];
    label.textColor = UIColorFromRGB(0x939393);
    return label;
}

@end
