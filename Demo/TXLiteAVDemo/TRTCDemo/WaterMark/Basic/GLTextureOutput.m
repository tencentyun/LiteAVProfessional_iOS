//
//  GLTextureOutput.m
//  WaterMarkDemo
//
//  Created by adams on 2021/7/7.
//

#import "GLTextureOutput.h"

@implementation GLTextureOutput
@synthesize     delegate = _delegate;
@synthesize     texture  = _texture;
@synthesize     enabled;

- (id)init {
    if (self == [super init]) {
        self.enabled = YES;
    }
    return self;
}

- (void)doneWithTexture {
    [firstInputFramebuffer unlock];
}

#pragma mark - GLInput Protocol
- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex {
    [_delegate newFrameReadyFromTextureOutput:self];
}

- (NSInteger)nextAvailableTextureIndex {
    return 0;
}

- (void)setInputFramebuffer:(GLFramebuffer *)newInputFramebuffer atIndex:(NSInteger)textureIndex {
    firstInputFramebuffer = newInputFramebuffer;
    [firstInputFramebuffer lock];
    _texture = [firstInputFramebuffer texture];
}

- (void)setInputRotation:(GLRotationMode)newInputRotation atIndex:(NSInteger)textureIndex {
}

- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex {
}

- (CGSize)maximumOutputSize {
    return CGSizeZero;
}

- (void)endProcessing {
}

- (BOOL)shouldIgnoreUpdatesToThisTarget {
    return NO;
}

- (BOOL)wantsMonochromeInput {
    return NO;
}

- (void)setCurrentlyReceivingMonochromeInput:(BOOL)newValue {
}

@end
