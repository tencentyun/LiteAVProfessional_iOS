//
//  VideoRecordConfig.m
//  TXLiteAVDemo
//
//  Created by shengcui on 2018/9/13.
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "VideoRecordConfig.h"

@implementation VideoRecordConfig
-(instancetype)init
{
    self = [super init];
    if (self) {
        _videoResolution = VIDEO_RESOLUTION_540_960;
        _videoRatio = VIDEO_ASPECT_RATIO_9_16;
        _bps = 2400;
        _fps = 20;
        _gop = 3;
        _enableAEC = YES;
    }
    return self;
}
+ (instancetype)defaultConfigure
{
    return [[VideoRecordConfig alloc] init];
}
@end

