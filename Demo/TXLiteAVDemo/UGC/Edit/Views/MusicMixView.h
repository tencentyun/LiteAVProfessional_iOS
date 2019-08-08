//
//  MusicMixView.h
//  DeviceManageIOSApp
//
//  Created by rushanting on 2017/5/12.
//  Copyright © 2017年 tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MusicCollectionCell.h"

/**
 视频编辑混音view
 */

@protocol MusicMixViewDelegate <NSObject>

- (void)onOpenLocalMusicList;                                                                               //打开本地音乐
- (void)onSetVideoVolume:(CGFloat)videoVolume musicVolume:(CGFloat)musicVolume;                             //音量设置
- (void)onSetBGMWithFileAsset:(AVAsset*)fileAsset startTime:(CGFloat)startTime endTime:(CGFloat)endTime; //音乐设置

@end

@interface MusicMixView : UIView

@property (nonatomic, weak) id<MusicMixViewDelegate> delegate;

- (void)addMusicInfo:(MusicInfo*)musicInfo;

@end
