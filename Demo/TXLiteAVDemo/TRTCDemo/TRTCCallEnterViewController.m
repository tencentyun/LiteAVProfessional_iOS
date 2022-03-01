//
//  TRTCCallEnterViewController.m
//  TXLiteAVDemo
//
//  Created by origin 李 on 2021/9/7.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "TRTCCallEnterViewController.h"
#import "AppLocalized.h"
@interface TRTCCallEnterViewController ()

@end

@implementation TRTCCallEnterViewController
- (instancetype)init {
    self = [super init];
    if (self) {
        self.scene = TRTCAppSceneVideoCall;
        self.title = TRTCLocalize(@"Demo.TRTC.Live.trtcCalling");
    }
    return self;
}

@end
