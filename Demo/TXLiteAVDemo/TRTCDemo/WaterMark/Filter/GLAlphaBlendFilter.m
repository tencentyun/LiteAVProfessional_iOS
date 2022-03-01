//
//  GLAlphaBlendFilter.m
//  WaterMarkDemo
//
//  Created by adams on 2021/7/6.
//

#import "GLAlphaBlendFilter.h"

NSString *const kGLAlphaBlendFragmentShaderString = SHADER_STRING(varying highp vec2 textureCoordinate; varying highp vec2 textureCoordinate2;

                                                                  uniform sampler2D inputImageTexture; uniform sampler2D inputImageTexture2;

                                                                  uniform lowp float mixturePercent;

                                                                  void main() {
                                                                      lowp vec4 textureColor  = texture2D(inputImageTexture, textureCoordinate);
                                                                      lowp vec4 textureColor2 = texture2D(inputImageTexture2, textureCoordinate2);

                                                                      gl_FragColor = vec4(mix(textureColor.rgb, textureColor2.rgb, textureColor2.a * mixturePercent), textureColor.a);
                                                                  });

NSString *const kGLTwoInputTextureVertexShaderString = SHADER_STRING(attribute vec4 position; attribute vec4 inputTextureCoordinate; attribute vec4 inputTextureCoordinate2;

                                                                     varying vec2 textureCoordinate; varying vec2 textureCoordinate2;

                                                                     void main() {
                                                                         gl_Position        = position;
                                                                         textureCoordinate  = inputTextureCoordinate.xy;
                                                                         textureCoordinate2 = inputTextureCoordinate2.xy;
                                                                     });

@implementation GLAlphaBlendFilter
@synthesize     mix = _mix;

- (id)init {
    if (self == [super initWithVertexShaderFromString:kGLTwoInputTextureVertexShaderString fragmentShaderFromString:kGLAlphaBlendFragmentShaderString]) {
        mixUniform     = [filterProgram uniformIndex:@"mixturePercent"];
        inputRotation2 = kGLNoRotation;

        hasSetFirstTexture = NO;

        hasReceivedFirstFrame    = NO;
        hasReceivedSecondFrame   = NO;
        firstFrameWasVideo       = NO;
        secondFrameWasVideo      = NO;
        firstFrameCheckDisabled  = NO;
        secondFrameCheckDisabled = NO;

        firstFrameTime  = kCMTimeInvalid;
        secondFrameTime = kCMTimeInvalid;

        runSynchronouslyOnVideoProcessingQueue(^{
            [GLContext useImageProcessingContext];
            filterSecondTextureCoordinateAttribute = [filterProgram attributeIndex:@"inputTextureCoordinate2"];

            filterInputTextureUniform2 = [filterProgram uniformIndex:@"inputImageTexture2"];  // This does assume a name of "inputImageTexture2" for second input texture in the fragment shader
            glEnableVertexAttribArray(filterSecondTextureCoordinateAttribute);
        });
        self.mix = 0.5;
    }
    return self;
}

- (void)setMix:(CGFloat)newValue {
    _mix = newValue;
    [self setFloat:_mix forUniform:mixUniform program:filterProgram];
}

- (void)initializeAttributes {
    [super initializeAttributes];
    [filterProgram addAttribute:@"inputTextureCoordinate2"];
}

- (void)disableFirstFrameCheck {
    firstFrameCheckDisabled = YES;
}

- (void)disableSecondFrameCheck {
    secondFrameCheckDisabled = YES;
}

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates {
    if (self.preventRendering) {
        [firstInputFramebuffer unlock];
        [secondInputFramebuffer unlock];
        return;
    }

    [GLContext setActiveShaderProgram:filterProgram];
    outputFramebuffer = [[GLContext sharedFramebufferCache] fetchFramebufferForSize:[self sizeOfFBO] textureOptions:self.outputTextureOptions onlyTexture:NO];
    [outputFramebuffer activateFramebuffer];
    if (usingNextFrameForImageCapture) {
        [outputFramebuffer lock];
    }

    [self setUniformsForProgramAtIndex:0];

    glClearColor(backgroundColorRed, backgroundColorGreen, backgroundColorBlue, backgroundColorAlpha);
    glClear(GL_COLOR_BUFFER_BIT);

    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, [firstInputFramebuffer texture]);
    glUniform1i(filterInputTextureUniform, 2);

    glActiveTexture(GL_TEXTURE3);
    glBindTexture(GL_TEXTURE_2D, [secondInputFramebuffer texture]);
    glUniform1i(filterInputTextureUniform2, 3);

    glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
    glVertexAttribPointer(filterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    glVertexAttribPointer(filterSecondTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, [[self class] textureCoordinatesForRotation:inputRotation2]);

    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

    [firstInputFramebuffer unlock];
    [secondInputFramebuffer unlock];
    if (usingNextFrameForImageCapture) {
        dispatch_semaphore_signal(imageCaptureSemaphore);
    }
}

- (NSInteger)nextAvailableTextureIndex {
    if (hasSetFirstTexture) {
        return 1;
    } else {
        return 0;
    }
}

- (void)setInputFramebuffer:(GLFramebuffer *)newInputFramebuffer atIndex:(NSInteger)textureIndex {
    if (textureIndex == 0) {
        firstInputFramebuffer = newInputFramebuffer;
        hasSetFirstTexture    = YES;
        [firstInputFramebuffer lock];
    } else {
        secondInputFramebuffer = newInputFramebuffer;
        [secondInputFramebuffer lock];
    }
}

- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex {
    if (textureIndex == 0) {
        [super setInputSize:newSize atIndex:textureIndex];
        if (CGSizeEqualToSize(newSize, CGSizeZero)) {
            hasSetFirstTexture = NO;
        }
    }
}

- (void)setInputRotation:(GLRotationMode)newInputRotation atIndex:(NSInteger)textureIndex {
    if (textureIndex == 0) {
        inputRotation = newInputRotation;
    } else {
        inputRotation2 = newInputRotation;
    }
}

- (CGSize)rotatedSize:(CGSize)sizeToRotate forIndex:(NSInteger)textureIndex {
    CGSize rotatedSize = sizeToRotate;

    GLRotationMode rotationToCheck;
    if (textureIndex == 0) {
        rotationToCheck = inputRotation;
    } else {
        rotationToCheck = inputRotation2;
    }

    if (GLRotationSwapsWidthAndHeight(rotationToCheck)) {
        rotatedSize.width  = sizeToRotate.height;
        rotatedSize.height = sizeToRotate.width;
    }
    return rotatedSize;
}

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex {
    if (hasReceivedFirstFrame && hasReceivedSecondFrame) {
        return;
    }

    BOOL updatedMovieFrameOppositeStillImage = NO;

    if (textureIndex == 0) {
        hasReceivedFirstFrame = YES;
        firstFrameTime        = frameTime;
        if (secondFrameCheckDisabled) {
            hasReceivedSecondFrame = YES;
        }

        if (!CMTIME_IS_INDEFINITE(frameTime)) {
            if CMTIME_IS_INDEFINITE (secondFrameTime) {
                updatedMovieFrameOppositeStillImage = YES;
            }
        }
    } else {
        hasReceivedSecondFrame = YES;
        secondFrameTime        = frameTime;
        if (firstFrameCheckDisabled) {
            hasReceivedFirstFrame = YES;
        }

        if (!CMTIME_IS_INDEFINITE(frameTime)) {
            if CMTIME_IS_INDEFINITE (firstFrameTime) {
                updatedMovieFrameOppositeStillImage = YES;
            }
        }
    }

    if ((hasReceivedFirstFrame && hasReceivedSecondFrame) || updatedMovieFrameOppositeStillImage) {
        CMTime passOnFrameTime = (!CMTIME_IS_INDEFINITE(firstFrameTime)) ? firstFrameTime : secondFrameTime;
        [super newFrameReadyAtTime:passOnFrameTime atIndex:0];
        hasReceivedFirstFrame  = NO;
        hasReceivedSecondFrame = NO;
    }
}

@end
