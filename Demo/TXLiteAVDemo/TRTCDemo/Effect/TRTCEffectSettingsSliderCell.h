/*
* Module:   TRTCSettingsSliderCell
*
* Function: 配置列表Cell，右侧是一个Slider
*
*/

#import "TRTCEffectSettingsBaseCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface TRTCEffectSettingsSliderCell : TRTCEffectSettingsBaseCell

@end


@interface TRTCEffectSettingsSliderItem : TRTCEffectSettingsBaseItem

@property (nonatomic) float sliderValue;
@property (nonatomic) float minValue;
@property (nonatomic) float maxValue;
@property (nonatomic) float step;
@property (nonatomic) BOOL continuous;
@property (copy, nonatomic, readonly) void (^action)(float);

- (instancetype)initWithTitle:(NSString *)title
                        value:(float)value
                          min:(float)min
                          max:(float)max
                         step:(float)step
                   continuous:(BOOL)continuous
                       action:(void (^)(float))action;

@end

NS_ASSUME_NONNULL_END
