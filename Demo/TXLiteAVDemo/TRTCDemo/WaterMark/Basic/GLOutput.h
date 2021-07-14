//
//  GLOutput.h
//  WaterMarkDemo
//
//  Created by adams on 2021/7/6.
//

#import "GLContext.h"
#import "GLFramebuffer.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

dispatch_queue_attr_t GLDefaultQueueAttribute(void);

void runSynchronouslyOnVideoProcessingQueue(void (^block)(void));
void runAsynchronouslyOnVideoProcessingQueue(void (^block)(void));

@interface GLOutput : NSObject
{
    GLFramebuffer *outputFramebuffer;
    NSMutableArray *targets, *targetTextureIndices;
    CGSize inputTextureSize, cachedMaximumOutputSize, forcedMaximumSize;
    BOOL overrideInputSize;
    BOOL allTargetsWantMonochromeData;
    BOOL usingNextFrameForImageCapture;
}

@property(readwrite, nonatomic) BOOL shouldSmoothlyScaleOutput;
@property(readwrite, nonatomic) BOOL shouldIgnoreUpdatesToThisTarget;
@property(readwrite, nonatomic, unsafe_unretained) id<GLInput> targetToIgnoreForUpdates;
@property(nonatomic, copy) void(^frameProcessingCompletionBlock)(GLOutput*, CMTime);
@property(nonatomic, assign) BOOL enabled;
@property(readwrite, nonatomic) GLTextureOptions outputTextureOptions;


- (void)setInputFramebufferForTarget:(id<GLInput>)target atIndex:(NSInteger)inputTextureIndex;
- (GLFramebuffer *)framebufferForOutput;
- (void)removeOutputFramebuffer;
- (void)notifyTargetsAboutNewOutputTexture;
 
- (NSArray*)targets;
- (void)addTarget:(id<GLInput>)newTarget;
- (void)addTarget:(id<GLInput>)newTarget atTextureLocation:(NSInteger)textureLocation;
- (void)removeTarget:(id<GLInput>)targetToRemove;
- (void)removeAllTargets;

- (void)forceProcessingAtSize:(CGSize)frameSize;
- (void)forceProcessingAtSizeRespectingAspectRatio:(CGSize)frameSize;

- (void)useNextFrameForImageCapture;

@end

NS_ASSUME_NONNULL_END
