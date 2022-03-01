//
//  TestRenderCustomVideoData.m
//  TXLiteAVDemo
//
//  Created by rushanting on 2019/3/27.
//  Copyright © 2019 Tencent. All rights reserved.
//

#import "TestRenderVideoFrame.h"
#import "TRTCCloudDef.h"

@interface                                        TestRenderVideoFrame ()
@property(nonatomic, retain) UIImageView *        localVideoView;
@property(nonatomic, retain) NSMutableDictionary *userVideoViews;
@end

@implementation TestRenderVideoFrame

- (instancetype)init {
    if (self = [super init]) {
        _userVideoViews = [NSMutableDictionary new];
    }

    return self;
}

- (void)addUser:(NSString *)userId videoView:(UIImageView *)videoView {
    // userId是nil为自己
    if (!userId) {
        _localVideoView = videoView;
    } else {
        [_userVideoViews setObject:videoView forKey:userId];
    }
}

- (void)onRenderVideoFrame:(TRTCVideoFrame *)frame userId:(NSString *)userId streamType:(TRTCVideoStreamType)streamType {
    if (frame.bufferType == TRTCVideoBufferType_NSData && frame.pixelFormat == TRTCVideoPixelFormat_NV12) {
        __weak __typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            TestRenderVideoFrame *strongSelf = weakSelf;
            UIImageView *         videoView  = nil;
            if (userId && userId.length > 0) {
                videoView = [strongSelf.userVideoViews objectForKey:userId];
            } else {
                videoView = strongSelf.localVideoView;
            }
            unsigned char *rgbaData = malloc(frame.width * frame.height * 4);
            convertNv12ToRgba(rgbaData, (unsigned char *)frame.data.bytes, frame.width, frame.height);
            UIImage *image        = [self convertRGBAToUIImage:rgbaData withWidth:frame.width withHeight:frame.height];
            videoView.image       = image;
            videoView.contentMode = UIViewContentModeScaleAspectFit;
            free(rgbaData);
        });
    }
    if (frame.bufferType == TRTCVideoBufferType_NSData && frame.pixelFormat == TRTCVideoPixelFormat_32BGRA) {
        __weak __typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            TestRenderVideoFrame *strongSelf = weakSelf;
            UIImageView *         videoView  = nil;
            if (userId && userId.length > 0) {
                videoView = [strongSelf.userVideoViews objectForKey:userId];
            } else {
                videoView = strongSelf.localVideoView;
            }
            unsigned char *rgbaData = malloc(frame.width * frame.height * 4);
            convertBgraToRgba(rgbaData, (unsigned char *)frame.data.bytes, frame.width, frame.height);
            UIImage *image        = [self convertRGBAToUIImage:rgbaData withWidth:frame.width withHeight:frame.height];
            videoView.image       = image;
            videoView.contentMode = UIViewContentModeScaleAspectFit;
            free(rgbaData);
        });
    }
    if (frame.bufferType == TRTCVideoBufferType_PixelBuffer) {
        CFRetain(frame.pixelBuffer);
        __weak __typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            TestRenderVideoFrame *strongSelf = weakSelf;
            UIImageView *         videoView  = nil;
            if (userId && userId.length > 0) {
                videoView = [strongSelf.userVideoViews objectForKey:userId];
            } else {
                videoView = strongSelf.localVideoView;
            }
            videoView.image       = [UIImage imageWithCIImage:[CIImage imageWithCVImageBuffer:frame.pixelBuffer]];
            videoView.contentMode = UIViewContentModeScaleAspectFit;
            CFRelease(frame.pixelBuffer);
        });
    }
}

void convertNv12ToRgba(unsigned char *rgbout, unsigned char *pdata, int DataWidth, int DataHeight) {
    unsigned long  idx = 0;
    unsigned char *ybase, *ubase;
    float          y, u, v;
    ybase = pdata;                           //获取Y平面地址
    ubase = pdata + DataWidth * DataHeight;  //获取U平面地址，NV12中U、V是交错存储在一个平面的，V是U+1
    for (int j = 0; j < DataHeight; j++) {
        for (int i = 0; i < DataWidth; i++) {
            int r, g, b;
            y = ybase[i + j * DataWidth];  //一个像素对应一个y
            if (y < 16) y = 16;
            if (y > 235) y = 235;
            u = ubase[j / 2 * DataWidth + (i / 2) * 2];  // 每四个y对应一个uv
            if (u < 16) u = 16;
            if (u > 239) u = 239;
            v = ubase[j / 2 * DataWidth + (i / 2) * 2 + 1];  //一定要注意是u+1
            if (v < 16) v = 16;
            if (v > 239) v = 239;

            r = (1.164 * (y - 16) + 1.596 * (v - 128));
            if (r < 0) r = 0;
            if (r > 255) r = 255;
            g = (1.164 * (y - 16) - 0.813 * (v - 128) - 0.391 * (u - 128));
            if (g < 0) g = 0;
            if (g > 255) g = 255;
            b = (1.164 * (y - 16) + 2.018 * (u - 128));
            if (b < 0) b = 0;
            if (b > 255) b = 255;

            rgbout[idx++] = r;
            rgbout[idx++] = g;
            rgbout[idx++] = b;
            rgbout[idx++] = (char)255;
        }
    }
}

void convertBgraToRgba(unsigned char *rgbaout, unsigned char *pdata, int DataWidth, int DataHeight) {
    for (int i = 0; i < DataWidth * DataHeight; ++i) {
        rgbaout[4 * i]     = pdata[4 * i + 2];
        rgbaout[4 * i + 1] = pdata[4 * i + 1];
        rgbaout[4 * i + 2] = pdata[4 * i];
        rgbaout[4 * i + 3] = pdata[4 * i + 3];
    }
}

- (UIImage *)convertRGBAToUIImage:(unsigned char *)buffer withWidth:(int)width withHeight:(int)height {
    //转为RGBA32
    char *rgba = (char *)malloc(width * height * 4);
    for (int i = 0; i < width * height; ++i) {
        rgba[4 * i]     = buffer[4 * i];
        rgba[4 * i + 1] = buffer[4 * i + 1];
        rgba[4 * i + 2] = buffer[4 * i + 2];
        rgba[4 * i + 3] = buffer[4 * i + 3];
    }

    size_t            bufferLength     = width * height * 4;
    CGDataProviderRef provider         = CGDataProviderCreateWithData(NULL, rgba, bufferLength, NULL);
    size_t            bitsPerComponent = 8;
    size_t            bitsPerPixel     = 32;
    size_t            bytesPerRow      = 4 * width;

    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    if (colorSpaceRef == NULL) {
        NSLog(@"Error allocating color space");
        CGDataProviderRelease(provider);
        return nil;
    }

    CGBitmapInfo           bitmapInfo      = kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;

    CGImageRef iref = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo,
                                    provider,  // data provider
                                    NULL,      // decode
                                    YES,       // should interpolate
                                    renderingIntent);

    uint32_t *pixels = (uint32_t *)malloc(bufferLength);

    if (pixels == NULL) {
        NSLog(@"Error: Memory not allocated for bitmap");
        CGDataProviderRelease(provider);
        CGColorSpaceRelease(colorSpaceRef);
        CGImageRelease(iref);
        return nil;
    }

    CGContextRef context = CGBitmapContextCreate(pixels, width, height, bitsPerComponent, bytesPerRow, colorSpaceRef, bitmapInfo);

    if (context == NULL) {
        NSLog(@"Error context not created");
        if (pixels) {
            free(pixels);
            pixels = NULL;
        }
    }

    UIImage *image = nil;
    if (context) {
        CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, width, height), iref);

        CGImageRef imageRef = CGBitmapContextCreateImage(context);

        image = [UIImage imageWithCGImage:imageRef scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
        if ([UIImage respondsToSelector:@selector(imageWithCGImage:scale:orientation:)]) {
            image = [UIImage imageWithCGImage:imageRef scale:1.0 orientation:UIImageOrientationUp];
        } else {
            image = [UIImage imageWithCGImage:imageRef];
        }

        CGImageRelease(imageRef);
        CGContextRelease(context);
        CGImageRelease(iref);
    }

    CGColorSpaceRelease(colorSpaceRef);
    CGDataProviderRelease(provider);

    if (pixels) {
        free(pixels);
    }
    if (rgba) {
        free(rgba);
    }
    return image;
}

@end
