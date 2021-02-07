//
//  V2TRTCPlayerSettingContainer.h
//  TXLiteAVDemo_Enterprise
//
//  Created by jiruizhang on 2020/12/3.
//  Copyright © 2020 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "V2TXLivePlayer.h"

NS_ASSUME_NONNULL_BEGIN

@class V2PlayerSettingViewController;
@protocol V2PlayerSettingViewControllerDelegate <NSObject>

- (void)v2PlayerSettingVC:(V2PlayerSettingViewController *)container didClickStartVideo:(BOOL)start;
- (void)v2PlayerSettingVC:(V2PlayerSettingViewController *)container didClickMuteVideo:(BOOL)muteVideo;
- (void)v2PlayerSettingVC:(V2PlayerSettingViewController *)container didClickMuteAudio:(BOOL)muteAudio;
- (void)v2PlayerSettingVC:(V2PlayerSettingViewController *)container didClickLog:(BOOL)isLogShow;
- (void)v2PlayerSettingVC:(V2PlayerSettingViewController *)container enableVolumeEvaluation:(BOOL)isEnable;

@end

@interface V2PlayerSettingViewController : UIView
@property (nonatomic, assign) BOOL isStart;
@property (nonatomic, assign) BOOL isAudioMuted;
@property (nonatomic, assign) BOOL isVideoMuted;
@property (nonatomic, assign) BOOL isLogShow;
@property (nonatomic, weak) id<V2PlayerSettingViewControllerDelegate> delegate;

- (instancetype)initWithHostVC:(UIViewController *)hostVC
                     muteAudio:(BOOL)isAudioMuted
                     muteVideo:(BOOL)isVideoMuted
                       logView:(BOOL)isLogShow
                        player:(V2TXLivePlayer *)player;

//- (void)clearSettingVC;

@end

NS_ASSUME_NONNULL_END
