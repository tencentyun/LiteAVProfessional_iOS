//
//  GLTextureOutput.h
//  WaterMarkDemo
//
//  Created by adams on 2021/7/7.
//

#import <Foundation/Foundation.h>
#import "GLContext.h"

NS_ASSUME_NONNULL_BEGIN
@class GLTextureOutput;

@protocol GLTextureOutputDelegate
- (void)newFrameReadyFromTextureOutput:(GLTextureOutput *)callbackTextureOutput;
@end

@interface GLTextureOutput : NSObject <GLInput>
{
    GLFramebuffer *firstInputFramebuffer;
}

@property(readwrite, unsafe_unretained, nonatomic) id<GLTextureOutputDelegate> delegate;
@property(readonly, assign) GLuint texture;
@property(nonatomic, assign) BOOL enabled;

- (void)doneWithTexture;

@end

NS_ASSUME_NONNULL_END
