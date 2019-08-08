//
//  TXUGCColor.m
//  TXLiteAVDemo
//
//  Created by shengcui on 2018/9/12.
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "TXColor.h"
#define HexColor(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 \
alpha:1.0]

@implementation TXColor
+ (UIColor*)cyan {
    return HexColor(0x0ACCAC);
}
+ (UIColor*)darkCyan {
    return HexColor(0x10acc0);
}
+ (UIColor*)controlBackground {
    return HexColor(0x0BC59C);
}
+ (UIColor*)gray {
    return HexColor(0x777777);
}
+ (UIColor *)lightGray {
    return HexColor(0xcccccc);
}
+ (UIColor *)darkGray {
    return HexColor(0x555555);
}
+ (UIColor *)grayBorder {
    return HexColor(0x999999);
}
+ (UIColor *)black {
    return HexColor(0x181818);
}
+ (UIColor *)progressColor {
    return HexColor(0x00f5ac);
}

@end
