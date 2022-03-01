//
//  WaterMarkProcessor.m
//  WaterMarkDemo
//
//  Created by adams on 2021/7/7.
//

#import "WaterMarkProcessor.h"

#import "GLAlphaBlendFilter.h"
#import "GLTextureInput.h"
#import "GLTextureOutput.h"
#import "GLUIElement.h"
#import "PixelBufferProcessor.h"
#import "libyuv.h"

@interface WaterMarkProcessor () {
    CVPixelBufferRef _pixelBufferNV12;
}
@property(nonatomic, strong) PixelBufferProcessor *pixelBufferProcessor;
@property(nonatomic, assign) CVPixelBufferRef      resultPixelBuffer;
@property(nonatomic, strong) GLUIElement *         uiElement;
@property(nonatomic, strong) GLAlphaBlendFilter *  blendFilter;
@property(nonatomic, strong) UIView *              contentView;
@property(nonatomic, strong) UILabel *             timeLabel;
@property(nonatomic, strong) NSDateFormatter *     formatter;
@end

@implementation WaterMarkProcessor
- (void)setPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    if (_pixelBuffer && pixelBuffer && CFEqual(pixelBuffer, _pixelBuffer)) {
        return;
    }
    if (pixelBuffer) {
        CVPixelBufferRetain(pixelBuffer);
    }
    if (_pixelBuffer) {
        CVPixelBufferRelease(_pixelBuffer);
    }
    _pixelBuffer = pixelBuffer;
}

- (void)setResultPixelBuffer:(CVPixelBufferRef)resultPixelBuffer {
    if (_resultPixelBuffer && resultPixelBuffer && CFEqual(resultPixelBuffer, _resultPixelBuffer)) {
        return;
    }
    if (resultPixelBuffer) {
        CVPixelBufferRetain(resultPixelBuffer);
    }
    if (_resultPixelBuffer) {
        CVPixelBufferRelease(_resultPixelBuffer);
    }
    _resultPixelBuffer = resultPixelBuffer;
}

- (GLAlphaBlendFilter *)blendFilter {
    if (!_blendFilter) {
        _blendFilter     = [[GLAlphaBlendFilter alloc] init];
        _blendFilter.mix = 1.0;
    }
    return _blendFilter;
}

- (PixelBufferProcessor *)pixelBufferProcessor {
    if (!_pixelBufferProcessor) {
        _pixelBufferProcessor = [[PixelBufferProcessor alloc] initWithContext:[[GLContext sharedImageProcessingContext] context]];
    }
    return _pixelBufferProcessor;
}

- (UILabel *)timeLabel {
    if (!_timeLabel) {
        _timeLabel                 = [[UILabel alloc] initWithFrame:CGRectZero];
        _timeLabel.textColor       = UIColor.redColor;
        _timeLabel.textAlignment   = NSTextAlignmentCenter;
        _timeLabel.font            = [UIFont systemFontOfSize:55];
        _timeLabel.backgroundColor = UIColor.clearColor;
    }
    return _timeLabel;
}

- (UIView *)contentView {
    if (!_contentView) {
        _contentView                 = [[UIView alloc] initWithFrame:CGRectZero];
        _contentView.backgroundColor = UIColor.clearColor;
    }
    return _contentView;
}

- (CVPixelBufferRef)outputPixelBuffer {
    if (!self.pixelBuffer) {
        return nil;
    }
    [self startRendering];
    return self.resultPixelBuffer;
}

- (NSDateFormatter *)formatter {
    if (!_formatter) {
        _formatter = [[NSDateFormatter alloc] init];
        [_formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
    }
    return _formatter;
}

- (void)startRendering {
    NSString *timeString = [self.formatter stringFromDate:[NSDate date]];
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self.contentView addSubview:self.timeLabel];
        self.timeLabel.text = timeString;
        [self.timeLabel sizeToFit];
        self.uiElement = [[GLUIElement alloc] initWithView:self.contentView];
    });

    CVPixelBufferRef pixelBuffer = [self renderByOpenGL:self.pixelBuffer];
    if (_pixelBufferNV12) {
        CVPixelBufferRelease(_pixelBufferNV12);
    }
    OSType        format          = CVPixelBufferGetPixelFormatType(self.pixelBuffer);
    NSDictionary *pixelAttributes = @{(NSString *)kCVPixelBufferIOSurfacePropertiesKey : @{}};

    if (kCVReturnSuccess != CVPixelBufferCreate(kCFAllocatorDefault, CVPixelBufferGetWidth(self.pixelBuffer), CVPixelBufferGetHeight(self.pixelBuffer), format, (__bridge CFDictionaryRef)(pixelAttributes), &_pixelBufferNV12)) {
        CVPixelBufferRelease(pixelBuffer);
        return;
    }
    if ([self RgbaToNV12PixelBuffer:pixelBuffer pixelBufferYUV:_pixelBufferNV12]) {
        self.resultPixelBuffer = _pixelBufferNV12;
    } else {
        self.resultPixelBuffer = pixelBuffer;
    }
    CVPixelBufferRelease(pixelBuffer);
}

// 用 OpenGL 加滤镜
- (CVPixelBufferRef)renderByOpenGL:(CVPixelBufferRef)pixelBuffer {
    CVPixelBufferRetain(pixelBuffer);
    __block CVPixelBufferRef output = nil;
    __block CGSize           labelSize;
    dispatch_sync(dispatch_get_main_queue(), ^{
        labelSize = self.timeLabel.bounds.size;
    });

    [self.blendFilter removeAllTargets];

    __weak typeof(self) weakSelf = self;
    runSynchronouslyOnVideoProcessingQueue(^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [GLContext useImageProcessingContext];
        GLuint textureID = [strongSelf.pixelBufferProcessor convertYUVPixelBufferToTexture:pixelBuffer];
        CGSize size      = CGSizeMake(CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer));
        [GLContext setActiveShaderProgram:nil];

        GLTextureInput *textureInput = [[GLTextureInput alloc] initWithTexture:textureID size:size];
        [textureInput addTarget:strongSelf.blendFilter];

        dispatch_sync(dispatch_get_main_queue(), ^{
            strongSelf.contentView.frame = CGRectMake(0, 0, size.width, size.height);
            strongSelf.timeLabel.frame   = CGRectMake((size.width - labelSize.width) * 0.5, size.width * 0.2, labelSize.width, labelSize.height);
        });
        [strongSelf.uiElement addTarget:strongSelf.blendFilter];

        GLTextureOutput *textureOutput = [[GLTextureOutput alloc] init];
        [strongSelf.blendFilter addTarget:textureOutput];
        [textureInput processTexture];

        [strongSelf.uiElement update];

        output = [strongSelf.pixelBufferProcessor convertTextureToPixelBuffer:textureOutput.texture textureSize:size];
        [textureOutput doneWithTexture];

        glDeleteTextures(1, &textureID);
    });
    CVPixelBufferRelease(pixelBuffer);

    return output;
}

- (BOOL)RgbaToNV12PixelBuffer:(CVPixelBufferRef)pixelBufferRGBA pixelBufferYUV:(CVPixelBufferRef)pixelBufferNV12 {
    CVPixelBufferLockBaseAddress(pixelBufferNV12, 0);
    unsigned char *y  = (unsigned char *)CVPixelBufferGetBaseAddressOfPlane(pixelBufferNV12, 0);
    unsigned char *uv = (unsigned char *)CVPixelBufferGetBaseAddressOfPlane(pixelBufferNV12, 1);
    CVPixelBufferLockBaseAddress(pixelBufferRGBA, 0);
    uint8_t *data = (uint8_t *)CVPixelBufferGetBaseAddress(pixelBufferRGBA);

    int32_t width  = (int32_t)CVPixelBufferGetWidth(pixelBufferNV12);
    int32_t height = (int32_t)CVPixelBufferGetHeight(pixelBufferNV12);

    size_t bgraStride = CVPixelBufferGetBytesPerRowOfPlane(pixelBufferRGBA, 0);
    size_t y_stride   = CVPixelBufferGetBytesPerRowOfPlane(pixelBufferNV12, 0);
    size_t uv_stride  = CVPixelBufferGetBytesPerRowOfPlane(pixelBufferNV12, 1);
    ARGBToNV12(data, (int)bgraStride, y, (int)y_stride, uv, (int)uv_stride, width, height);
    CVPixelBufferUnlockBaseAddress(pixelBufferRGBA, 0);
    CVPixelBufferUnlockBaseAddress(pixelBufferNV12, 0);
    return true;
}

- (void)dealloc {
    if (_pixelBuffer) {
        CVPixelBufferRelease(_pixelBuffer);
    }
    if (_resultPixelBuffer) {
        CVPixelBufferRelease(_resultPixelBuffer);
    }
    if (_pixelBufferNV12) {
        CVPixelBufferRelease(_pixelBufferNV12);
    }
}

@end
