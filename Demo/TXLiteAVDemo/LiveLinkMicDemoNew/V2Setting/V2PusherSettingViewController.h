//
//  V2TRTCSettingContainer.h
//  TXLiteAVDemo_Enterprise
//
//  Created by jiruizhang on 2020/12/3.
//  Copyright © 2020 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "V2TXLivePusher.h"
#import "V2PusherSettingModel.h"

NS_ASSUME_NONNULL_BEGIN

@class V2PusherSettingViewController;
@protocol V2PusherSettingViewControllerDelegate <NSObject>
- (void)v2PusherSettingVC:(V2PusherSettingViewController *)container didClickStartVideo:(BOOL)start;
- (void)v2PusherSettingVC:(V2PusherSettingViewController *)container didClickMuteVideo:(BOOL)muteVideo;
- (void)v2PusherSettingVCDidClickSwitchCamera:(V2PusherSettingViewController *)container value:(BOOL)frontCamera;
- (void)v2PusherSettingVC:(V2PusherSettingViewController *)container didClickMuteAudio:(BOOL)muteAudio;
- (void)v2PusherSettingVC:(V2PusherSettingViewController *)container didClickLog:(BOOL)isLogShow;
- (void)v2PusherSettingVCDidClickLocalRotation:(V2PusherSettingViewController *)container;

@end

@interface V2PusherSettingViewController : UIView
@property (nonatomic, weak) V2TXLivePusher *pusher;
@property (nonatomic, assign) BOOL isStart;
@property (nonatomic, assign) BOOL frontCamera;
@property (nonatomic, assign) BOOL isAudioMuted;
@property (nonatomic, assign) BOOL isVideoMuted;
@property (nonatomic, assign) BOOL isLogShow;
@property (nonatomic, weak) id<V2PusherSettingViewControllerDelegate> delegate;

- (instancetype)initWithHostVC:(UIViewController *)hostVC
                     muteVideo:(BOOL)isVideoMuted
                     muteAudio:(BOOL)isAudioMuted
                       logView:(BOOL)isLogShow
                        pusher:(V2TXLivePusher *)pusher
               pusherViewModel:(V2PusherSettingModel *)pusherVM;
- (void)stopPush;
@end

NS_ASSUME_NONNULL_END
