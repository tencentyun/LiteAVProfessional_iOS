//
//  GLFramebuffer.h
//  WaterMarkDemo
//
//  Created by adams on 2021/7/6.
//

#import <CoreMedia/CoreMedia.h>
#import <Foundation/Foundation.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

typedef struct GLTextureOptions {
    GLenum minFilter;
    GLenum magFilter;
    GLenum wrapS;
    GLenum wrapT;
    GLenum internalFormat;
    GLenum format;
    GLenum type;
} GLTextureOptions;

@interface                                   GLFramebuffer : NSObject
@property(readonly, assign) CGSize           size;
@property(readonly, assign) GLTextureOptions textureOptions;
@property(readonly, assign) GLuint           texture;
@property(readonly, assign) BOOL             missingFramebuffer;

- (id)initWithSize:(CGSize)framebufferSize;
- (id)initWithSize:(CGSize)framebufferSize textureOptions:(GLTextureOptions)fboTextureOptions onlyTexture:(BOOL)onlyGenerateTexture;
- (id)initWithSize:(CGSize)framebufferSize overriddenTexture:(GLuint)inputTexture;

- (void)activateFramebuffer;

- (void)lock;
- (void)unlock;
- (void)clearAllLocks;
- (void)disableReferenceCounting;
- (void)enableReferenceCounting;

- (void)restoreRenderTarget;

- (void)lockForReading;
- (void)unlockAfterReading;
- (NSUInteger)bytesPerRow;
- (GLubyte *)byteBuffer;

@end

NS_ASSUME_NONNULL_END
