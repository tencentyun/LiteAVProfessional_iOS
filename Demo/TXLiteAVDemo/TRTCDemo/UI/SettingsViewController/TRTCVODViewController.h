// 这个用来测试TRTC和点播同时使用的场景

#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "TXVodPlayer.h"

@interface TRTCVODViewController : UIViewController {
    TXVodPlayer *_txVodPlayer;
    UITextView *_statusView;
    UITextView *_logViewEvt;
    unsigned long long _startTime;
    unsigned long long _lastTime;

    UIButton *_btnPlay;
    UIButton *_btnClose;
    UIView *_cover;
    UIButton *_btnChangeRate;

    BOOL _screenPortrait;
    BOOL _renderFillScreen;
    BOOL _log_switch;
    BOOL _play_switch;
    AVCaptureSession *_VideoCaptureSession;

    NSString *_logMsg;
    NSString *_tipsMsg;
    NSString *_testPath;
    NSInteger _cacheStrategy;

    UIButton *_btnCacheStrategy;
    UIView *_vCacheStrategy;
    UIButton *_radioBtnFast;
    UIButton *_radioBtnSmooth;
    UIButton *_radioBtnAUTO;
    UIButton *_helpBtn;
    BOOL _enableAttachToTRTC;
    TXVodPlayConfig *_config;
}

@property(nonatomic, retain) UITextField *txtRtmpUrl;

- (BOOL)startPlay;
- (void)stopPlay;
- (void)setEnableAttachVodToTRTC:(BOOL)enable trtcCloud:(NSObject *)trtcCloud;

@end

