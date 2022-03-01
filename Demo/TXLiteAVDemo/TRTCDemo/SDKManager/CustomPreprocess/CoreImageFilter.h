//
//  CoreImageFilter.h
//  TRTCCustomDemo
//
//  Created by kaoji on 2020/8/25.
//  Copyright © 2020 kaoji. All rights reserved.
//

#import <CoreImage/CoreImage.h>
#import <Foundation/Foundation.h>
#import <TRTCCloudDef.h>

NS_ASSUME_NONNULL_BEGIN

@interface CoreImageFilter : NSObject

@property(nonatomic, strong) CIContext *fContex;
//将buffer通过CoreImage进行修改
- (CIImage *)filterPixelBuffer:(TRTCVideoFrame *)frame;

@end

NS_ASSUME_NONNULL_END
