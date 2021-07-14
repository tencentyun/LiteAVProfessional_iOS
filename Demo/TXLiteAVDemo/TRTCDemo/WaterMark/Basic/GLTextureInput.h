//
//  GLTextureInput.h
//  WaterMarkDemo
//
//  Created by adams on 2021/7/7.
//

#import "GLOutput.h"

NS_ASSUME_NONNULL_BEGIN

@interface GLTextureInput : GLOutput

@property (nonatomic, assign) CGSize textureSize;
@property (nonatomic, assign) GLuint newInputTexture;

- (id)initWithTexture:(GLuint)newInputTexture size:(CGSize)newTextureSize;

- (void)processTexture;

@end

NS_ASSUME_NONNULL_END
