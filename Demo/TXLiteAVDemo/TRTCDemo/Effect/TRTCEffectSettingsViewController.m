/*
* Module:   TRTCEffectSettingsViewController
*
* Function: 音效设置页，包含一个全部音效的列表，以及音效的全局设置项
*
*    1. Demo的音效列表定义在TXAudioEffectManager中
*
*    2. 音效Cell为TRTCSettingsEffectCell，
*       音效的循环次数设置在TRTCSettingsEffectLoopCountCell中
*
*/

#import "TRTCEffectSettingsViewController.h"
#import "TRTCSettingsEffectCell.h"
#import "TRTCSettingsEffectLoopCountCell.h"
#import "TRTCEffectSettingsSliderCell.h"
#import "TRTCEffectManager.h"
#import "ColorMacro.h"

@interface TRTCEffectSettingsViewController ()

@end

@implementation TRTCEffectSettingsViewController

- (void)makeCustomRegistrition {
    [self.tableView registerClass:TRTCSettingsEffectItem.bindedCellClass
           forCellReuseIdentifier:TRTCSettingsEffectItem.bindedCellId];
    [self.tableView registerClass:TRTCSettingsEffectLoopCountItem.bindedCellClass
           forCellReuseIdentifier:TRTCSettingsEffectLoopCountItem.bindedCellId];
}

- (instancetype)initWithManager:(TRTCEffectManager *)manager {
    if (self = [super init]) {
        self.manager = manager;
    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColorFromRGB(0x13233F);
    
    __weak __typeof(self) wSelf = self;
    NSArray *otherItems = @[
        [[TRTCEffectSettingsSliderItem alloc] initWithTitle:@"全局音量"
                                                value:100 min:0 max:100 step:1
                                           continuous:YES
                                               action:^(float value) {
            [wSelf onChangeGlobalVolume:(NSInteger)value];
        }],
        [[TRTCSettingsEffectLoopCountItem alloc] initWithManager:self.manager],
    ];
    self.items = [[[self buildEffectItems] arrayByAddingObjectsFromArray:otherItems]mutableCopy];
}

- (NSArray *)buildEffectItems {
    NSMutableArray *items = [NSMutableArray array];
    for (TRTCAudioEffectConfig *effect in self.manager.effects) {
        TRTCSettingsEffectItem *item = [[TRTCSettingsEffectItem alloc] initWithEffect:effect manager:self.manager];
        NSLog(@"___ cell: %@", NSStringFromClass([item.class bindedCellClass]));
        [items addObject:item];
    }
    return items;
}

#pragma mark - Actions

- (void)onChangeGlobalVolume:(NSInteger)volume {
    [self.manager setGlobalVolume:volume];
}

@end
