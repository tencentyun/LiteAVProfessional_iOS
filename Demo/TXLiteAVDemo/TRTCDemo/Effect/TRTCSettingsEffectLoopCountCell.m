/*
* Module:   TRTCSettingsEffectLoopCountCell
*
* Function: 全局设置音效循环次数，以及停止所有音效播放
*
*/

#import "TRTCSettingsEffectLoopCountCell.h"
#import "Masonry.h"
#import "ColorMacro.h"
#import "UIImage+Additions.h"

@interface TRTCSettingsEffectLoopCountCell ()<UITextFieldDelegate>

@property (strong, nonatomic) UITextField *loopCountText;
@property (strong, nonatomic) UIButton *stopButton;

@end

@implementation TRTCSettingsEffectLoopCountCell

- (void)setupUI {
    [super setupUI];
    
    self.loopCountText = [[UITextField alloc] init];
    self.loopCountText.borderStyle = UITextBorderStyleRoundedRect;
    self.loopCountText.backgroundColor = UIColorFromRGB(0x4A4A4A);
    self.loopCountText.textColor = UIColorFromRGB(0x939393);
    self.loopCountText.font = [UIFont systemFontOfSize:15];
    self.loopCountText.delegate = self;
    self.loopCountText.textAlignment = NSTextAlignmentCenter;
    self.loopCountText.keyboardType = UIKeyboardTypeNumberPad;
    
    [self.contentView addSubview:self.loopCountText];
    [self.loopCountText mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.contentView);
        make.leading.equalTo(self.titleLabel.mas_trailing).offset(20);
        make.width.mas_equalTo(40);
    }];
    
    self.stopButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.stopButton.contentEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 10);
    [self.stopButton setTitle:@"停止所有音效" forState:UIControlStateNormal];
    self.stopButton.titleLabel.font = [UIFont systemFontOfSize:15];
    [self.stopButton setBackgroundImage:[[UIImage imageWithColor:UIColorFromRGB(0x05a764)
                                                 size:CGSizeMake(10, 10)
                                         cornerRadius:4]
                              stretchableImageWithLeftCapWidth:5 topCapHeight:5]
                    forState:UIControlStateNormal];
    [self.stopButton setBackgroundImage:[[UIImage imageWithColor:UIColorFromRGB(0x307250)
                                                 size:CGSizeMake(10, 10)
                                         cornerRadius:4]
                              stretchableImageWithLeftCapWidth:5 topCapHeight:5]
                    forState:UIControlStateHighlighted];

    [self.stopButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(30);
    }];
    
    [self.stopButton addTarget:self action:@selector(onClickStopButton:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.contentView addSubview:self.stopButton];
    [self.stopButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.contentView);
        make.trailing.equalTo(self.contentView).offset(-18);
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onTextChange)
                                                 name:UITextFieldTextDidChangeNotification
                                               object:self.loopCountText];
}

- (void)didUpdateItem:(TRTCEffectSettingsBaseItem *)item {
    if ([item isKindOfClass:[TRTCSettingsEffectLoopCountItem class]]) {
        self.loopCountText.text = [NSString stringWithFormat:@"%@", @(self.manager.loopCount)];
    }
}

- (void)onClickStopButton:(id)sender {
    [self.manager stopAllEffects];
}

- (void)onTextChange {
    NSInteger loopCount = [self.loopCountText.text integerValue];
    [self.manager setLoopCount:loopCount];
}

- (TRTCEffectManager *)manager {
    TRTCSettingsEffectLoopCountItem *effectItem = (TRTCSettingsEffectLoopCountItem *)self.item;
    return effectItem.manager;
}

@end


@implementation TRTCSettingsEffectLoopCountItem

- (instancetype)initWithManager:(TRTCEffectManager *)manager {
    if (self = [super init]) {
        self.title = @"循环次数";
        _manager = manager;
    }
    return self;
}

+ (Class)bindedCellClass {
    return [TRTCSettingsEffectLoopCountCell class];
}

- (NSString *)bindedCellId {
    return [TRTCSettingsEffectLoopCountItem bindedCellId];
}

@end

