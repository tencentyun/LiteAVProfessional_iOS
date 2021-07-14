//
//  TRTCRemoteView.h
//  TXLiteAVDemo
//
//  Created by bluedang on 2021/5/18.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TRTCRemoteUserConfig.h"

NS_ASSUME_NONNULL_BEGIN

@class TRTCVideoView;

@protocol TRTCVideoViewDelegate <NSObject>

@optional
- (void)onViewTap:(TRTCVideoView*)view;
@end

@interface TRTCVideoView : UIImageView
@property (nonatomic, strong) NSString *userId;
@property (nonatomic, weak) id<TRTCVideoViewDelegate> delegate;
@property (nonatomic, strong) UIProgressView* audioVolumeIndicator;
@property (nonatomic, strong) TRTCRemoteUserConfig *userConfig;
- (void)setAudioVolumeRadio:(float)volumeRadio;
- (void)showText:(NSString *)text;
@end

NS_ASSUME_NONNULL_END
