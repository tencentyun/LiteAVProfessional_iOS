//
//  ShaderProcessor.m
//  WaterMarkDemo
//
//  Created by adams on 2021/7/7.
//

#import "ShaderProcessor.h"

#import <OpenGLES/ES2/gl.h>

@implementation ShaderProcessor

// 将一个顶点着色器和一个片段着色器挂载到一个着色器程序上，并返回程序的 id
+ (GLuint)programWithShaderName:(NSString *)shaderName {
    // 编译两个着色器
    GLuint vertexShader   = [self compileShaderWithName:shaderName type:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShaderWithName:shaderName type:GL_FRAGMENT_SHADER];

    // 挂载 shader 到 program 上
    GLuint program = glCreateProgram();
    glAttachShader(program, vertexShader);
    glAttachShader(program, fragmentShader);

    // 链接 program
    glLinkProgram(program);

    // 检查链接是否成功
    GLint linkSuccess;
    glGetProgramiv(program, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(program, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSAssert(NO, @"program链接失败：%@", messageString);
        exit(1);
    }

    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);

    return program;
}

// 编译一个 shader，并返回 shader 的 id
+ (GLuint)compileShaderWithName:(NSString *)name type:(GLenum)shaderType {
    // 查找 shader 文件
    NSString *shaderPath = [[NSBundle mainBundle] pathForResource:name ofType:shaderType == GL_VERTEX_SHADER ? @"vsh" : @"fsh"];  // 根据不同的类型确定后缀名
    NSError * error;
    NSString *shaderString = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString) {
        NSAssert(NO, @"读取shader失败");
        exit(1);
    }

    // 创建一个 shader 对象
    GLuint shader = glCreateShader(shaderType);

    // 获取 shader 的内容
    const char *shaderStringUTF8 = [shaderString UTF8String];
    int         len              = (int)strlen(shaderStringUTF8);
    glShaderSource(shader, 1, &shaderStringUTF8, &len);

    // 编译shader
    glCompileShader(shader);

    // 查询 shader 是否编译成功
    GLint compileSuccess;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shader, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSAssert(NO, @"shader编译失败：%@", messageString);
        exit(1);
    }

    return shader;
}

@end
