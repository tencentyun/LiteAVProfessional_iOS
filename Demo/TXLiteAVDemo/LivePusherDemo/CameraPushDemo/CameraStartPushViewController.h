//
//  CameraStartPushViewController.h
//  TXLiteAVDemo
//
//  Created by adams on 2021/7/20.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

static NSString *const kPUSH_URL      = @"url_push";
static NSString *const kPUSH_TYPE     = @"push_type";
static NSString *const kRTMP_PLAY_URL = @"url_play_rtmp";
static NSString *const kFLV_PLAY_URL  = @"url_play_flv";
static NSString *const kHLS_PLAY_URL  = @"url_play_hls";
static NSString *const kLEB_PLAY_URL  = @"url_play_leb";
static NSString *const kRTC_PLAY_URL  = @"url_play_rtc";

static NSString *const RTC_PUSH_URL  = @"trtc://cloud.tencent.com/push/";
static NSString *const RTMP_PLAY_URL = @"rtmp://3891.liveplay.myqcloud.com/live/";
static NSString *const HTTP_PLAY_URL = @"http://3891.liveplay.myqcloud.com/live/";

@interface CameraStartPushViewController : UIViewController

@end

@interface TCRTCUtil : NSObject
+ (NSMutableDictionary *)generateRTCURL;
@end

NS_ASSUME_NONNULL_END
