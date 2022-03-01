//
//  GLProgram.m
//  WaterMarkDemo
//
//  Created by adams on 2021/7/6.
//

#import "GLProgram.h"

typedef void (*GLInfoFunction)(GLuint program, GLenum pname, GLint *params);
typedef void (*GLLogFunction)(GLuint program, GLsizei bufsize, GLsizei *length, GLchar *infolog);

@interface GLProgram ()

@end

@implementation GLProgram

@synthesize initialized = _initialized;

- (id)initWithVertexShaderString:(NSString *)vShaderString fragmentShaderString:(NSString *)fShaderString {
    if (self == [super init]) {
        _initialized = NO;
        attributes   = [[NSMutableArray alloc] init];
        uniforms     = [[NSMutableArray alloc] init];
        program      = glCreateProgram();

        if (![self compileShader:&vertShader type:GL_VERTEX_SHADER string:vShaderString]) {
            NSLog(@"Failed to compile vertex shader");
        }

        if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER string:fShaderString]) {
            NSLog(@"Failed to compile fragment shader");
        }

        glAttachShader(program, vertShader);
        glAttachShader(program, fragShader);
    }
    return self;
}

- (id)initWithVertexShaderString:(NSString *)vShaderString fragmentShaderFilename:(NSString *)fShaderFilename {
    NSString *fragShaderPathname   = [[NSBundle mainBundle] pathForResource:fShaderFilename ofType:@"fsh"];
    NSString *fragmentShaderString = [NSString stringWithContentsOfFile:fragShaderPathname encoding:NSUTF8StringEncoding error:nil];
    if (self == [self initWithVertexShaderString:vShaderString fragmentShaderString:fragmentShaderString]) {
    }
    return self;
}

- (id)initWithVertexShaderFilename:(NSString *)vShaderFilename fragmentShaderFilename:(NSString *)fShaderFilename {
    NSString *vertShaderPathname = [[NSBundle mainBundle] pathForResource:vShaderFilename ofType:@"vsh"];
    NSString *vertexShaderString = [NSString stringWithContentsOfFile:vertShaderPathname encoding:NSUTF8StringEncoding error:nil];

    NSString *fragShaderPathname   = [[NSBundle mainBundle] pathForResource:fShaderFilename ofType:@"fsh"];
    NSString *fragmentShaderString = [NSString stringWithContentsOfFile:fragShaderPathname encoding:NSUTF8StringEncoding error:nil];

    if (self == [self initWithVertexShaderString:vertexShaderString fragmentShaderString:fragmentShaderString]) {
    }
    return self;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type string:(NSString *)shaderString {
    GLint         status;
    const GLchar *source;
    source = (GLchar *)[shaderString UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }

    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);

    if (status != GL_TRUE) {
        GLint logLength;
        glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
        if (logLength > 0) {
            GLchar *log = (GLchar *)malloc(logLength);
            glGetShaderInfoLog(*shader, logLength, &logLength, log);
            if (shader == &vertShader) {
                self.vertexShaderLog = [NSString stringWithFormat:@"%s", log];
            } else {
                self.fragmentShaderLog = [NSString stringWithFormat:@"%s", log];
            }
            free(log);
        }
    }
    return status == GL_TRUE;
}

- (void)addAttribute:(NSString *)attributeName {
    if (![attributes containsObject:attributeName]) {
        [attributes addObject:attributeName];
        glBindAttribLocation(program, (GLuint)[attributes indexOfObject:attributeName], [attributeName UTF8String]);
    }
}

- (GLuint)attributeIndex:(NSString *)attributeName {
    return (GLuint)[attributes indexOfObject:attributeName];
}

- (GLuint)uniformIndex:(NSString *)uniformName {
    return glGetUniformLocation(program, [uniformName UTF8String]);
}

- (BOOL)link {
    GLint status;
    glLinkProgram(program);
    glGetProgramiv(program, GL_LINK_STATUS, &status);
    if (status == GL_FALSE) {
        return NO;
    }

    if (vertShader) {
        glDeleteShader(vertShader);
        vertShader = 0;
    }

    if (fragShader) {
        glDeleteShader(fragShader);
        fragShader = 0;
    }

    self.initialized = YES;
    return YES;
}

- (void)use {
    glUseProgram(program);
}

- (void)validate {
    GLint logLength;
    glValidateProgram(program);
    glGetProgramiv(program, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(program, logLength, &logLength, log);
        self.programLog = [NSString stringWithFormat:@"%s", log];
        free(log);
    }
}

- (void)dealloc {
    if (vertShader) {
        glDeleteShader(vertShader);
    }

    if (fragShader) {
        glDeleteShader(fragShader);
    }

    if (program) {
        glDeleteProgram(program);
    }
}

@end
