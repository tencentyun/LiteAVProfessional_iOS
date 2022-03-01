/*
 * Module:   TRTCRemoteUserConfig
 *
 * Function: 保存对远端用户的设置项
 *
 *    1. 对象无需保存到本地
 *
 */

#import "TRTCRemoteUserConfig.h"

#import "TRTCCloud.h"

@implementation TRTCRemoteUserConfig

- (instancetype)init {
    self = [super init];
    if (self) {
        self.isAudioEnabled          = YES;
        self.isVideoEnabled          = YES;
        self.isSubStream             = NO;
        self.renderParams            = [[TRTCRenderParams alloc] init];
        self.renderParams.fillMode   = TRTCVideoFillMode_Fill;
        self.renderParams.mirrorType = TRTCVideoMirrorTypeDisable;
        self.volume                  = 100;
    }
    return self;
}

- (void)setIsSubStream:(BOOL)isSubStream {
    _isSubStream = isSubStream;
    if (_isSubStream) {
        self.renderParams.fillMode = TRTCVideoFillMode_Fit;
    } else {
        self.renderParams.fillMode = TRTCVideoFillMode_Fill;
    }
}

@end
