//
//  GLTextureInput.m
//  WaterMarkDemo
//
//  Created by adams on 2021/7/7.
//

#import "GLTextureInput.h"

@implementation GLTextureInput

- (id)initWithTexture:(GLuint)newInputTexture size:(CGSize)newTextureSize {
    if (self == [super init]) {
        runSynchronouslyOnVideoProcessingQueue(^{
            [GLContext useImageProcessingContext];
        });
        
        _textureSize = newTextureSize;
        _newInputTexture = newInputTexture;
        
        runSynchronouslyOnVideoProcessingQueue(^{
            self->outputFramebuffer = [[GLFramebuffer alloc] initWithSize:newTextureSize overriddenTexture:self->_newInputTexture];
        });
    }
    return self;
}

- (void)processTexture {
    runAsynchronouslyOnVideoProcessingQueue(^{
        for (id<GLInput> currentTarget in targets) {
            NSInteger indexOfObject = [targets indexOfObject:currentTarget];
            NSInteger targetTextureIndex = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
            
            [currentTarget setInputSize:_textureSize atIndex:targetTextureIndex];
            [currentTarget setInputFramebuffer:outputFramebuffer atIndex:targetTextureIndex];
            [currentTarget newFrameReadyAtTime:kCMTimeZero atIndex:targetTextureIndex];
        }
    });
}

@end
