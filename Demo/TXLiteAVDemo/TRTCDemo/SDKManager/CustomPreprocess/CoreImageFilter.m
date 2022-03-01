//
//  CoreImageFilter.m
//  TRTCCustomDemo
//
//  Created by kaoji on 2020/8/25.
//  Copyright © 2020 kaoji. All rights reserved.
//

#import "CoreImageFilter.h"

@interface                             CoreImageFilter ()
@property(nonatomic, strong) CIFilter *blurFilter;
@property(nonatomic, strong) CIFilter *effectFilter;
@end

@implementation CoreImageFilter

- (instancetype)init {
    if (self = [super init]) {
        _blurFilter   = [CIFilter filterWithName:@"CIGaussianBlur"];
        _effectFilter = [CIFilter filterWithName:@"CIPhotoEffectInstant"];
        _fContex      = [CIContext contextWithOptions:nil];
    }
    return self;
}

- (CIImage *)filterPixelBuffer:(TRTCVideoFrame *)frame {
    CVImageBufferRef imageBuffer = frame.pixelBuffer;
    CIImage *        sourceImage = [CIImage imageWithCVPixelBuffer:(CVPixelBufferRef)imageBuffer options:nil];

    [self.blurFilter setValue:sourceImage forKey:kCIInputImageKey];
    CIImage *filteredImage = [self.blurFilter outputImage];

    [self.effectFilter setValue:filteredImage forKey:kCIInputImageKey];
    filteredImage = [self.effectFilter outputImage];

    return filteredImage;
}

@end
