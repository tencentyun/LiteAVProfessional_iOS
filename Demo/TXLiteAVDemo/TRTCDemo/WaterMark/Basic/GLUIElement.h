//
//  GLUIElement.h
//  WaterMarkDemo
//
//  Created by adams on 2021/7/7.
//

#import "GLOutput.h"

NS_ASSUME_NONNULL_BEGIN

@interface GLUIElement : GLOutput
- (id)initWithView:(UIView *)inputView;
- (void)update;
@end

NS_ASSUME_NONNULL_END
