//
//  WaterMarkProcessor.h
//  WaterMarkDemo
//
//  Created by adams on 2021/7/7.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WaterMarkProcessor : NSObject

@property(nonatomic, assign) CVPixelBufferRef pixelBuffer;

- (CVPixelBufferRef)outputPixelBuffer;

@end

NS_ASSUME_NONNULL_END
