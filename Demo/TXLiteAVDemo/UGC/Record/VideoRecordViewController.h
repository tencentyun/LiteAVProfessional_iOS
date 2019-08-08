#import <UIKit/UIKit.h>
#import "TXLiteAVSDKHeader.h"
#import "VideoRecordConfig.h"

@interface RecordMusicInfo : NSObject
@property (nonatomic, copy) NSString* filePath;
@property (nonatomic, copy) NSString* soneName;
@property (nonatomic, copy) NSString* singerName;
@property (nonatomic, assign) CGFloat duration;
@end

/**
 *  短视频录制VC
 */
@interface VideoRecordViewController : UIViewController
@property (nonatomic, copy) void(^onRecordCompleted)(TXUGCRecordResult *result);
-(instancetype)initWithConfigure:(VideoRecordConfig*)configure;
@end
