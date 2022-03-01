//
//  GLFramebufferCache.h
//  WaterMarkDemo
//
//  Created by adams on 2021/7/6.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <QuartzCore/QuartzCore.h>

#import "GLFramebuffer.h"
NS_ASSUME_NONNULL_BEGIN

@interface GLFramebufferCache : NSObject
- (GLFramebuffer *)fetchFramebufferForSize:(CGSize)framebufferSize textureOptions:(GLTextureOptions)textureOptions onlyTexture:(BOOL)onlyTexture;
- (GLFramebuffer *)fetchFramebufferForSize:(CGSize)framebufferSize onlyTexture:(BOOL)onlyTexture;
- (void)returnFramebufferToCache:(GLFramebuffer *)framebuffer;
- (void)purgeAllUnassignedFramebuffers;
- (void)addFramebufferToActiveImageCaptureList:(GLFramebuffer *)framebuffer;
- (void)removeFramebufferFromActiveImageCaptureList:(GLFramebuffer *)framebuffer;
@end

NS_ASSUME_NONNULL_END
