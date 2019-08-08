//
//  VideoPasterViewController.h
//  DeviceManageIOSApp
//
//  Created by lynxzhang on 2017/5/18.
//  Copyright © 2017年 tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
@class TXVideoEditer;
@class VideoPreview;
@class VideoPasterView;

/**
 贴纸操作器
 */

typedef NS_ENUM(NSInteger,PasterInfoType)
{
    PasterInfoType_Animate,
    PasterInfoType_static,
};

@interface VideoPasterInfo : NSObject
@property (nonatomic, assign) PasterInfoType pasterInfoType;
@property (nonatomic, strong) VideoPasterView* pasterView;
@property (nonatomic, strong) UIImage  *iconImage;
@property (nonatomic, assign) CGFloat  startTime;    //s
@property (nonatomic, assign) CGFloat  endTime;      //s
@property (nonatomic, assign) CGSize   size;
//动态贴纸
@property (nonatomic, strong) NSString *path;        //动态贴纸需要文件路径 -> SDK
@property (nonatomic, assign) CGFloat  rotateAngle;  //动态贴纸需要传入旋转角度 -> SDK
@property (nonatomic, assign) float    duration;
@property (nonatomic, strong) NSArray<UIImage*> *imageList;
//静态贴纸
@property (nonatomic, strong) UIImage  *image;       //静态贴纸需要贴纸Image -> SDK
@end


@protocol VideoPasterViewControllerDelegate <NSObject>
//返回
- (void)onSetVideoPasterInfosFinish:(NSArray<VideoPasterInfo*>*)videoPasterInfo;

@end

@interface VideoPasterViewController : UIViewController

@property (nonatomic, weak) id<VideoPasterViewControllerDelegate> delegate;

- (id)initWithVideoEditer:(TXVideoEditer*)videoEditer previewView:(VideoPreview*)previewView startTime:(CGFloat)startTime endTime:(CGFloat)endTime videoPasterInfos:(NSArray<VideoPasterInfo*>*)videoPasterInfos;

@end

