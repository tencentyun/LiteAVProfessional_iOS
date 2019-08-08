#import "PlayUGCDecorateView.h"
//#import "TCIMPlatform.h"
#import "UIView+CustomAutoLayout.h"
#import <AVFoundation/AVFoundation.h>
#import "UIView+Additions.h"
#import "TXColor.h"

#define kMinRecordDuration 5.f
#define kMinRecordedDuration (kMinRecordDuration/kMaxRecordDuration)

@implementation PlayUGCDecorateView
{
    UIView               *_vRecordVideo;
    UILabel              *_labRecordedDurationTips;
    UIImageView           *_imgRecordedDurationTips;
    UIView               *_vRecordedDurationTips;
    UILabel              *_labRecordedDuration;
    UIProgressView        *_prgRecordedProgress;
    UIButton             *_btnClose;
    UIButton             *_btnRecord;
    UIButton             *_btnReset;
    
    BOOL                _recordStart;
    
    float               _recordProgress;
}

-(instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onLogout:) name:logoutNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidEnterBackground:)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onAudioSessionEvent:)
                                                     name:AVAudioSessionInterruptionNotification
                                                   object:nil];
        
        _recordStart = NO;
        _recordProgress = 0.f;
        
        [self initUI];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)initUI
{
    
    // 视频录制
    _vRecordVideo = [[UIView alloc] init];
    _vRecordVideo.hidden = NO;
    _vRecordVideo.backgroundColor = [UIColor clearColor];
    
    _labRecordedDurationTips = [[UILabel alloc] init];
    [_labRecordedDurationTips setText:@"至少要录到这里"];
    _labRecordedDurationTips.font = [UIFont systemFontOfSize:14];
    _labRecordedDurationTips.textColor = [UIColor whiteColor];
    _labRecordedDurationTips.textAlignment = NSTextAlignmentCenter;
    _labRecordedDurationTips.lineBreakMode = NSLineBreakByWordWrapping;
    
    _imgRecordedDurationTips = [[UIImageView alloc ] init];
    _imgRecordedDurationTips.image = [UIImage imageNamed:@"video_record_bubble"];
    
    _labRecordedDuration = [[UILabel alloc] init];
    [_labRecordedDuration setText:@"00:00"];
    _labRecordedDuration.font = [UIFont systemFontOfSize:10];
    _labRecordedDuration.textColor = [UIColor whiteColor];
    _labRecordedDuration.textAlignment = NSTextAlignmentLeft;
    
    _prgRecordedProgress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    _prgRecordedProgress.progress = 0.f;
    _prgRecordedProgress.progressTintColor = TXColor.cyan;
    
    _vRecordedDurationTips = [[UILabel alloc] init];
    _vRecordedDurationTips.backgroundColor = TXColor.cyan;
    
    _btnClose = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnClose setImage:[UIImage imageNamed:@"video_record_close"] forState:UIControlStateNormal];
    [_btnClose addTarget:self action:@selector(closeRecord) forControlEvents:UIControlEventTouchUpInside];
    
    _btnRecord = [UIButton buttonWithType:UIButtonTypeCustom];
    if (!_recordStart) {
        [_btnRecord setImage:[UIImage imageNamed:@"video_record_start"] forState:UIControlStateNormal];
        [_btnRecord setImage:[UIImage imageNamed:@"video_record_start_press"] forState:UIControlStateHighlighted];
    }
    _btnRecord.selected = NO;
    [_btnRecord addTarget:self action:@selector(recordVideo) forControlEvents:UIControlEventTouchUpInside];
    
    _btnReset = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnReset setImage:[UIImage imageNamed:@"video_record_again"] forState:UIControlStateNormal];
    [_btnReset setImage:[UIImage imageNamed:@"video_record_again_press"] forState:UIControlStateHighlighted];
    [_btnReset setTitle:@"重录" forState:UIControlStateNormal];
    [_btnReset setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _btnReset.titleEdgeInsets = UIEdgeInsetsMake(0, 3, 0, 0);
    _btnReset.titleLabel.font = [UIFont systemFontOfSize:16];
    [_btnReset.layer setMasksToBounds:YES];
    [_btnReset.layer setCornerRadius:_btnReset.height/2];
    [_btnReset addTarget:self action:@selector(resetRecord) forControlEvents:UIControlEventTouchUpInside];
    
    [self addSubview:_vRecordVideo];
    [_vRecordVideo addSubview:_imgRecordedDurationTips];
    [_vRecordVideo addSubview:_labRecordedDurationTips];
    [_vRecordVideo addSubview:_labRecordedDuration];
    [_vRecordVideo addSubview:_prgRecordedProgress];
    [_vRecordVideo addSubview:_vRecordedDurationTips];
    [_vRecordVideo addSubview:_btnClose];
    [_vRecordVideo addSubview:_btnRecord];
    [_vRecordVideo addSubview:_btnReset];
    
    [_vRecordVideo setSize:CGSizeMake(self.width, self.height)];
    _vRecordVideo.frame = self.frame;
    
    [_imgRecordedDurationTips setSize:CGSizeMake(120, 20)];
    [_imgRecordedDurationTips alignParentBottomWithMargin:110];
    [_imgRecordedDurationTips alignParentLeftWithMargin:15];
    
    [_labRecordedDurationTips setSize:CGSizeMake(120, 14)];
    [_labRecordedDurationTips alignParentBottomWithMargin:115];
    [_labRecordedDurationTips alignParentLeftWithMargin:15];
    
    [_labRecordedDuration setSize:CGSizeMake(30, 10)];
    [_labRecordedDuration alignParentBottomWithMargin:110];
    [_labRecordedDuration alignParentRightWithMargin:15];
    
    [_prgRecordedProgress setSize:CGSizeMake(self.width-30, 2)];
    [_prgRecordedProgress alignParentBottomWithMargin:100];
    [_prgRecordedProgress alignParentLeftWithMargin:15];
    
    [_vRecordedDurationTips setSize:CGSizeMake(2, 4)];
    [_vRecordedDurationTips alignParentBottomWithMargin:99];
    [_vRecordedDurationTips alignParentLeftWithMargin:15 + _prgRecordedProgress.width*kMinRecordedDuration];
    
    [_btnRecord setSize:CGSizeMake(65, 65)];
    [_btnRecord alignParentBottomWithMargin:15];
    _btnRecord.center = CGPointMake(self.center.x, _btnRecord.center.y);
    
    [_btnClose setSize:CGSizeMake(20, 20)];
    [_btnClose alignParentBottomWithMargin:40];
    _btnClose.center = CGPointMake(_btnRecord.center.x/2, _btnClose.center.y);
    
    [_btnReset setSize:CGSizeMake(100, 16)];
    [_btnReset alignParentBottomWithMargin:40];
    _btnReset.center = CGPointMake(_btnRecord.center.x*3/2, _btnReset.center.y);
    
    
    _labRecordedDurationTips.hidden = YES;
    _imgRecordedDurationTips.hidden = YES;
}

- (void)closeRecord
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(closeRecord)]) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [self.delegate closeRecord];
    }
    
    [self resetRecord];
}

- (void)recordVideo
{
    _recordStart = !_recordStart;
    _btnRecord.selected = NO;
    if (!_recordStart) {
        [_btnRecord setImage:[UIImage imageNamed:@"video_record_start"] forState:UIControlStateNormal];
        [_btnRecord setImage:[UIImage imageNamed:@"video_record_start_press"] forState:UIControlStateHighlighted];
        
        _prgRecordedProgress.progress = 0.f;
        [_labRecordedDuration setText:@"00:00"];
        
        {
//            _recordStart = YES;
            if (_recordProgress < kMinRecordedDuration) {
                [self toastTip:@"至少要录够5秒"];
                [self resetRecord];
                return;
            }
        }
    } else {
        [_btnRecord setImage:[UIImage imageNamed:@"video_record_stop"] forState:UIControlStateNormal];
        [_btnRecord setImage:[UIImage imageNamed:@"video_record_stop_press"] forState:UIControlStateHighlighted];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(recordVideo:)]) {
        [self.delegate recordVideo:_recordStart];
    }
}

- (void)resetRecord
{
//    if (!_recordStart) return;
    
    _recordProgress = 0.f;
    _recordStart = NO;
    _btnRecord.selected = NO;
    [_btnRecord setImage:[UIImage imageNamed:@"video_record_start"] forState:UIControlStateNormal];
    [_btnRecord setImage:[UIImage imageNamed:@"video_record_start_press"] forState:UIControlStateHighlighted];
    
    _prgRecordedProgress.progress = 0.f;
    [_labRecordedDuration setText:@"00:00"];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(resetRecord)]) {
        [self.delegate resetRecord];
    }
}

- (void) setVideoRecordProgress:(float) progress
{
    _recordProgress = progress;
    
    [_prgRecordedProgress setProgress:progress animated:YES];
    [_labRecordedDuration setText:[NSString  stringWithFormat:@"00:%02u", (UInt32)(progress*kMaxRecordDuration)]];
    if (progress*kMaxRecordDuration >= kMaxRecordDuration) {
        if (_recordStart) [self recordVideo];
    }
}

// 监听登出消息
- (void)onLogout:(NSNotification*)notice
{
    [self closeRecord];
}

//-(void)onRecvGroupSender:(IMUserAble *)info textMsg:(NSString *)msgText
//{
//    
//}
//
//- (void)onRecvGroupSystemMessage:(TIMGroupSystemElem *)msg
//{
//    // 群被解散
//    if (msg.type == TIM_GROUP_SYSTEM_DELETE_GROUP_TYPE) {
//        [HUDHelper alert:kErrorMsgLiveStopped cancel:@"确定" action:^{
//            [self  closeRecord];
//        }];
//    }
//}

- (void)onAudioSessionEvent:(NSNotification *)noti
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(closeRecord)]) {
        [self.delegate closeRecord];
    }
    
    _recordProgress = 0.f;
    _recordStart = NO;
    _btnRecord.selected = NO;
    [_btnRecord setImage:[UIImage imageNamed:@"video_record_start"] forState:UIControlStateNormal];
    [_btnRecord setImage:[UIImage imageNamed:@"video_record_start_press"] forState:UIControlStateHighlighted];
    
    _prgRecordedProgress.progress = 0.f;
    [_labRecordedDuration setText:@"00:00"];
}

- (void)applicationDidEnterBackground:(NSNotification *)noti
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(closeRecord)]) {
        [self.delegate closeRecord];
    }
    
    _recordProgress = 0.f;
    _recordStart = NO;
    _btnRecord.selected = NO;
    [_btnRecord setImage:[UIImage imageNamed:@"video_record_start"] forState:UIControlStateNormal];
    [_btnRecord setImage:[UIImage imageNamed:@"video_record_start_press"] forState:UIControlStateHighlighted];
    
    _prgRecordedProgress.progress = 0.f;
    [_labRecordedDuration setText:@"00:00"];
}

- (float) heightForString:(UITextView *)textView andWidth:(float)width{
    CGSize sizeToFit = [textView sizeThatFits:CGSizeMake(width, MAXFLOAT)];
    return sizeToFit.height;
}

- (void) toastTip:(NSString*)toastInfo
{
    CGRect frameRC = [[UIScreen mainScreen] bounds];
    frameRC.origin.y = frameRC.size.height - 110;
    frameRC.size.height -= 110;
    __block UITextView * toastView = [[UITextView alloc] init];
    
    toastView.editable = NO;
    toastView.selectable = NO;
    
    frameRC.size.height = [self heightForString:toastView andWidth:frameRC.size.width];
    
    toastView.frame = frameRC;
    
    toastView.text = toastInfo;
    toastView.backgroundColor = [UIColor whiteColor];
    toastView.alpha = 0.5;
    
    [self addSubview:toastView];
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC);
    
    dispatch_after(popTime, dispatch_get_main_queue(), ^(){
        [toastView removeFromSuperview];
        toastView = nil;
    });
}

@end
