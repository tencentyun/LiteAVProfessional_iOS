//
//  GLAlphaBlendFilter.h
//  WaterMarkDemo
//
//  Created by adams on 2021/7/6.
//

#import <Foundation/Foundation.h>
#import "GLFilter.h"

NS_ASSUME_NONNULL_BEGIN

@interface GLAlphaBlendFilter : GLFilter
{
    GLint mixUniform;
    GLFramebuffer *secondInputFramebuffer;

    GLint filterSecondTextureCoordinateAttribute;
    GLint filterInputTextureUniform2;
    GLRotationMode inputRotation2;
    CMTime firstFrameTime, secondFrameTime;
    
    BOOL hasSetFirstTexture, hasReceivedFirstFrame, hasReceivedSecondFrame, firstFrameWasVideo, secondFrameWasVideo;
    BOOL firstFrameCheckDisabled, secondFrameCheckDisabled;
   
}

@property(readwrite, nonatomic) CGFloat mix;

- (void)disableFirstFrameCheck;
- (void)disableSecondFrameCheck;

@end

NS_ASSUME_NONNULL_END
