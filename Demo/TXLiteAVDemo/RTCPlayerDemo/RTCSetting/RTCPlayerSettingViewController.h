//
//  RTCTRTCPlayerSettingContainer.h
//  TXLiteAVDemo_Enterprise
//
//  Created by adams on 2021/7/22.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "V2TXLivePlayer.h"

NS_ASSUME_NONNULL_BEGIN

@class RTCPlayerSettingViewController;
@protocol RTCPlayerSettingViewControllerDelegate <NSObject>

- (void)RTCPlayerSettingVC:(RTCPlayerSettingViewController *)container didClickStartVideo:(BOOL)start;
- (void)RTCPlayerSettingVC:(RTCPlayerSettingViewController *)container didClickMuteVideo:(BOOL)muteVideo;
- (void)RTCPlayerSettingVC:(RTCPlayerSettingViewController *)container didClickMuteAudio:(BOOL)muteAudio;
- (void)RTCPlayerSettingVC:(RTCPlayerSettingViewController *)container didClickLog:(BOOL)isLogShow;
- (void)RTCPlayerSettingVC:(RTCPlayerSettingViewController *)container enableVolumeEvaluation:(BOOL)isEnable;

@end

@interface                                                            RTCPlayerSettingViewController : UIView
@property(nonatomic, assign) BOOL                                     isStart;
@property(nonatomic, assign) BOOL                                     isAudioMuted;
@property(nonatomic, assign) BOOL                                     isVideoMuted;
@property(nonatomic, assign) BOOL                                     isLogShow;
@property(nonatomic, assign) V2TXLiveFillMode                         fillMode;
@property(nonatomic, weak) id<RTCPlayerSettingViewControllerDelegate> delegate;

- (instancetype)initWithHostVC:(UIViewController *)hostVC muteAudio:(BOOL)isAudioMuted muteVideo:(BOOL)isVideoMuted logView:(BOOL)isLogShow player:(V2TXLivePlayer *)player;

//- (void)clearSettingVC;

@end

NS_ASSUME_NONNULL_END
