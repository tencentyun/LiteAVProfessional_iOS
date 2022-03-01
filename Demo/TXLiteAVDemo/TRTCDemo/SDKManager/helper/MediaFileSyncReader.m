//
//  TRTCCustomVideoTest.m
//  TXLiteAVDemo
//
//  Created by rushanting on 2019/3/26.
//  Copyright © 2019 Tencent. All rights reserved.
//

#import "MediaFileSyncReader.h"

#include <objc/runtime.h>

#import "MediaFileReader.h"

@interface                                    MediaFileSyncReader ()
@property(nonatomic, strong) MediaFileReader *mediaReader;
@property(nonatomic, assign) UInt64           startTime;
@property(nonatomic, assign) BOOL             videoFinished;
@property(nonatomic, assign) BOOL             audioFinished;
@end

@implementation MediaFileSyncReader

- (instancetype)initWithAVAsset:(AVAsset *)asset {
    self = [super init];
    if (self) {
        _mediaReader     = [[MediaFileReader alloc] initWithMediaAsset:asset videoReadFormat:VideoReadFormat_NV12];
        _audioSampleRate = self.mediaReader.audioSampleRate;
        _audioChannels   = self.mediaReader.audioChannels;
        _angle           = self.mediaReader.angle;
    }
    return self;
}

- (NSData *)createPCMData:(CMSampleBufferRef)sampleBuffer {
    const CMAudioFormatDescriptionRef  formatDesc = (CMAudioFormatDescriptionRef)CMSampleBufferGetFormatDescription(sampleBuffer);
    const AudioStreamBasicDescription *asbd       = NULL;
    if (formatDesc) {
        asbd = CMAudioFormatDescriptionGetStreamBasicDescription(formatDesc);
    }
    AudioBufferList  audioBufferList;
    CMBlockBufferRef blockBuffer;
    OSStatus         state = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, NULL, &audioBufferList, sizeof(audioBufferList), NULL, NULL, 0, &blockBuffer);

    if (state == noErr) {
        NSMutableData *audioPCMData = [[NSMutableData alloc] init];
        for (int i = 0; i < audioBufferList.mNumberBuffers; i++) {
            AudioBuffer audioBuffer = audioBufferList.mBuffers[i];

            [audioPCMData appendBytes:audioBuffer.mData length:audioBuffer.mDataByteSize];
        }
        if (blockBuffer != nil) {
            CFRelease(blockBuffer);
        }
        return audioPCMData;
    } else {
        return nil;
    }
}

- (void)start {
    _startTime     = CACurrentMediaTime() * 1000000;
    _videoFinished = false;
    _audioFinished = false;
    [self startVideo];
    [self startAudio];
}

- (void)stop {
    [self.mediaReader stopVideoRead];
    [self.mediaReader stopAudioRead];
}

- (void)resetMedia {
    if (!_videoFinished) {
        return;
    }
    if (!_audioFinished) {
        return;
    }
    NSLog(@"resetMedia");
    _videoFinished = false;
    _audioFinished = false;
    _startTime     = CACurrentMediaTime() * 1000000;
    [self startVideo];
    [self startAudio];
}

- (void)startVideo {
    __weak __typeof(self) weakSelf = self;
    [weakSelf.mediaReader startVideoRead];
    [weakSelf.mediaReader readVideoFrameFromTime:0
        toTime:(float)weakSelf.mediaReader.duration.value / weakSelf.mediaReader.duration.timescale
        fps:weakSelf.mediaReader.fps
        readOneFrame:^(CMSampleBufferRef sampleBuffer) {
            @autoreleasepool {
                __strong __typeof(weakSelf) strongSelf = weakSelf;

                CMTime time      = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
                UInt64 timeStamp = time.value / (double)time.timescale * 1000000;

                UInt64 currnetTime = CACurrentMediaTime() * 1000000;
                UInt64 pts         = time.value / (double)time.timescale * 1000000;
                UInt64 cost        = currnetTime - strongSelf.startTime;

                if (pts > cost) {
                    usleep((UInt32)(pts - cost));
                }

                if ([strongSelf.delegate respondsToSelector:@selector(onReadVideoFrameAtFrameIntervals:timeStamp:)]) {
                    [strongSelf.delegate onReadVideoFrameAtFrameIntervals:CMSampleBufferGetImageBuffer(sampleBuffer) timeStamp:timeStamp];
                }
            }
        }
        readFinished:^{
            __typeof(self) strongSelf = weakSelf;
            strongSelf.videoFinished  = true;
            [strongSelf resetMedia];
        }];
}

- (void)startAudio {
    __weak __typeof(self) weakSelf = self;
    [weakSelf.mediaReader startAudioRead];
    [weakSelf.mediaReader readAudioFrameFromTime:0
        toTime:(float)weakSelf.mediaReader.duration.value / weakSelf.mediaReader.duration.timescale
        readOneFrame:^(CMSampleBufferRef sampleBuffer) {
            @autoreleasepool {
                __typeof(self) strongSelf = weakSelf;

                CMTime time      = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
                UInt64 timeStamp = time.value / (double)time.timescale * 1000000;

                UInt64 currnetTime = CACurrentMediaTime() * 1000000;
                UInt64 pts         = time.value / (double)time.timescale * 1000000;
                UInt64 cost        = currnetTime - strongSelf.startTime;

                if (pts > cost) {
                    usleep((UInt32)(pts - cost));
                }

                if ([self.delegate respondsToSelector:@selector(onReadAudioFrameAtFrameIntervals:timeStamp:)]) {
                    [strongSelf.delegate onReadAudioFrameAtFrameIntervals:[self createPCMData:sampleBuffer] timeStamp:timeStamp];
                }
            }
        }
        readFinished:^{
            __typeof(self) strongSelf = weakSelf;
            strongSelf.audioFinished  = true;
            [strongSelf resetMedia];
        }];
}

@end
