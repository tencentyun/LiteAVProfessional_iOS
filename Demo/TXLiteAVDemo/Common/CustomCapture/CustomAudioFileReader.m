#import <Foundation/Foundation.h>
#import <sys/time.h>
#import "CustomAudioFileReader.h"

#define WEAKIFY(x) __weak __typeof(x) w_##x = x;
#define STRONGIFY_OR_RET(x) __strong __typeof(w_##x) x = w_##x; if (nil == x) return;

@interface CustomAudioFileReader()

@property (atomic) BOOL isStart;

@end

@implementation CustomAudioFileReader
{
    int _sampleLen;
    int _fileDataReadLen;
    NSData *_fileData;
}

static CustomAudioFileReader *_instance;

+ (instancetype)sharedInstance {
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        _instance = [[CustomAudioFileReader alloc] initPrivate];
    });
    return _instance;
}

- (instancetype)initPrivate {
    self = [super init];
    if (nil != self) {
        _isStart = NO;
    }
    return self;
}

- (void)start:(int)sampleRate nChannels:(int)channels nSampleLen:(int)sampleLen {
    _sampleLen = sampleLen;
    
    NSString *resourcePath = [[NSBundle mainBundle] pathForResource:@"CustomAudio48000_1" ofType:@"pcm"];
    _fileData = [NSData dataWithContentsOfFile:resourcePath];
    
    dispatch_queue_t _unitQueue = dispatch_queue_create("audio_read_queue", DISPATCH_QUEUE_SERIAL);
    
    self.isStart = YES;
    WEAKIFY(self);
    dispatch_async(_unitQueue, ^{
        STRONGIFY_OR_RET(self);
        while (self.isStart) {
            struct timeval tv;
            gettimeofday(&tv,NULL);
            uint64_t currentTime = tv.tv_sec * 1000 + tv.tv_usec / 1000;
            if (self.delegate) {
                [self.delegate onAudioCapturePcm:[NSData dataWithBytes:self->_fileData.bytes+self->_fileDataReadLen length:self->_sampleLen] sampleRate:48000 channels:1 ts:(uint32_t)currentTime];
            }
            self->_fileDataReadLen += self->_sampleLen;
            if (self->_fileDataReadLen+self->_sampleLen > self->_fileData.length) {
                self->_fileDataReadLen = 0;
            }
            usleep(1000*20);
        }
        self->_fileData = nil;
    });
}

- (void)stop {
    self.isStart = NO;
}

@end
