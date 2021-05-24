//
//  LebTRTCPlayerSettingContainer.h
//  TXLiteAVDemo_Enterprise
//
//  Created by jiruizhang on 2020/12/3.
//  Copyright © 2020 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "V2TXLivePlayer.h"

NS_ASSUME_NONNULL_BEGIN

@class LebPlayerSettingViewController;
@protocol LebPlayerSettingViewControllerDelegate <NSObject>

- (void)lebPlayerSettingVC:(LebPlayerSettingViewController *)container didClickStartVideo:(BOOL)start;
- (void)lebPlayerSettingVC:(LebPlayerSettingViewController *)container didClickMuteVideo:(BOOL)muteVideo;
- (void)lebPlayerSettingVC:(LebPlayerSettingViewController *)container didClickMuteAudio:(BOOL)muteAudio;
- (void)lebPlayerSettingVC:(LebPlayerSettingViewController *)container didClickLog:(BOOL)isLogShow;
- (void)lebPlayerSettingVC:(LebPlayerSettingViewController *)container enableVolumeEvaluation:(BOOL)isEnable;

@end

@interface LebPlayerSettingViewController : UIView
@property (nonatomic, assign) BOOL isStart;
@property (nonatomic, assign) BOOL isAudioMuted;
@property (nonatomic, assign) BOOL isVideoMuted;
@property (nonatomic, assign) BOOL isLogShow;
@property (nonatomic, weak) id<LebPlayerSettingViewControllerDelegate> delegate;

- (instancetype)initWithHostVC:(UIViewController *)hostVC
                     muteAudio:(BOOL)isAudioMuted
                     muteVideo:(BOOL)isVideoMuted
                       logView:(BOOL)isLogShow
                        player:(V2TXLivePlayer *)player;

//- (void)clearSettingVC;

@end

NS_ASSUME_NONNULL_END
