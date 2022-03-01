/*
 * Module:   TRTCAudioConfig
 *
 * Function: 保存音频的设置项
 *
 *    1. 在init中，会检查UserDefauls是否有历史记录，如存在则用历史记录初始化对象
 *
 *    2. 在dealloc中，将对象当前的值保存进UserDefaults中
 *
 */

#import "TRTCAudioConfig.h"

@implementation TRTCAudioConfig

- (instancetype)init {
    if (self = [super init]) {
        self.isEnabled       = YES;
        self.isCustomCapture = NO;
        [self loadFromLocal];
    }
    return self;
}

- (void)dealloc {
    [self saveToLocal];
}

- (void)loadFromLocal {
    NSDictionary *dict = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"TRTCAudioConfig"];
    if (!dict) {
        return;
    }
    self.route                     = [dict[@"route"] intValue];
    self.volumeType                = [dict[@"volumeType"] integerValue];
    self.isEarMonitoringEnabled    = [dict[@"isEarMonitoringEnabled"] boolValue];
    self.isVolumeEvaluationEnabled = [dict[@"isVolumeEvaluationEnabled"] boolValue];
}

- (void)saveToLocal {
    NSDictionary *dict = @{
        @"route" : @(self.route),
        @"volumeType" : @(self.volumeType),
        @"isEarMonitoringEnabled" : @(self.isEarMonitoringEnabled),
        @"isVolumeEvaluationEnabled" : @(self.isVolumeEvaluationEnabled),
    };
    [[NSUserDefaults standardUserDefaults] setValue:dict forKey:@"TRTCAudioConfig"];
}

+ (NSArray<NSString *> *)audiobitrateList {
    return @[ @"16", @"20", @"32", @"50", @"64", @"96", @"128"];
}
@end
