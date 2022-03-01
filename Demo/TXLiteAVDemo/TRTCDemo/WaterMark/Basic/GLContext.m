//
//  GLContext.m
//  WaterMarkDemo
//
//  Created by adams on 2021/7/6.
//

#import "GLContext.h"

extern dispatch_queue_attr_t GLDefaultQueueAttribute(void);

@interface GLContext () {
    NSMutableDictionary *shaderProgramCache;
    NSMutableArray *     shaderProgramUsageHistory;
    EAGLSharegroup *     _sharegroup;
}
@end

@implementation GLContext
@synthesize     context               = _context;
@synthesize     currentShaderProgram  = _currentShaderProgram;
@synthesize     contextQueue          = _contextQueue;
@synthesize     coreVideoTextureCache = _coreVideoTextureCache;
@synthesize     framebufferCache      = _framebufferCache;

static void *openGLESContextQueueKey;

- (id)init {
    if (self == [super init]) {
        openGLESContextQueueKey = &openGLESContextQueueKey;
        _contextQueue           = dispatch_queue_create("com.adams.gl.openGLESContextQueue", GLDefaultQueueAttribute());
        dispatch_queue_set_specific(_contextQueue, openGLESContextQueueKey, (__bridge void *)self, NULL);
        shaderProgramCache        = [[NSMutableDictionary alloc] init];
        shaderProgramUsageHistory = [[NSMutableArray alloc] init];
    }
    return self;
}

+ (void *)contextKey {
    return openGLESContextQueueKey;
}

+ (GLContext *)sharedImageProcessingContext {
    static dispatch_once_t pred;
    static GLContext *     sharedImageProcessingContext = nil;
    dispatch_once(&pred, ^{
        sharedImageProcessingContext = [[[self class] alloc] init];
    });
    return sharedImageProcessingContext;
}

+ (dispatch_queue_t)sharedContextQueue {
    return [[self sharedImageProcessingContext] contextQueue];
}

+ (GLFramebufferCache *)sharedFramebufferCache {
    return [[self sharedImageProcessingContext] framebufferCache];
}

+ (void)useImageProcessingContext {
    [[GLContext sharedImageProcessingContext] useAsCurrentContext];
}

- (void)useAsCurrentContext {
    EAGLContext *imageProcessingContext = [self context];
    if ([EAGLContext currentContext] != imageProcessingContext) {
        [EAGLContext setCurrentContext:imageProcessingContext];
    }
}

+ (void)setActiveShaderProgram:(GLProgram *)shaderProgram {
    GLContext *sharedContext = [GLContext sharedImageProcessingContext];
    [sharedContext setContextShaderProgram:shaderProgram];
}

- (void)setContextShaderProgram:(GLProgram *)shaderProgram {
    EAGLContext *imageProcessingContext = [self context];
    if ([EAGLContext currentContext] != imageProcessingContext) {
        [EAGLContext setCurrentContext:imageProcessingContext];
    }

    if (self.currentShaderProgram != shaderProgram) {
        self.currentShaderProgram = shaderProgram;
        [shaderProgram use];
    }
}

+ (GLint)maximumTextureSizeForThisDevice {
    static dispatch_once_t pred;
    static GLint           maxTextureSize = 0;

    dispatch_once(&pred, ^{
        [self useImageProcessingContext];
        glGetIntegerv(GL_MAX_TEXTURE_SIZE, &maxTextureSize);
    });

    return maxTextureSize;
}

+ (GLint)maximumTextureUnitsForThisDevice {
    static dispatch_once_t pred;
    static GLint           maxTextureUnits = 0;

    dispatch_once(&pred, ^{
        [self useImageProcessingContext];
        glGetIntegerv(GL_MAX_TEXTURE_IMAGE_UNITS, &maxTextureUnits);
    });

    return maxTextureUnits;
}

+ (GLint)maximumVaryingVectorsForThisDevice {
    static dispatch_once_t pred;
    static GLint           maxVaryingVectors = 0;

    dispatch_once(&pred, ^{
        [self useImageProcessingContext];
        glGetIntegerv(GL_MAX_VARYING_VECTORS, &maxVaryingVectors);
    });

    return maxVaryingVectors;
}

+ (BOOL)deviceSupportsOpenGLESExtension:(NSString *)extension {
    static dispatch_once_t pred;
    static NSArray *       extensionNames = nil;

    dispatch_once(&pred, ^{
        [GLContext useImageProcessingContext];
        NSString *extensionsString = [NSString stringWithCString:(const char *)glGetString(GL_EXTENSIONS) encoding:NSASCIIStringEncoding];
        extensionNames             = [extensionsString componentsSeparatedByString:@" "];
    });

    return [extensionNames containsObject:extension];
}

+ (BOOL)deviceSupportsRedTextures {
    static dispatch_once_t pred;
    static BOOL            supportsRedTextures = NO;

    dispatch_once(&pred, ^{
        supportsRedTextures = [GLContext deviceSupportsOpenGLESExtension:@"GL_EXT_texture_rg"];
    });

    return supportsRedTextures;
}

+ (BOOL)deviceSupportsFramebufferReads {
    static dispatch_once_t pred;
    static BOOL            supportsFramebufferReads = NO;

    dispatch_once(&pred, ^{
        supportsFramebufferReads = [GLContext deviceSupportsOpenGLESExtension:@"GL_EXT_shader_framebuffer_fetch"];
    });

    return supportsFramebufferReads;
}

+ (CGSize)sizeThatFitsWithinATextureForSize:(CGSize)inputSize {
    GLint maxTextureSize = [self maximumTextureSizeForThisDevice];
    if ((inputSize.width < maxTextureSize) && (inputSize.height < maxTextureSize)) {
        return inputSize;
    }

    CGSize adjustedSize;
    if (inputSize.width > inputSize.height) {
        adjustedSize.width  = (CGFloat)maxTextureSize;
        adjustedSize.height = ((CGFloat)maxTextureSize / inputSize.width) * inputSize.height;
    } else {
        adjustedSize.height = (CGFloat)maxTextureSize;
        adjustedSize.width  = ((CGFloat)maxTextureSize / inputSize.height) * inputSize.width;
    }

    return adjustedSize;
}

- (void)presentBufferForDisplay {
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

- (GLProgram *)programForVertexShaderString:(NSString *)vertexShaderString fragmentShaderString:(NSString *)fragmentShaderString {
    NSString * lookupKeyForShaderProgram = [NSString stringWithFormat:@"V: %@ - F: %@", vertexShaderString, fragmentShaderString];
    GLProgram *programFromCache          = [shaderProgramCache objectForKey:lookupKeyForShaderProgram];

    if (programFromCache == nil) {
        programFromCache = [[GLProgram alloc] initWithVertexShaderString:vertexShaderString fragmentShaderString:fragmentShaderString];
        [shaderProgramCache setObject:programFromCache forKey:lookupKeyForShaderProgram];
    }

    return programFromCache;
}

- (void)useSharegroup:(EAGLSharegroup *)sharegroup {
    NSAssert(_context == nil, @"Unable to use a share group when the context has already been created. Call this method before you use the context for the first time.");
    _sharegroup = sharegroup;
}

- (EAGLContext *)createContext {
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2 sharegroup:_sharegroup];
    NSAssert(context != nil, @"Unable to create an OpenGL ES 2.0 context. The OpenGL ES 2.0 support to work.");
    return context;
}

+ (BOOL)supportsFastTextureUpload {
#if TARGET_IPHONE_SIMULATOR
    return NO;
#else

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wtautological-pointer-compare"
    return (CVOpenGLESTextureCacheCreate != NULL);
#pragma clang diagnostic pop

#endif
}

- (EAGLContext *)context {
    if (!_context) {
        _context = [self createContext];
        [EAGLContext setCurrentContext:_context];
        glDisable(GL_DEPTH_TEST);
    }
    return _context;
}

- (CVOpenGLESTextureCacheRef)coreVideoTextureCache {
    if (!_coreVideoTextureCache) {
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, [self context], NULL, &_coreVideoTextureCache);
        if (err) {
            NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreate %d", err);
        }
    }
    return _coreVideoTextureCache;
}

- (GLFramebufferCache *)framebufferCache {
    if (!_framebufferCache) {
        _framebufferCache = [[GLFramebufferCache alloc] init];
    }
    return _framebufferCache;
}

@end
