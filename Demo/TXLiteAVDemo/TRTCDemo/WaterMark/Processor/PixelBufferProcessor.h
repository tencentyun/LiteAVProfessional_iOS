//
//  PixelBufferProcessor.h
//  WaterMarkDemo
//
//  Created by adams on 2021/7/7.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PixelBufferProcessor : NSObject

- (instancetype)initWithContext:(EAGLContext *)context;

/// 创建 RGB 格式的 pixelBuffer
- (CVPixelBufferRef)createPixelBufferWithSize:(CGSize)size;

/// YUV 格式的 PixelBuffer 转化为纹理
- (GLuint)convertYUVPixelBufferToTexture:(CVPixelBufferRef)pixelBuffer;

/// RBG 格式的 PixelBuffer 转化为纹理
- (GLuint)convertRGBPixelBufferToTexture:(CVPixelBufferRef)pixelBuffer;

/// 纹理转化为 RGB 格式的 pixelBuffer
- (CVPixelBufferRef)convertTextureToPixelBuffer:(GLuint)texture textureSize:(CGSize)textureSize;

@end

NS_ASSUME_NONNULL_END
