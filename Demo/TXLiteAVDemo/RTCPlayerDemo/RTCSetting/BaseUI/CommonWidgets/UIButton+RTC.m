/*
 * Module:   UIButton(RTC)
 *
 * Function: 标准化UIButton控件，用于text button和icon button
 *           RTCIconButton用于图片的contentMode
 *
 */

#import "ColorMacro.h"
#import "Masonry.h"
#import "UIButton+Leb.h"
#import "UIImage+Additions.h"

@implementation UIButton (RTC)

+ (instancetype)rtc_cellButtonWithTitle:(NSString *)title {
    UIButton *button         = [UIButton buttonWithType:UIButtonTypeCustom];
    button.contentEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 10);

    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:15];
    [button setupBackground];

    [button mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(30);
    }];
    return button;
}

+ (instancetype)rtc_iconButtonWithImage:(UIImage *)image {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:image forState:UIControlStateNormal];
    button.imageView.contentMode = UIViewContentModeScaleAspectFit;
    button.tintColor             = UIColorFromRGB(0x05a764);
    return button;
}

- (void)setupBackground {
    [self setBackgroundImage:[[UIImage imageWithColor:UIColorFromRGB(0x05a764) size:CGSizeMake(10, 10) cornerRadius:4] stretchableImageWithLeftCapWidth:5 topCapHeight:5]
                    forState:UIControlStateNormal];
    [self setBackgroundImage:[[UIImage imageWithColor:UIColorFromRGB(0x307250) size:CGSizeMake(10, 10) cornerRadius:4] stretchableImageWithLeftCapWidth:5 topCapHeight:5]
                    forState:UIControlStateHighlighted];
}

@end
