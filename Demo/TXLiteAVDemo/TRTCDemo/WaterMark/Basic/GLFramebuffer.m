//
//  GLFramebuffer.m
//  WaterMarkDemo
//
//  Created by adams on 2021/7/6.
//

#import "GLFramebuffer.h"

#import "GLOutput.h"

@interface GLFramebuffer () {
    GLuint               framebuffer;
    CVPixelBufferRef     renderTarget;
    CVOpenGLESTextureRef renderTexture;
    NSUInteger           readLockCount;
    NSUInteger           framebufferReferenceCount;
    BOOL                 referenceCountingDisabled;
}
@end

@implementation GLFramebuffer

@synthesize size               = _size;
@synthesize textureOptions     = _textureOptions;
@synthesize texture            = _texture;
@synthesize missingFramebuffer = _missingFramebuffer;

- (id)initWithSize:(CGSize)framebufferSize textureOptions:(GLTextureOptions)fboTextureOptions onlyTexture:(BOOL)onlyGenerateTexture {
    if (self == [super init]) {
        _textureOptions           = fboTextureOptions;
        _size                     = framebufferSize;
        framebufferReferenceCount = 0;
        referenceCountingDisabled = NO;
        _missingFramebuffer       = onlyGenerateTexture;

        if (_missingFramebuffer) {
            runSynchronouslyOnVideoProcessingQueue(^{
                [GLContext useImageProcessingContext];
                [self generateTexture];
                self->framebuffer = 0;
            });
        } else {
            [self generateFramebuffer];
        }
    }
    return self;
}

- (id)initWithSize:(CGSize)framebufferSize overriddenTexture:(GLuint)inputTexture {
    if (self == [super init]) {
        GLTextureOptions defaultTextureOptions;
        defaultTextureOptions.minFilter      = GL_LINEAR;
        defaultTextureOptions.magFilter      = GL_LINEAR;
        defaultTextureOptions.wrapS          = GL_CLAMP_TO_EDGE;
        defaultTextureOptions.wrapT          = GL_CLAMP_TO_EDGE;
        defaultTextureOptions.internalFormat = GL_RGBA;
        defaultTextureOptions.format         = GL_BGRA;
        defaultTextureOptions.type           = GL_UNSIGNED_BYTE;

        _textureOptions           = defaultTextureOptions;
        _size                     = framebufferSize;
        framebufferReferenceCount = 0;
        referenceCountingDisabled = YES;

        _texture = inputTexture;
    }
    return self;
}

- (id)initWithSize:(CGSize)framebufferSize {
    GLTextureOptions defaultTextureOptions;
    defaultTextureOptions.minFilter      = GL_LINEAR;
    defaultTextureOptions.magFilter      = GL_LINEAR;
    defaultTextureOptions.wrapS          = GL_CLAMP_TO_EDGE;
    defaultTextureOptions.wrapT          = GL_CLAMP_TO_EDGE;
    defaultTextureOptions.internalFormat = GL_RGBA;
    defaultTextureOptions.format         = GL_BGRA;
    defaultTextureOptions.type           = GL_UNSIGNED_BYTE;

    if (self == [self initWithSize:framebufferSize textureOptions:defaultTextureOptions onlyTexture:NO]) {
    }
    return self;
}

- (void)dealloc {
    [self destroyFramebuffer];
}

- (void)generateTexture {
    glActiveTexture(GL_TEXTURE1);
    glGenTextures(1, &_texture);
    glBindTexture(GL_TEXTURE_2D, _texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, _textureOptions.minFilter);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, _textureOptions.magFilter);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, _textureOptions.wrapS);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, _textureOptions.wrapT);
}

- (void)generateFramebuffer {
    runSynchronouslyOnVideoProcessingQueue(^{
        [GLContext useImageProcessingContext];
        glGenFramebuffers(1, &framebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);

        if ([GLContext supportsFastTextureUpload]) {
            CVOpenGLESTextureCacheRef coreVideoTextureCache = [[GLContext sharedImageProcessingContext] coreVideoTextureCache];
            CFDictionaryRef           empty;
            CFMutableDictionaryRef    attrs;
            empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
            attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
            CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
            CVReturn err = CVPixelBufferCreate(kCFAllocatorDefault, (int)_size.width, (int)_size.height, kCVPixelFormatType_32BGRA, attrs, &renderTarget);
            if (err) {
                NSLog(@"FBO size: %f, %f", _size.width, _size.height);
                NSAssert(NO, @"Error at CVPixelBufferCreate %d", err);
            }
            err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, coreVideoTextureCache, renderTarget,
                                                               NULL,  // texture attributes
                                                               GL_TEXTURE_2D,
                                                               _textureOptions.internalFormat,  // opengl format
                                                               (int)_size.width, (int)_size.height,
                                                               _textureOptions.format,  // native iOS format
                                                               _textureOptions.type, 0, &renderTexture);
            if (err) {
                NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
            }

            CFRelease(attrs);
            CFRelease(empty);

            glBindTexture(CVOpenGLESTextureGetTarget(renderTexture), CVOpenGLESTextureGetName(renderTexture));
            _texture = CVOpenGLESTextureGetName(renderTexture);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, _textureOptions.wrapS);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, _textureOptions.wrapT);

            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(renderTexture), 0);
        } else {
            [self generateTexture];
            glBindTexture(GL_TEXTURE_2D, _texture);
            glTexImage2D(GL_TEXTURE_2D, 0, _textureOptions.internalFormat, (int)_size.width, (int)_size.height, 0, _textureOptions.format, _textureOptions.type, 0);
            glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _texture, 0);
        }

#ifndef NS_BLOCK_ASSERTIONS
        GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"Incomplete filter FBO: %d", status);
#endif
        glBindTexture(GL_TEXTURE_2D, 0);
    });
}

- (void)destroyFramebuffer {
    runSynchronouslyOnVideoProcessingQueue(^{
        [GLContext useImageProcessingContext];
        if (framebuffer) {
            glDeleteFramebuffers(1, &framebuffer);
            framebuffer = 0;
        }

        if ([GLContext supportsFastTextureUpload] && (!_missingFramebuffer)) {
            if (renderTarget) {
                CFRelease(renderTarget);
                renderTarget = NULL;
            }

            if (renderTexture) {
                CFRelease(renderTexture);
                renderTexture = NULL;
            }
        } else {
            glDeleteTextures(1, &_texture);
        }
    });
}

- (void)activateFramebuffer {
    NSLog(@"activateFramebuffer id:%d", framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    glViewport(0, 0, (int)_size.width, (int)_size.height);
}

- (void)lock {
    if (referenceCountingDisabled) {
        return;
    }
    framebufferReferenceCount++;
}

- (void)unlock {
    if (referenceCountingDisabled) {
        return;
    }
    NSAssert(framebufferReferenceCount > 0, @"Tried to overrelease a framebuffer, did you forget to call -useNextFrameForImageCapture before using -imageFromCurrentFramebuffer?");
    framebufferReferenceCount--;
    if (framebufferReferenceCount < 1) {
        [[GLContext sharedFramebufferCache] returnFramebufferToCache:self];
    }
}

- (void)clearAllLocks {
    framebufferReferenceCount = 0;
}

- (void)disableReferenceCounting {
    referenceCountingDisabled = YES;
}

- (void)enableReferenceCounting {
    referenceCountingDisabled = NO;
}

void dataProviderUnlockCallback(void *info, const void *data, size_t size) {
    GLFramebuffer *framebuffer = (__bridge_transfer GLFramebuffer *)info;
    [framebuffer restoreRenderTarget];
    [framebuffer unlock];
    [[GLContext sharedFramebufferCache] removeFramebufferFromActiveImageCaptureList:framebuffer];
}

- (void)restoreRenderTarget {
    [self unlockAfterReading];
    CFRelease(renderTarget);
}

- (void)lockForReading {
    if ([GLContext supportsFastTextureUpload]) {
        if (readLockCount == 0) {
            CVPixelBufferLockBaseAddress(renderTarget, 0);
        }
        readLockCount++;
    }
}

- (void)unlockAfterReading {
    if ([GLContext supportsFastTextureUpload]) {
        NSAssert(readLockCount > 0, @"Unbalanced call to -[GLFramebuffer unlockAfterReading]");
        readLockCount--;
        if (readLockCount == 0) {
            CVPixelBufferUnlockBaseAddress(renderTarget, 0);
        }
    }
}

- (NSUInteger)bytesPerRow {
    if ([GLContext supportsFastTextureUpload]) {
        return CVPixelBufferGetBytesPerRow(renderTarget);
    } else {
        return _size.width * 4;
    }
}

- (GLubyte *)byteBuffer {
    [self lockForReading];
    GLubyte *bufferBytes = CVPixelBufferGetBaseAddress(renderTarget);
    [self unlockAfterReading];
    return bufferBytes;
}

- (GLuint)texture {
    return _texture;
}

@end
