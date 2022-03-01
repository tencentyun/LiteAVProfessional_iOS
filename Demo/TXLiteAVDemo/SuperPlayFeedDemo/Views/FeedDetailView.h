//
//  FeedDetailView.h
//  TXLiteAVDemo
//
//  Created by 路鹏 on 2021/10/28.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FeedHeadModel.h"
#import "FeedVideoModel.h"
#import "FeedDetailHeadView.h"
#import "SuperPlayer.h"

NS_ASSUME_NONNULL_BEGIN

@interface FeedDetailView : UIView

@property (nonatomic, strong) FeedDetailHeadView  *headView;

@property (nonatomic, strong) FeedHeadModel       *model;

@property (nonatomic, strong) FeedVideoModel      *videoModel;

@property (nonatomic, strong) SuperPlayerView     *superPlayView;

/**
 * 设置列表数据
 * @param videos               列表数据
*/
- (void)setListData:(NSArray *)videos;

/**
 * 销毁列表播放器
*/
- (void)destory;

@end

NS_ASSUME_NONNULL_END
