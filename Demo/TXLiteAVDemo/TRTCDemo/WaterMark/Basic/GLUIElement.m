//
//  GLUIElement.m
//  WaterMarkDemo
//
//  Created by adams on 2021/7/7.
//

#import "GLUIElement.h"

@interface GLUIElement () {
    UIView * view;
    CALayer *layer;

    CGSize         previousLayerSizeInPixels;
    CMTime         time;
    NSTimeInterval actualTimeOfLastUpdate;
}
@end

@implementation GLUIElement

- (id)initWithView:(UIView *)inputView {
    if (self == [super init]) {
        view                      = inputView;
        layer                     = inputView.layer;
        previousLayerSizeInPixels = CGSizeZero;
        [self update];
    }
    return self;
}

- (CGSize)layerSizeInPixels {
    CGSize pointSize = layer.bounds.size;
    return CGSizeMake(layer.contentsScale * pointSize.width, layer.contentsScale * pointSize.height);
}

- (void)update {
    [self updateWithTimestamp:kCMTimeIndefinite];
}

- (void)updateUsingCurrentTime {
    if (CMTIME_IS_INVALID(time)) {
        time                   = CMTimeMakeWithSeconds(0, 600);
        actualTimeOfLastUpdate = [NSDate timeIntervalSinceReferenceDate];
    } else {
        NSTimeInterval now     = [NSDate timeIntervalSinceReferenceDate];
        NSTimeInterval diff    = now - actualTimeOfLastUpdate;
        time                   = CMTimeAdd(time, CMTimeMakeWithSeconds(diff, 600));
        actualTimeOfLastUpdate = now;
    }

    [self updateWithTimestamp:time];
}

- (void)updateWithTimestamp:(CMTime)frameTime {
    [GLContext useImageProcessingContext];

    CGSize layerPixelSize = [self layerSizeInPixels];

    GLubyte *imageData = (GLubyte *)calloc(1, (int)layerPixelSize.width * (int)layerPixelSize.height * 4);

    CGColorSpaceRef genericRGBColorspace = CGColorSpaceCreateDeviceRGB();
    CGContextRef    imageContext         = CGBitmapContextCreate(imageData, (int)layerPixelSize.width, (int)layerPixelSize.height, 8, (int)layerPixelSize.width * 4, genericRGBColorspace,
                                                      kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGContextTranslateCTM(imageContext, 0.0f, layerPixelSize.height);
    CGContextScaleCTM(imageContext, layer.contentsScale, -layer.contentsScale);

    [layer renderInContext:imageContext];

    CGContextRelease(imageContext);
    CGColorSpaceRelease(genericRGBColorspace);

    outputFramebuffer = [[GLContext sharedFramebufferCache] fetchFramebufferForSize:layerPixelSize textureOptions:self.outputTextureOptions onlyTexture:YES];

    glBindTexture(GL_TEXTURE_2D, [outputFramebuffer texture]);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (int)layerPixelSize.width, (int)layerPixelSize.height, 0, GL_BGRA, GL_UNSIGNED_BYTE, imageData);

    free(imageData);

    for (id<GLInput> currentTarget in targets) {
        if (currentTarget != self.targetToIgnoreForUpdates) {
            NSInteger indexOfObject        = [targets indexOfObject:currentTarget];
            NSInteger textureIndexOfTarget = [[targetTextureIndices objectAtIndex:indexOfObject] integerValue];
            [currentTarget setInputSize:layerPixelSize atIndex:textureIndexOfTarget];
            [currentTarget newFrameReadyAtTime:frameTime atIndex:textureIndexOfTarget];
        }
    }
}

@end
