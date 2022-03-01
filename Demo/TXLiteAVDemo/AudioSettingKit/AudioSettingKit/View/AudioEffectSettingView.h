//
//  AudioEffectSettingView.h
//  TCAudioSettingKit
//
//  Created by abyyxwang on 2020/5/26.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, AudioEffectSettingViewType) {
    AudioEffectSettingViewDefault,  // 默认大小，在底部弹起
    AudioEffectSettingViewCustom,   // 用户自定义大小，初始化frame为0
};

@protocol AudioEffectViewDelegate <NSObject>

- (void)onEffectViewHidden:(BOOL)isHidden;

@end

@class TXAudioEffectManager;
@class TCASKitTheme;
@interface AudioEffectSettingView : UIView

@property(nonatomic, weak) id<AudioEffectViewDelegate> delegate;

+ (CGFloat)height;

- (instancetype)initWithType:(AudioEffectSettingViewType)type;
- (instancetype)initWithType:(AudioEffectSettingViewType)type theme:(TCASKitTheme *)theme;

- (void)setIsDebugMode;
- (void)setAudioEffectManager:(TXAudioEffectManager *)manager;

- (void)show;
- (void)hide;
- (BOOL)isShow;

/// 停止播放音乐
- (void)stopPlay;

- (void)recoveryVoiceSetting;  // 恢复音效设置（一般禁用本地麦克风后，会导致音效设置失效）

/// 清除音效设置状态（再次恢复需要重新设置Manager）
- (void)resetAudioSetting;

/// 清除背景音乐播放状态 （主播暂停播放后需要恢复播放音乐的状态）
- (void)resetBgmSelectItemStatus;

@end

NS_ASSUME_NONNULL_END
