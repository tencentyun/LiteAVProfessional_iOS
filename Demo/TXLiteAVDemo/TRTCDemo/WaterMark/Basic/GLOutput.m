//
//  GLOutput.m
//  WaterMarkDemo
//
//  Created by adams on 2021/7/6.
//

#import "GLOutput.h"
#import <mach/mach.h>

dispatch_queue_attr_t GLDefaultQueueAttribute(void) {
    if ([[[UIDevice currentDevice] systemVersion] compare:@"9.0" options:NSNumericSearch] != NSOrderedAscending) {
        return dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_DEFAULT, 0);
    }
    return nil;
}

void runSynchronouslyOnVideoProcessingQueue(void (^block)(void)) {
    dispatch_queue_t videoProcessingQueue = [GLContext sharedContextQueue];
    if (dispatch_get_specific([GLContext contextKey])) {
        block();
    } else {
        dispatch_sync(videoProcessingQueue, block);
    }
}

void runAsynchronouslyOnVideoProcessingQueue(void (^block)(void)) {
    dispatch_queue_t videoProcessingQueue = [GLContext sharedContextQueue];
    if (dispatch_get_specific([GLContext contextKey])) {
        block();
    } else {
        dispatch_async(videoProcessingQueue, block);
    }
}

@implementation GLOutput

@synthesize shouldSmoothlyScaleOutput = _shouldSmoothlyScaleOutput;
@synthesize shouldIgnoreUpdatesToThisTarget = _shouldIgnoreUpdatesToThisTarget;
@synthesize targetToIgnoreForUpdates = _targetToIgnoreForUpdates;
@synthesize frameProcessingCompletionBlock = _frameProcessingCompletionBlock;
@synthesize enabled = _enabled;
@synthesize outputTextureOptions = _outputTextureOptions;

- (id)init {
    if (self == [super init]) {
        targets = [[NSMutableArray alloc] init];
        targetTextureIndices = [[NSMutableArray alloc] init];
        _enabled = YES;
        allTargetsWantMonochromeData = YES;
        usingNextFrameForImageCapture = NO;
        
        _outputTextureOptions.minFilter = GL_LINEAR;
        _outputTextureOptions.magFilter = GL_LINEAR;
        _outputTextureOptions.wrapS = GL_CLAMP_TO_EDGE;
        _outputTextureOptions.wrapT = GL_CLAMP_TO_EDGE;
        _outputTextureOptions.internalFormat = GL_RGBA;
        _outputTextureOptions.format = GL_BGRA;
        _outputTextureOptions.type = GL_UNSIGNED_BYTE;
    }
    return self;
}

- (void)dealloc {
    [self removeAllTargets];
}

- (void)setInputFramebufferForTarget:(id<GLInput>)target atIndex:(NSInteger)inputTextureIndex {
    [target setInputFramebuffer:[self framebufferForOutput] atIndex:inputTextureIndex];
}

- (GLFramebuffer *)framebufferForOutput {
    return outputFramebuffer;
}

- (void)removeOutputFramebuffer {
    outputFramebuffer = nil;
}

- (void)notifyTargetsAboutNewOutputTexture {
    for (id<GLInput> currentTarget in targets) {
        NSInteger indexOfObject = [targets indexOfObject:currentTarget];
        NSInteger textureIndex = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
        [self setInputFramebufferForTarget:currentTarget atIndex:textureIndex];
    }
}

- (NSArray*)targets {
    return [NSArray arrayWithArray:targets];
}

- (void)addTarget:(id<GLInput>)newTarget {
    NSInteger nextAvailableTextureIndex = [newTarget nextAvailableTextureIndex];
    [self addTarget:newTarget atTextureLocation:nextAvailableTextureIndex];
    
    if ([newTarget shouldIgnoreUpdatesToThisTarget])
    {
        _targetToIgnoreForUpdates = newTarget;
    }
}

- (void)addTarget:(id<GLInput>)newTarget atTextureLocation:(NSInteger)textureLocation {
    if([targets containsObject:newTarget]) {
        return;
    }
    
    cachedMaximumOutputSize = CGSizeZero;
    runSynchronouslyOnVideoProcessingQueue(^{
        [self setInputFramebufferForTarget:newTarget atIndex:textureLocation];
        [targets addObject:newTarget];
        [targetTextureIndices addObject:[NSNumber numberWithInteger:textureLocation]];
        allTargetsWantMonochromeData = allTargetsWantMonochromeData && [newTarget wantsMonochromeInput];
    });
}

- (void)removeTarget:(id<GLInput>)targetToRemove {
    if(![targets containsObject:targetToRemove]) {
        return;
    }
    
    if (_targetToIgnoreForUpdates == targetToRemove) {
        _targetToIgnoreForUpdates = nil;
    }
    
    cachedMaximumOutputSize = CGSizeZero;
    
    NSInteger indexOfObject = [targets indexOfObject:targetToRemove];
    NSInteger textureIndexOfTarget = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];

    runSynchronouslyOnVideoProcessingQueue(^{
        [targetToRemove setInputSize:CGSizeZero atIndex:textureIndexOfTarget];
        [targetTextureIndices removeObjectAtIndex:indexOfObject];
        [targets removeObject:targetToRemove];
    });
}

- (void)removeAllTargets {
    cachedMaximumOutputSize = CGSizeZero;
    runSynchronouslyOnVideoProcessingQueue(^{
        for (id<GLInput> targetToRemove in targets) {
            NSInteger indexOfObject = [targets indexOfObject:targetToRemove];
            NSInteger textureIndexOfTarget = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
            [targetToRemove setInputSize:CGSizeZero atIndex:textureIndexOfTarget];
        }
        [targets removeAllObjects];
        [targetTextureIndices removeAllObjects];
        
        allTargetsWantMonochromeData = YES;
    });
}

- (void)forceProcessingAtSize:(CGSize)frameSize {
}

- (void)forceProcessingAtSizeRespectingAspectRatio:(CGSize)frameSize {
}

- (void)useNextFrameForImageCapture {
}

@end
