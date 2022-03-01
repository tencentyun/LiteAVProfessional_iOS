//
//  TCAudioSettingManager.h
//  TCAudioSettingKit
//
//  Created by abyyxwang on 2020/5/28.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
@class TXAudioEffectManager;
@protocol TCAudioMusicPlayStatusDelegate <NSObject>

- (void)onStartPlayMusic;
- (void)onStopPlayerMusic;
- (void)onCompletePlayMusic;
- (void)onPlayingWithCurrent:(NSInteger)currentSec total:(NSInteger)totalSec;

@end

@interface TCAudioSettingManager : NSObject

@property(nonatomic, weak) id<TCAudioMusicPlayStatusDelegate> delegate;

- (NSInteger)getcurrentMusicTatolDurationInMs;

- (void)setAudioEffectManager:(TXAudioEffectManager *)manager;

/// 恢复初始状态
- (void)clearStates;

/// 设置变声效果
/// @param value 变声效果
- (void)setVoiceChangerTypeWithValue:(NSInteger)value;

/// 设置混响效果
/// @param value 混响效果
- (void)setReverbTypeWithValue:(NSInteger)value;

/// 设置人声音量
/// @param volume 音量 0-100
- (void)setVoiceVolume:(NSInteger)volume;

/// 设置音乐音量
/// @param volume 音量 0-100
- (void)setBGMVolume:(NSInteger)volume;

- (void)setBGMPitch:(CGFloat)value;

/// 设置音乐速度
/// @param rate 速度 0.5-2
- (void)setBGMRate:(CGFloat)rate;

/// 设置本地音乐音量
/// @param volume 音量 0-100
- (void)setLocalVolume:(NSInteger)volume;

/// 设置远端听到的音乐音量
/// @param volume 音量 0-100
- (void)setRemoteVolume:(NSInteger)volume;

/// 设置播放进度
/// @param progress 0-100
- (void)setProgress:(CGFloat)progress;

/// 播放音乐
/// @param path 音乐路径
/// @param bgmID 音乐ID
- (void)playMusicWithPath:(NSString *)path bgmID:(NSInteger)bgmID;

- (void)stopPlay;

- (void)pausePlay;

- (void)resumePlay;

@end

NS_ASSUME_NONNULL_END
