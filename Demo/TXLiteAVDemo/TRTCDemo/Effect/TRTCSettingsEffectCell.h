/*
* Module:   TRTCSettingsEffectCell
*
* Function: 音效Cell, 包含音效的上传开关，音量调整，播放和停止操作。
*
*    1. TRTCSettingsEffectItem保存设置给Cell的音效数据TRTCAudioEffectParam，
*       以及音效管理对象TXAudioEffectManager
*
*/

#import "TRTCSettingsBaseCell.h"
#import "TRTCEffectManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface TRTCSettingsEffectCell : TRTCSettingsBaseCell

@end


@interface TRTCSettingsEffectItem : TRTCSettingsBaseItem

@property (strong, nonatomic, readonly) TRTCAudioEffectConfig *effect;
@property (strong, nonatomic, readonly) TRTCEffectManager *manager;
@property (nonatomic) BOOL isPlaying;

- (instancetype)initWithEffect:(TRTCAudioEffectConfig *)effect
                       manager:(TRTCEffectManager *)manager NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
