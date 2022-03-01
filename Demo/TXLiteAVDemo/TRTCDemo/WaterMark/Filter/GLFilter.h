//
//  GLFilter.h
//  WaterMarkDemo
//
//  Created by adams on 2021/7/6.
//

#import <Foundation/Foundation.h>

#import "GLOutput.h"

#define STRINGIZE(x)        #x
#define STRINGIZE2(x)       STRINGIZE(x)
#define SHADER_STRING(text) @STRINGIZE2(text)

#define GLHashIdentifier           #
#define GLWrappedLabel(x)          x
#define GLEscapedHashIdentifier(a) GLWrappedLabel(GLHashIdentifier) a

extern NSString *const kGLVertexShaderString;
extern NSString *const kGLPassthroughFragmentShaderString;

struct GPUVector4 {
    GLfloat one;
    GLfloat two;
    GLfloat three;
    GLfloat four;
};
typedef struct GPUVector4 GPUVector4;

struct GPUVector3 {
    GLfloat one;
    GLfloat two;
    GLfloat three;
};
typedef struct GPUVector3 GPUVector3;

struct GPUMatrix4x4 {
    GPUVector4 one;
    GPUVector4 two;
    GPUVector4 three;
    GPUVector4 four;
};
typedef struct GPUMatrix4x4 GPUMatrix4x4;

struct GPUMatrix3x3 {
    GPUVector3 one;
    GPUVector3 two;
    GPUVector3 three;
};
typedef struct GPUMatrix3x3 GPUMatrix3x3;

NS_ASSUME_NONNULL_BEGIN

@interface GLFilter : GLOutput <GLInput> {
    GLFramebuffer *firstInputFramebuffer;

    GLProgram *filterProgram;
    GLint      filterPositionAttribute, filterTextureCoordinateAttribute;
    GLint      filterInputTextureUniform;
    GLfloat    backgroundColorRed, backgroundColorGreen, backgroundColorBlue, backgroundColorAlpha;

    BOOL isEndProcessing;

    CGSize         currentFilterSize;
    GLRotationMode inputRotation;

    BOOL currentlyReceivingMonochromeInput;

    NSMutableDictionary *uniformStateRestorationBlocks;
    dispatch_semaphore_t imageCaptureSemaphore;
}

@property(readonly) CVPixelBufferRef renderTarget;
@property(readwrite, nonatomic) BOOL preventRendering;
@property(readwrite, nonatomic) BOOL currentlyReceivingMonochromeInput;

- (id)initWithVertexShaderFromString:(NSString *)vertexShaderString fragmentShaderFromString:(NSString *)fragmentShaderString;
- (void)initializeAttributes;
- (CGSize)sizeOfFBO;
+ (const GLfloat *)textureCoordinatesForRotation:(GLRotationMode)rotationMode;
- (void)setFloat:(GLfloat)floatValue forUniform:(GLint)uniform program:(GLProgram *)shaderProgram;
- (void)setUniformsForProgramAtIndex:(NSUInteger)programIndex;
@end

NS_ASSUME_NONNULL_END
