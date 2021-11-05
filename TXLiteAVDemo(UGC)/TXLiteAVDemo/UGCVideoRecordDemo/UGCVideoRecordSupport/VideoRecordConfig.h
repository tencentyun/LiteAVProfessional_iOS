//
//  VideoRecordConfig.h
//  TXLiteAVDemo
//
//  Created by shengcui on 2018/9/13.
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TXLiteAVSDKHeader.h"

@interface VideoRecordConfig : NSObject
@property(nonatomic,assign)TXVideoAspectRatio videoRatio;
@property(nonatomic,assign)TXVideoResolution videoResolution;
@property(nonatomic,assign)int bps;
@property(nonatomic,assign)int fps;
@property(nonatomic,assign)int gop;
@property(nonatomic,assign)BOOL enableAEC;
+ (instancetype)defaultConfigure;
@end

