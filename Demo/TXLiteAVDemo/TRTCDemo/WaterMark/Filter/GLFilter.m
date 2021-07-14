//
//  GLFilter.m
//  WaterMarkDemo
//
//  Created by adams on 2021/7/6.
//

#import "GLFilter.h"
#import <AVFoundation/AVFoundation.h>
NSString *const kGLVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 
 varying vec2 textureCoordinate;
 
 void main()
 {
    gl_Position = position;
    textureCoordinate = inputTextureCoordinate.xy;
 }
);

NSString *const kGLPassthroughFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 uniform sampler2D inputImageTexture;
 
 void main()
 {
    gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
 }
);

@implementation GLFilter

@synthesize preventRendering = _preventRendering;
@synthesize currentlyReceivingMonochromeInput;

- (id)initWithVertexShaderFromString:(NSString *)vertexShaderString fragmentShaderFromString:(NSString *)fragmentShaderString {
    if (self == [super init]) {
        uniformStateRestorationBlocks = [NSMutableDictionary dictionaryWithCapacity:10];
        _preventRendering = NO;
        currentlyReceivingMonochromeInput = NO;
        backgroundColorRed = 0.0;
        backgroundColorGreen = 0.0;
        backgroundColorBlue = 0.0;
        backgroundColorAlpha = 0.0;
        imageCaptureSemaphore = dispatch_semaphore_create(0);
        dispatch_semaphore_signal(imageCaptureSemaphore);
        
        runSynchronouslyOnVideoProcessingQueue(^{
            [GLContext useImageProcessingContext];
            
            filterProgram = [[GLContext sharedImageProcessingContext] programForVertexShaderString:vertexShaderString fragmentShaderString:fragmentShaderString];
            
            if (!filterProgram.initialized)
            {
                [self initializeAttributes];
                
                if (![filterProgram link])
                {
                    NSString *progLog = [filterProgram programLog];
                    NSLog(@"Program link log: %@", progLog);
                    NSString *fragLog = [filterProgram fragmentShaderLog];
                    NSLog(@"Fragment shader compile log: %@", fragLog);
                    NSString *vertLog = [filterProgram vertexShaderLog];
                    NSLog(@"Vertex shader compile log: %@", vertLog);
                    filterProgram = nil;
                    NSAssert(NO, @"Filter shader link failed");
                }
            }
            
            filterPositionAttribute = [filterProgram attributeIndex:@"position"];
            filterTextureCoordinateAttribute = [filterProgram attributeIndex:@"inputTextureCoordinate"];
            filterInputTextureUniform = [filterProgram uniformIndex:@"inputImageTexture"]; // This does assume a name of "inputImageTexture" for the fragment shader
            
            [GLContext setActiveShaderProgram:filterProgram];
            
            glEnableVertexAttribArray(filterPositionAttribute);
            glEnableVertexAttribArray(filterTextureCoordinateAttribute);
        });
    }
    return self;
}

- (void)initializeAttributes {
    [filterProgram addAttribute:@"position"];
    [filterProgram addAttribute:@"inputTextureCoordinate"];
}

- (void)setupFilterForSize:(CGSize)filterFrameSize {
    
}

- (void)useNextFrameForImageCapture {
    usingNextFrameForImageCapture = YES;
    if (dispatch_semaphore_wait(imageCaptureSemaphore, DISPATCH_TIME_NOW) != 0) {
        return;
    }
}

- (CGSize)sizeOfFBO {
    CGSize outputSize = [self maximumOutputSize];
    if ( (CGSizeEqualToSize(outputSize, CGSizeZero)) || (inputTextureSize.width < outputSize.width) ) {
        return inputTextureSize;
    } else {
        return outputSize;
    }
}

+ (const GLfloat *)textureCoordinatesForRotation:(GLRotationMode)rotationMode {
    static const GLfloat noRotationTextureCoordinates[] = {
        0.0f, 0.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
    };
    
    static const GLfloat rotateLeftTextureCoordinates[] = {
        1.0f, 0.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        0.0f, 1.0f,
    };
    
    static const GLfloat rotateRightTextureCoordinates[] = {
        0.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 1.0f,
        1.0f, 0.0f,
    };
    
    static const GLfloat verticalFlipTextureCoordinates[] = {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f,  0.0f,
        1.0f,  0.0f,
    };
    
    static const GLfloat horizontalFlipTextureCoordinates[] = {
        1.0f, 0.0f,
        0.0f, 0.0f,
        1.0f,  1.0f,
        0.0f,  1.0f,
    };
    
    static const GLfloat rotateRightVerticalFlipTextureCoordinates[] = {
        0.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 0.0f,
        1.0f, 1.0f,
    };

    static const GLfloat rotateRightHorizontalFlipTextureCoordinates[] = {
        1.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        0.0f, 0.0f,
    };

    static const GLfloat rotate180TextureCoordinates[] = {
        1.0f, 1.0f,
        0.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 0.0f,
    };

    switch(rotationMode) {
        case kGLNoRotation: return noRotationTextureCoordinates;
        case kGLRotateLeft: return rotateLeftTextureCoordinates;
        case kGLRotateRight: return rotateRightTextureCoordinates;
        case kGLFlipVertical: return verticalFlipTextureCoordinates;
        case kGLFlipHorizonal: return horizontalFlipTextureCoordinates;
        case kGLRotateRightFlipVertical: return rotateRightVerticalFlipTextureCoordinates;
        case kGLRotateRightFlipHorizontal: return rotateRightHorizontalFlipTextureCoordinates;
        case kGLRotate180: return rotate180TextureCoordinates;
    }
}

- (void)renderToTextureWithVertices:(const GLfloat *)vertices textureCoordinates:(const GLfloat *)textureCoordinates {
    if (self.preventRendering) {
        [firstInputFramebuffer unlock];
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

    glVertexAttribPointer(filterPositionAttribute, 2, GL_FLOAT, 0, 0, vertices);
    glVertexAttribPointer(filterTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    [firstInputFramebuffer unlock];
    
    if (usingNextFrameForImageCapture) {
        dispatch_semaphore_signal(imageCaptureSemaphore);
    }
}

- (void)informTargetsAboutNewFrameAtTime:(CMTime)frameTime {
    if (self.frameProcessingCompletionBlock != NULL) {
        self.frameProcessingCompletionBlock(self, frameTime);
    }
    
    for (id<GLInput> currentTarget in targets) {
        if (currentTarget != self.targetToIgnoreForUpdates) {
            NSInteger indexOfObject = [targets indexOfObject:currentTarget];
            NSInteger textureIndex = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];

            [self setInputFramebufferForTarget:currentTarget atIndex:textureIndex];
            [currentTarget setInputSize:[self outputFrameSize] atIndex:textureIndex];
        }
    }
    
    [[self framebufferForOutput] unlock];
    
    if (!usingNextFrameForImageCapture) {
        [self removeOutputFramebuffer];
    }
    
    for (id<GLInput> currentTarget in targets) {
        if (currentTarget != self.targetToIgnoreForUpdates) {
            NSInteger indexOfObject = [targets indexOfObject:currentTarget];
            NSInteger textureIndex = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
            [currentTarget newFrameReadyAtTime:frameTime atIndex:textureIndex];
        }
    }
}

- (CGSize)outputFrameSize {
    return inputTextureSize;
}

- (void)setUniformsForProgramAtIndex:(NSUInteger)programIndex {
    [uniformStateRestorationBlocks enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop){
        dispatch_block_t currentBlock = obj;
        currentBlock();
    }];
}

- (void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex {
    static const GLfloat imageVertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
    
    [self renderToTextureWithVertices:imageVertices textureCoordinates:[[self class] textureCoordinatesForRotation:inputRotation]];

    [self informTargetsAboutNewFrameAtTime:frameTime];
}

- (void)setFloat:(GLfloat)floatValue forUniform:(GLint)uniform program:(GLProgram *)shaderProgram {
    runAsynchronouslyOnVideoProcessingQueue(^{
        [GLContext setActiveShaderProgram:shaderProgram];
        [self setAndExecuteUniformStateCallbackAtIndex:uniform forProgram:shaderProgram toBlock:^{
            glUniform1f(uniform, floatValue);
        }];
    });
}

- (void)setAndExecuteUniformStateCallbackAtIndex:(GLint)uniform forProgram:(GLProgram *)shaderProgram toBlock:(dispatch_block_t)uniformStateBlock {
    [uniformStateRestorationBlocks setObject:[uniformStateBlock copy] forKey:[NSNumber numberWithInt:uniform]];
    uniformStateBlock();
}

- (NSInteger)nextAvailableTextureIndex {
    return 0;
}

- (CGSize)rotatedSize:(CGSize)sizeToRotate forIndex:(NSInteger)textureIndex {
    CGSize rotatedSize = sizeToRotate;
    if (GLRotationSwapsWidthAndHeight(inputRotation)) {
        rotatedSize.width = sizeToRotate.height;
        rotatedSize.height = sizeToRotate.width;
    }
    
    return rotatedSize;
}

- (CGPoint)rotatedPoint:(CGPoint)pointToRotate forRotation:(GLRotationMode)rotation {
    CGPoint rotatedPoint;
    switch(rotation) {
        case kGLNoRotation: return pointToRotate; break;
        case kGLFlipHorizonal:
        {
            rotatedPoint.x = 1.0 - pointToRotate.x;
            rotatedPoint.y = pointToRotate.y;
        }; break;
        case kGLFlipVertical:
        {
            rotatedPoint.x = pointToRotate.x;
            rotatedPoint.y = 1.0 - pointToRotate.y;
        }; break;
        case kGLRotateLeft:
        {
            rotatedPoint.x = 1.0 - pointToRotate.y;
            rotatedPoint.y = pointToRotate.x;
        }; break;
        case kGLRotateRight:
        {
            rotatedPoint.x = pointToRotate.y;
            rotatedPoint.y = 1.0 - pointToRotate.x;
        }; break;
        case kGLRotateRightFlipVertical:
        {
            rotatedPoint.x = pointToRotate.y;
            rotatedPoint.y = pointToRotate.x;
        }; break;
        case kGLRotateRightFlipHorizontal:
        {
            rotatedPoint.x = 1.0 - pointToRotate.y;
            rotatedPoint.y = 1.0 - pointToRotate.x;
        }; break;
        case kGLRotate180:
        {
            rotatedPoint.x = 1.0 - pointToRotate.x;
            rotatedPoint.y = 1.0 - pointToRotate.y;
        }; break;
    }
    
    return rotatedPoint;
}

- (void)setInputSize:(CGSize)newSize atIndex:(NSInteger)textureIndex {
    if (self.preventRendering) {
        return;
    }
    
    if (overrideInputSize) {
        if (CGSizeEqualToSize(forcedMaximumSize, CGSizeZero)) {
            
        } else {
            CGRect insetRect = AVMakeRectWithAspectRatioInsideRect(newSize, CGRectMake(0.0, 0.0, forcedMaximumSize.width, forcedMaximumSize.height));
            inputTextureSize = insetRect.size;
        }
    } else {
        CGSize rotatedSize = [self rotatedSize:newSize forIndex:textureIndex];
        if (CGSizeEqualToSize(rotatedSize, CGSizeZero)) {
            inputTextureSize = rotatedSize;
        } else if (!CGSizeEqualToSize(inputTextureSize, rotatedSize)) {
            inputTextureSize = rotatedSize;
        }
    }
    
    [self setupFilterForSize:[self sizeOfFBO]];
}

- (void)forceProcessingAtSize:(CGSize)frameSize {
    if (CGSizeEqualToSize(frameSize, CGSizeZero)) {
        overrideInputSize = NO;
    } else {
        overrideInputSize = YES;
        inputTextureSize = frameSize;
        forcedMaximumSize = CGSizeZero;
    }
}

- (void)forceProcessingAtSizeRespectingAspectRatio:(CGSize)frameSize {
    if (CGSizeEqualToSize(frameSize, CGSizeZero)) {
        overrideInputSize = NO;
        inputTextureSize = CGSizeZero;
        forcedMaximumSize = CGSizeZero;
    } else {
        overrideInputSize = YES;
        forcedMaximumSize = frameSize;
    }
}

- (CGSize)maximumOutputSize {
    return CGSizeZero;
}

- (void)endProcessing {
    if (!isEndProcessing) {
        isEndProcessing = YES;
        for (id<GLInput> currentTarget in targets) {
            [currentTarget endProcessing];
        }
    }
}

- (BOOL)wantsMonochromeInput {
    return NO;
}

@end
