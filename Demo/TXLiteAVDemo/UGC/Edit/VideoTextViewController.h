//
//  VideoTextViewController.h
//  DeviceManageIOSApp
//
//  Created by rushanting on 2017/5/18.
//  Copyright © 2017年 tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
@class TXVideoEditer;
@class VideoPreview;
@class VideoTextFiled;

/**
 字幕添加操作操作器
 */

@interface VideoTextInfo : NSObject
@property (nonatomic, strong) VideoTextFiled* textField;
@property (nonatomic, assign) CGFloat startTime; //in seconds
@property (nonatomic, assign) CGFloat endTime;
@end


@protocol VideoTextViewControllerDelegate <NSObject>
//返回
- (void)onSetVideoTextInfosFinish:(NSArray<VideoTextInfo*>*)videoTextInfos;

@end

@interface VideoTextViewController : UIViewController

@property (nonatomic, weak) id<VideoTextViewControllerDelegate> delegate;

- (id)initWithVideoEditer:(TXVideoEditer*)videoEditer previewView:(VideoPreview*)previewView startTime:(CGFloat)startTime endTime:(CGFloat)endTime videoTextInfos:(NSArray<VideoTextInfo*>*)videoTextInfos;

@end
