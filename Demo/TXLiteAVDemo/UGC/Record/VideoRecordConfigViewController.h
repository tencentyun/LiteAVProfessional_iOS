//
//  VideoRecordConfigViewController.h
//  TXLiteAVDemo
//
//  Created by zhangxiang on 2017/9/12.
//  Copyright © 2017年 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TXLiteAVSDKHeader.h"
#import "VideoRecordConfig.h"

@interface VideoRecordConfigViewController : UIViewController
@property (copy, nonatomic) void(^onTapStart)(VideoRecordConfig* configure);
@end
