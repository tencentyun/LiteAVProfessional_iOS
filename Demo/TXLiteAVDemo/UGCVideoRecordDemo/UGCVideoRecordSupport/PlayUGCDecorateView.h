#import <UIKit/UIKit.h>

#define kMaxRecordDuration 60.f

@protocol PlayUGCDecorateViewDelegate <NSObject>
- (void)closeRecord;
- (void)recordVideo:(BOOL)isStart;
- (void)resetRecord;
@end

/**
 *  观众端短视频录制
 */
@interface PlayUGCDecorateView : UIView

@property(nonatomic,weak) id<PlayUGCDecorateViewDelegate>delegate;

- (instancetype)initWithFrame:(CGRect)frame;

- (void) setVideoRecordProgress:(float) progress;

@end
