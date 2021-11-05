//
//  LayoutDefine.m
//  TXLiteAVDemo_Enterprise
//
//  Created by peterwtma on 2021/7/20.
//  Copyright © 2021 Tencent. All rights reserved.
//


#import "LayoutDefine.h"


@implementation LayoutDefine

- (instancetype)init{
    self = [super init];
    if(self) {
        self.screenWidth = UIScreen.mainScreen.bounds.size.width;
        self.screenHeight = UIScreen.mainScreen.bounds.size.height;
        if([self deviceIsIphoneX]) {
            self.deviceSafeTopHeight = 44;
            self.deviceSafeBottomHeight = 34;
        } else {
            self.deviceSafeTopHeight = 20;
            self.deviceSafeBottomHeight = 0;
        }
        
    }
    return self;
}

- (BOOL)deviceIsIphoneX{
    if(UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad){
        return false;
    }
    CGSize size = UIScreen.mainScreen.bounds.size;
    int notchValue = (int)(size.width/size.height*100);
    if (notchValue == 216 || notchValue == 46) {
        return true;
    }
    return false;
}

- (CGFloat)widthConvertPixel:(CGFloat)w {
    return w / 375.0 * self.screenWidth;
}

+ (CGFloat)convertPixel:(CGFloat)h {
    return h / 812.0 * UIScreen.mainScreen.bounds.size.height;
}
@end
