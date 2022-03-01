/*
* Module:   TRTCSettingsEffectLoopCountCell
*
* Function: 全局设置音效循环次数，以及停止所有音效播放
*
*/

#import "TRTCEffectSettingsBaseCell.h"
#import "TRTCEffectManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface TRTCSettingsEffectLoopCountCell : TRTCEffectSettingsBaseCell

@end


@interface TRTCSettingsEffectLoopCountItem : TRTCEffectSettingsBaseItem

@property (strong, nonatomic, readonly) TRTCEffectManager *manager;

- (instancetype)initWithManager:(TRTCEffectManager *)manager NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
