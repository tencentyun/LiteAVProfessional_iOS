//
//  GLContext.h
//  WaterMarkDemo
//
//  Created by adams on 2021/7/6.
//

#import "GLProgram.h"
#import "GLFramebuffer.h"
#import "GLFramebufferCache.h"

NS_ASSUME_NONNULL_BEGIN

#define GLRotationSwapsWidthAndHeight(rotation) ((rotation) == kGLRotateLeft || (rotation) == kGLRotateRight || (rotation) == kGLRotateRightFlipVertical || (rotation) == kGLRotateRightFlipHorizontal)

typedef NS_ENUM(NSUInteger, GLRotationMode) {
    kGLNoRotation,
    kGLRotateLeft,
    kGLRotateRight,
    kGLFlipVertical,
    kGLFlipHorizonal,
    kGLRotateRightFlipVertical,
    kGLRotateRightFlipHorizontal,
    kGLRotate180
};

@protocol GLInput <NSObject>
- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex;
- (void)setInputFramebuffer:(GLFramebufferCache *)newInputFramebuffer atIndex:(NSInteger)textureIndex;
- (NSInteger)nextAvailableTextureIndex;
- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex;

- (CGSize)maximumOutputSize;
- (void)endProcessing;
- (BOOL)shouldIgnoreUpdatesToThisTarget;
- (BOOL)enabled;
- (BOOL)wantsMonochromeInput;
- (void)setCurrentlyReceivingMonochromeInput:(BOOL)newValue;
@end

@interface GLContext : NSObject
@property(readonly, nonatomic) dispatch_queue_t contextQueue;
@property(readwrite, retain, nonatomic) GLProgram *currentShaderProgram;
@property(readonly, retain, nonatomic) EAGLContext *context;
@property(readonly) CVOpenGLESTextureCacheRef coreVideoTextureCache;
@property(readonly) GLFramebufferCache *framebufferCache;

+ (void *)contextKey;
+ (GLContext *)sharedImageProcessingContext;
+ (dispatch_queue_t)sharedContextQueue;
+ (GLFramebufferCache *)sharedFramebufferCache;
+ (void)useImageProcessingContext;
- (void)useAsCurrentContext;
+ (void)setActiveShaderProgram:(GLProgram *)shaderProgram;
- (void)setContextShaderProgram:(GLProgram *)shaderProgram;
+ (GLint)maximumTextureSizeForThisDevice;
+ (GLint)maximumTextureUnitsForThisDevice;
+ (GLint)maximumVaryingVectorsForThisDevice;
+ (BOOL)deviceSupportsOpenGLESExtension:(NSString *)extension;
+ (BOOL)deviceSupportsRedTextures;
+ (BOOL)deviceSupportsFramebufferReads;
+ (CGSize)sizeThatFitsWithinATextureForSize:(CGSize)inputSize;

- (void)presentBufferForDisplay;
- (GLProgram *)programForVertexShaderString:(NSString *)vertexShaderString fragmentShaderString:(NSString *)fragmentShaderString;

- (void)useSharegroup:(EAGLSharegroup *)sharegroup;

// Manage fast texture upload
+ (BOOL)supportsFastTextureUpload;
@end

NS_ASSUME_NONNULL_END
