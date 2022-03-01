//
//  CameraStartPushAlertView.h
//  TXLiteAVDemo
//
//  Created by adams on 2021/7/20.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
typedef enum : NSUInteger {
    RTMP = 0,
    RTC  = 1,
} PushType;

typedef void (^GenerateCallback)(PushType);

@interface CameraStartPushAlertView : UIView

- (instancetype)initWithFrame:(CGRect)frame generateCallback:(GenerateCallback)callback;

- (void)show;

- (void)hide;

@end

NS_ASSUME_NONNULL_END
