//
//  GLFramebufferCache.m
//  WaterMarkDemo
//
//  Created by adams on 2021/7/6.
//

#import "GLFramebufferCache.h"
#import "GLContext.h"
#import "GLFramebuffer.h"
#import <UIKit/UIKit.h>
#import "GLOutput.h"

@interface GLFramebufferCache()
{
    NSMutableDictionary *framebufferCache;
    NSMutableDictionary *framebufferTypeCounts;
    NSMutableArray *activeImageCaptureList;
    id memoryWarningObserver;
    dispatch_queue_t framebufferCacheQueue;
}
@end

@implementation GLFramebufferCache
- (id)init {
    if (self == [super init]) {
        __unsafe_unretained __typeof__ (self) weakSelf = self;
        memoryWarningObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidReceiveMemoryWarningNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
            __typeof__ (self) strongSelf = weakSelf;
            if (strongSelf) {
                [strongSelf purgeAllUnassignedFramebuffers];
            }
        }];
        
        framebufferCache = [[NSMutableDictionary alloc] init];
        framebufferTypeCounts = [[NSMutableDictionary alloc] init];
        activeImageCaptureList = [[NSMutableArray alloc] init];
        framebufferCacheQueue = dispatch_queue_create("com.adams.gl.framebufferCacheQueue", GLDefaultQueueAttribute());
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSString *)hashForSize:(CGSize)size textureOptions:(GLTextureOptions)textureOptions onlyTexture:(BOOL)onlyTexture {
    if (onlyTexture) {
        return [NSString stringWithFormat:@"%.1fx%.1f-%d:%d:%d:%d:%d:%d:%d-NOFB", size.width, size.height, textureOptions.minFilter, textureOptions.magFilter, textureOptions.wrapS, textureOptions.wrapT, textureOptions.internalFormat, textureOptions.format, textureOptions.type];
    } else {
        return [NSString stringWithFormat:@"%.1fx%.1f-%d:%d:%d:%d:%d:%d:%d", size.width, size.height, textureOptions.minFilter, textureOptions.magFilter, textureOptions.wrapS, textureOptions.wrapT, textureOptions.internalFormat, textureOptions.format, textureOptions.type];
    }
}

- (GLFramebuffer *)fetchFramebufferForSize:(CGSize)framebufferSize textureOptions:(GLTextureOptions)textureOptions onlyTexture:(BOOL)onlyTexture;
{
    __block GLFramebuffer *framebufferFromCache = nil;
    runSynchronouslyOnVideoProcessingQueue(^{
        NSString *lookupHash = [self hashForSize:framebufferSize textureOptions:textureOptions onlyTexture:onlyTexture];
        NSNumber *numberOfMatchingTexturesInCache = [framebufferTypeCounts objectForKey:lookupHash];
        NSInteger numberOfMatchingTextures = [numberOfMatchingTexturesInCache integerValue];
        
        if ([numberOfMatchingTexturesInCache integerValue] < 1) {
            framebufferFromCache = [[GLFramebuffer alloc] initWithSize:framebufferSize textureOptions:textureOptions onlyTexture:onlyTexture];
        } else {
            NSInteger currentTextureID = (numberOfMatchingTextures - 1);
            while ((framebufferFromCache == nil) && (currentTextureID >= 0))
            {
                NSString *textureHash = [NSString stringWithFormat:@"%@-%ld", lookupHash, (long)currentTextureID];
                framebufferFromCache = [framebufferCache objectForKey:textureHash];
                if (framebufferFromCache != nil) {
                    [framebufferCache removeObjectForKey:textureHash];
                }
                currentTextureID--;
            }
            currentTextureID++;
            [framebufferTypeCounts setObject:[NSNumber numberWithInteger:currentTextureID] forKey:lookupHash];
            
            if (framebufferFromCache == nil) {
                framebufferFromCache = [[GLFramebuffer alloc] initWithSize:framebufferSize textureOptions:textureOptions onlyTexture:onlyTexture];
            }
        }
        
    });

    [framebufferFromCache lock];
    return framebufferFromCache;
}

- (GLFramebuffer *)fetchFramebufferForSize:(CGSize)framebufferSize onlyTexture:(BOOL)onlyTexture {
    GLTextureOptions defaultTextureOptions;
    defaultTextureOptions.minFilter = GL_LINEAR;
    defaultTextureOptions.magFilter = GL_LINEAR;
    defaultTextureOptions.wrapS = GL_CLAMP_TO_EDGE;
    defaultTextureOptions.wrapT = GL_CLAMP_TO_EDGE;
    defaultTextureOptions.internalFormat = GL_RGBA;
    defaultTextureOptions.format = GL_BGRA;
    defaultTextureOptions.type = GL_UNSIGNED_BYTE;
    
    return [self fetchFramebufferForSize:framebufferSize textureOptions:defaultTextureOptions onlyTexture:onlyTexture];
}

- (void)returnFramebufferToCache:(GLFramebuffer *)framebuffer {
    [framebuffer clearAllLocks];
    runAsynchronouslyOnVideoProcessingQueue(^{
        CGSize framebufferSize = framebuffer.size;
        GLTextureOptions framebufferTextureOptions = framebuffer.textureOptions;
        NSString *lookupHash = [self hashForSize:framebufferSize textureOptions:framebufferTextureOptions onlyTexture:framebuffer.missingFramebuffer];
        NSNumber *numberOfMatchingTexturesInCache = [framebufferTypeCounts objectForKey:lookupHash];
        NSInteger numberOfMatchingTextures = [numberOfMatchingTexturesInCache integerValue];
        NSString *textureHash = [NSString stringWithFormat:@"%@-%ld", lookupHash, (long)numberOfMatchingTextures];
        [framebufferCache setObject:framebuffer forKey:textureHash];
        [framebufferTypeCounts setObject:[NSNumber numberWithInteger:(numberOfMatchingTextures + 1)] forKey:lookupHash];
    });
}

- (void)purgeAllUnassignedFramebuffers {
    runAsynchronouslyOnVideoProcessingQueue(^{
        [framebufferCache removeAllObjects];
        [framebufferTypeCounts removeAllObjects];
        CVOpenGLESTextureCacheFlush([[GLContext sharedImageProcessingContext] coreVideoTextureCache], 0);
    });
}

- (void)addFramebufferToActiveImageCaptureList:(GLFramebuffer *)framebuffer {
    runAsynchronouslyOnVideoProcessingQueue(^{
        [activeImageCaptureList addObject:framebuffer];
    });
}

- (void)removeFramebufferFromActiveImageCaptureList:(GLFramebuffer *)framebuffer {
    runAsynchronouslyOnVideoProcessingQueue(^{
        [activeImageCaptureList removeObject:framebuffer];
    });
}

@end
