//
//  V2MainProtocolSelectViewController.m
//  TXLiteAVDemo
//
//  Created by coddyliu on 2020/12/5.
//  Copyright © 2020 Tencent. All rights reserved.
//

#import "V2MainProtocolSelectViewController.h"
#import "V2MainProtocolSelectSegmentView.h"
#import "Masonry.h"
#import <QuartzCore/QuartzCore.h>
#import "V2QRScanViewController.h"
#import "GenerateTestUserSig.h"
#import "MBProgressHUD.h"
#import "V2LiveUtils.h"

#define ViewWidth self.frame.size.width
#define ViewHeight self.frame.size.height

#define ScreenWidth UIScreen.mainScreen.bounds.size.width
#define ScreenHeight UIScreen.mainScreen.bounds.size.height
#define MAXY(view) CGRectGetMaxX(view.frame)

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 \
alpha:1.0]

#define V2LogSimple() \
        NSLog(@"[%@ %p %s %d]", NSStringFromClass(self.class), self, __func__, __LINE__);
#define V2Log(_format_, ...) \
        NSLog(@"[%@ %p %s %d] %@", NSStringFromClass(self.class), self, __func__, __LINE__, [NSString stringWithFormat:_format_, ##__VA_ARGS__]);

@interface V2URLSettingRoomView : UIView
@property (nonatomic, strong) UITextField *roomIdInputTextField;
@property (nonatomic, strong) UITextField *userIdInputTextField;
@property (nonatomic, strong) UITextField *remoteUserIdInputTextField;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIButton *generateButton;
@property (nonatomic, strong) UIButton *scanButton;
@property (nonatomic, strong) UIButton *startButton;
@property (nonatomic, assign) BOOL isPush;
@end

@implementation V2URLSettingRoomView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self constructSubviews];
        [self configSubview];
    }
    return self;
}

- (void)constructSubviews {
    self.roomIdInputTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 10, ViewWidth, 48)];
    self.roomIdInputTextField.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.roomIdInputTextField.layer.borderWidth = 1.0;
    self.roomIdInputTextField.font = [UIFont systemFontOfSize:16];
    self.roomIdInputTextField.textColor = [UIColor whiteColor];
    [self addSubview:self.roomIdInputTextField];
    
    self.remoteUserIdInputTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, MAXY(self.userIdInputTextField), ViewWidth, 48)];
    self.remoteUserIdInputTextField.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.remoteUserIdInputTextField.layer.borderWidth = 1.0;
    self.remoteUserIdInputTextField.font = [UIFont systemFontOfSize:16];
    self.remoteUserIdInputTextField.textColor = [UIColor whiteColor];
    [self addSubview:self.remoteUserIdInputTextField];

    self.userIdInputTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, MAXY(self.roomIdInputTextField), ViewWidth, 48)];
    self.userIdInputTextField.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.userIdInputTextField.layer.borderWidth = 1.0;
    self.userIdInputTextField.font = [UIFont systemFontOfSize:16];
    self.userIdInputTextField.textColor = [UIColor whiteColor];
    [self addSubview:self.userIdInputTextField];
    
    self.cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(0, MAXY(self.remoteUserIdInputTextField) + 10, ViewWidth, 48)];
    self.cancelButton.backgroundColor = UIColorFromRGB(0x2243EC);
    self.cancelButton.titleLabel.textColor = [UIColor whiteColor];
    self.cancelButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [self.cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    [self addSubview:self.cancelButton];

    self.generateButton = [[UIButton alloc] initWithFrame:CGRectMake(0, MAXY(self.remoteUserIdInputTextField) + 10, ViewWidth, 48)];
    self.generateButton.backgroundColor = UIColorFromRGB(0x2243EC);
    self.generateButton.titleLabel.textColor = [UIColor whiteColor];
    self.generateButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [self.generateButton setTitle:@"自动生成" forState:UIControlStateNormal];
    [self addSubview:self.generateButton];

    self.scanButton = [[UIButton alloc] initWithFrame:CGRectMake(0, MAXY(self.remoteUserIdInputTextField) + 10, ViewWidth, 48)];
    self.scanButton.backgroundColor = UIColor.clearColor;
    self.scanButton.titleLabel.textColor = [UIColor whiteColor];
    self.scanButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [self.scanButton setImage:[UIImage imageNamed:@"livepusher_ic_qcode"] forState:UIControlStateNormal];
    [self addSubview:self.scanButton];
    
    self.startButton = [[UIButton alloc] initWithFrame:CGRectMake(0, MAXY(self.scanButton) + 10, ViewWidth, 48)];
    self.startButton.backgroundColor = UIColorFromRGB(0x2243EC);
    self.startButton.titleLabel.textColor = [UIColor whiteColor];
    self.startButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [self addSubview:self.startButton];
}

/// 从上往下，竖排布局
- (void)layoutViews:(NSArray *)views relateFirstView:(void (^)(UIView *firstView, MASConstraintMaker *make))block {
    UIView *preView = nil;
    for (UIView *view in views) {
        [view mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).offset(20);
            make.right.equalTo(self).offset(-20);
            make.height.mas_equalTo(@(48));
            if (!preView) {
                block(view, make);
            } else {
                make.top.equalTo(preView.mas_bottom).offset(10);
            }
        }];
        preView = view;
    }
}

- (void)configSubview {
    self.remoteUserIdInputTextField.hidden = self.isPush;
    self.generateButton.hidden = YES; /// room push 可以自动生成；player 不可自动生成
    self.userIdInputTextField.hidden = !self.isPush;
    self.scanButton.hidden = self.isPush;
    self.roomIdInputTextField.placeholder = @" 请输入房间号";
    self.userIdInputTextField.placeholder = @" 请输入用户Id";
    if (self.isPush) {
        [self layoutViews:@[
            self.roomIdInputTextField,
            self.userIdInputTextField,
            self.remoteUserIdInputTextField,
            self.startButton,
            self.cancelButton
        ] relateFirstView:^(UIView *firstView, MASConstraintMaker *make) {
            make.top.equalTo(self).offset(10);
        }];
        [self.startButton setTitle:@"开始推流" forState:UIControlStateNormal];
    } else {
        NSArray *views = @[
            self.roomIdInputTextField,
            self.remoteUserIdInputTextField,
            self.userIdInputTextField,
            self.startButton,
            self.cancelButton
        ];
        UIView *preView = nil;
        CGFloat scanBtnWidth = 48.0;
        for (UIView *view in views) {
            CGFloat rightOffset = ([view isEqual:self.roomIdInputTextField] || [view isEqual:self.remoteUserIdInputTextField])?(-10-scanBtnWidth-20):-20;
            [view mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self).offset(20);
                make.right.equalTo(self).offset(rightOffset);
                make.height.mas_equalTo(@(48));
                if (!preView) {
                    make.top.equalTo(self).offset(10);
                } else {
                    make.top.equalTo(preView.mas_bottom).offset(10);
                }
            }];
            preView = view;
        }
        [self.scanButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.roomIdInputTextField.mas_right).offset(10);
            make.right.equalTo(self).offset(-20);
            make.top.mas_equalTo(self.roomIdInputTextField.mas_top);
            make.bottom.mas_equalTo(self.remoteUserIdInputTextField.mas_bottom);
        }];
        self.remoteUserIdInputTextField.placeholder = @" 请输入远端用户Id";
        [self.startButton setTitle:@"开始拉流" forState:UIControlStateNormal];
    }
}
@end

@interface V2URLSettingTRTCView : V2URLSettingRoomView
@end
@implementation V2URLSettingTRTCView

- (void)configSubview {
    self.userIdInputTextField.hidden = YES;
    self.remoteUserIdInputTextField.hidden = YES;
    self.generateButton.hidden = YES;
    self.scanButton.hidden = self.isPush;
    self.roomIdInputTextField.placeholder = @" 请输入streamId";
    self.userIdInputTextField.placeholder = @" 请输入userId";
    if (self.isPush) {
        [self.startButton setTitle:@"开始推流" forState:UIControlStateNormal];
    } else {
        [self.startButton setTitle:@"开始拉流" forState:UIControlStateNormal];
    }
    if (self.isPush) {
        [self layoutViews:@[
            self.roomIdInputTextField,
            self.userIdInputTextField,
            self.remoteUserIdInputTextField,
            self.startButton,
            self.cancelButton
        ] relateFirstView:^(UIView *firstView, MASConstraintMaker *make) {
            make.top.equalTo(self).offset(10);
        }];
    } else {
        NSArray *views = @[
            self.roomIdInputTextField,
            self.userIdInputTextField,
            self.startButton,
            self.cancelButton
        ];
        UIView *preView = nil;
        CGFloat scanBtnWidth = 48.0;
        for (UIView *view in views) {
            CGFloat rightOffset = ([view isEqual:self.roomIdInputTextField] || [view isEqual:self.remoteUserIdInputTextField])?(-10-scanBtnWidth-20):-20;
            [view mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self).offset(20);
                make.right.equalTo(self).offset(rightOffset);
                make.height.mas_equalTo(@(48));
                if (!preView) {
                    make.top.equalTo(self).offset(10);
                } else {
                    make.top.equalTo(preView.mas_bottom).offset(10);
                }
            }];
            preView = view;
        }
        [self.scanButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.roomIdInputTextField.mas_right).offset(10);
            make.right.equalTo(self).offset(-20);
            make.top.mas_equalTo(self.roomIdInputTextField.mas_top);
            make.bottom.mas_equalTo(self.roomIdInputTextField.mas_bottom);
        }];
    }
}

@end

@interface V2URLSettingCDNView : UIView
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *secTitleLabel;
@property (nonatomic, strong) UIButton *generateButton;
@property (nonatomic, strong) UILabel *inputTitleLabel;
@property (nonatomic, strong) UITextField *inputTextField;
@property (nonatomic, strong) UIButton *scanButton;
@property (nonatomic, strong) UIButton *startButton;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, assign) BOOL isPush;
@end

@implementation V2URLSettingCDNView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self constructSubviews];
        [self configSubview];
    }
    return self;
}

- (void)constructSubviews {
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, ViewWidth, ViewHeight)];
    self.titleLabel.font = [UIFont systemFontOfSize:17];
    self.titleLabel.textColor = [UIColor whiteColor];
    self.titleLabel.numberOfLines = 2;
    [self addSubview:self.titleLabel];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(20);
        make.right.equalTo(self).offset(-20);
        make.top.equalTo(self);
        make.height.mas_equalTo(@(41));
    }];
    self.titleLabel.textAlignment = NSTextAlignmentLeft;
    
    self.secTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, MAXY(self.titleLabel), ViewWidth, 50)];
    self.secTitleLabel.font = [UIFont systemFontOfSize:14];
    self.secTitleLabel.textColor = UIColorFromRGB(0x6B82A8);
    self.secTitleLabel.textAlignment = NSTextAlignmentLeft;
    self.secTitleLabel.numberOfLines = 4;
    [self addSubview:self.secTitleLabel];
    [self.secTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(20);
        make.right.equalTo(self).offset(-20);
        make.top.equalTo(self.titleLabel.mas_bottom);
    }];
    
    self.generateButton = [[UIButton alloc] initWithFrame:CGRectMake(20, MAXY(self.secTitleLabel) + 10, ViewWidth, 48)];
    self.generateButton.backgroundColor = UIColorFromRGB(0x2243EC);
    self.generateButton.titleLabel.textColor = [UIColor whiteColor];
    self.generateButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [self.generateButton setTitle:@"自动生成推流地址" forState:UIControlStateNormal];
    [self addSubview:self.generateButton];
    [self.generateButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(20);
        make.right.equalTo(self).offset(-20);
        make.top.equalTo(self.secTitleLabel.mas_bottom).offset(10);
        make.height.mas_equalTo(@(48));
    }];
    
    self.inputTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, ViewWidth, 20)];
    self.inputTitleLabel.textColor = UIColorFromRGB(0x6B82A8);
    self.inputTitleLabel.font = [UIFont systemFontOfSize:16];
    self.inputTitleLabel.textAlignment = NSTextAlignmentLeft;
    [self addSubview:self.inputTitleLabel];
    [self.inputTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(20);
        make.right.equalTo(self).offset(-20);
        make.top.equalTo(self.generateButton.mas_bottom).offset(30);
        make.height.mas_equalTo(@(20));
    }];
    
    self.inputTextField = [[UITextField alloc] initWithFrame:CGRectMake(20, MAXY(self.inputTitleLabel), ViewWidth, 48)];
    self.inputTextField.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.inputTextField.layer.borderWidth = 1.0;
    self.inputTextField.font = [UIFont systemFontOfSize:16];
    [self addSubview:self.inputTextField];
    [self.inputTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(20);
        make.right.equalTo(self).offset(-10-48-20);
        make.top.equalTo(self.inputTitleLabel.mas_bottom).offset(10);
        make.height.mas_equalTo(@(48));
    }];
    
    self.scanButton = [[UIButton alloc] initWithFrame:CGRectMake(20, MAXY(self.inputTextField) + 10, ViewWidth, 48)];
    self.scanButton.backgroundColor = UIColor.clearColor;
    self.scanButton.titleLabel.textColor = [UIColor whiteColor];
    self.scanButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [self addSubview:self.scanButton];
    [self.scanButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.inputTextField.mas_right).offset(10);
        make.right.equalTo(self).offset(-20);
        make.top.equalTo(self.inputTextField.mas_top);
        make.height.mas_equalTo(@(48));
    }];
    [self.scanButton setImage:[UIImage imageNamed:@"livepusher_ic_qcode"] forState:UIControlStateNormal];
    
    self.startButton = [[UIButton alloc] initWithFrame:CGRectMake(0, MAXY(self.inputTextField) + 10, ViewWidth, 48)];
    self.startButton.backgroundColor = UIColorFromRGB(0x2243EC);
    self.startButton.titleLabel.textColor = [UIColor whiteColor];
    self.startButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [self addSubview:self.startButton];
    [self.startButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(20);
        make.right.equalTo(self).offset(-20);
        make.top.equalTo(self.inputTextField.mas_bottom).offset(10);
        make.height.mas_equalTo(@(48));
    }];
    
    self.cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(0, MAXY(self.startButton) + 10, ViewWidth, 48)];
    self.cancelButton.backgroundColor = UIColorFromRGB(0x2243EC);
    self.cancelButton.titleLabel.textColor = [UIColor whiteColor];
    self.cancelButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [self.cancelButton setTitle:@"取消" forState:UIControlStateNormal];
    [self addSubview:self.cancelButton];
    [self.cancelButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).offset(20);
        make.right.equalTo(self).offset(-20);
        make.top.equalTo(self.startButton.mas_bottom).offset(10);
        make.height.mas_equalTo(@(48));
    }];
}

- (void)configSubview {
    self.titleLabel.text = @"你需要a，b两台手机进行测试";
    self.secTitleLabel.text = @"① a手机生成推流地址录制\n② b手机输入拉流地址或扫码拉流并播放测试";
    self.generateButton.hidden = !self.isPush;
    if (self.isPush) {
        self.inputTitleLabel.text = @"我有推流地址";
        self.inputTextField.placeholder = @" 请扫码输入推流地址";
        [self.startButton setTitle:@"开始推流" forState:UIControlStateNormal];
    } else {
        self.inputTitleLabel.text = @"我有拉流地址";
        self.inputTextField.placeholder = @" 请扫码输入拉流地址";
        [self.startButton setTitle:@"开始拉流" forState:UIControlStateNormal];
    }
}

@end

@interface V2MainProtocolSelectViewController () <ScanQRDelegate, UIGestureRecognizerDelegate, V2MainProtocolSelectSegmentViewProtocol, UITextFieldDelegate>
@property (nonatomic, strong) V2URLSettingCDNView *cdnView;
@property (nonatomic, strong) V2URLSettingRoomView *roomView;
@property (nonatomic, strong) V2URLSettingTRTCView *trtcView;
@property (nonatomic, strong) V2MainProtocolSelectSegmentView *segmentView;
@property (nonatomic, strong) CAGradientLayer *layer;
@property (nonatomic, strong) UIImageView *loadingImageView;
@property (nonatomic, strong) NSDictionary *cdnPlayUrls;
@end

@implementation V2MainProtocolSelectViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithWhite:0.6 alpha:0.5];
    self.modalPresentationStyle = UIModalPresentationOverFullScreen;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap:)];
    tap.delegate = self;
    [self.view addGestureRecognizer:tap];
    
    [self constructSubviews];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self makeFirstSubTextViewResponder];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

- (void)constructSubviews {
    if (self.cdnView) {  /// 已经构造过，不再进来
        return;
    }
    //loading imageview
    float width = 34;
    float height = 34;
    float offsetX = (self.view.frame.size.width - width) / 2;
    float offsetY = (self.view.frame.size.height - height) / 2;
    NSMutableArray *array = [[NSMutableArray alloc] initWithObjects:[UIImage imageNamed:@"loading_image0.png"],[UIImage imageNamed:@"loading_image1.png"],[UIImage imageNamed:@"loading_image2.png"],[UIImage imageNamed:@"loading_image3.png"],[UIImage imageNamed:@"loading_image4.png"],[UIImage imageNamed:@"loading_image5.png"],[UIImage imageNamed:@"loading_image6.png"],[UIImage imageNamed:@"loading_image7.png"], nil];
    _loadingImageView = [[UIImageView alloc] initWithFrame:CGRectMake(offsetX, offsetY, width, height)];
    _loadingImageView.animationImages = array;
    _loadingImageView.animationDuration = 1;
    _loadingImageView.hidden = YES;
    [self.view addSubview:_loadingImageView];

    // UIlabel
    self.cdnView = [[V2URLSettingCDNView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, 0)];
    [self.cdnView.generateButton addTarget:self action:@selector(onGenerate:) forControlEvents:UIControlEventTouchUpInside];
    [self.cdnView.scanButton addTarget:self action:@selector(onScan:) forControlEvents:UIControlEventTouchUpInside];
    [self.cdnView.startButton addTarget:self action:@selector(onStart:) forControlEvents:UIControlEventTouchUpInside];
    [self.cdnView.cancelButton addTarget:self action:@selector(onCancelClick:) forControlEvents:UIControlEventTouchUpInside];

    self.roomView = [[V2URLSettingRoomView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, 0)];
    [self.roomView.scanButton addTarget:self action:@selector(onScan:) forControlEvents:UIControlEventTouchUpInside];
    [self.roomView.startButton addTarget:self action:@selector(onStart:) forControlEvents:UIControlEventTouchUpInside];
    [self.roomView.generateButton addTarget:self action:@selector(onRoomGenerate:) forControlEvents:UIControlEventTouchUpInside];
    [self.roomView.cancelButton addTarget:self action:@selector(onCancelClick:) forControlEvents:UIControlEventTouchUpInside];

    self.trtcView = [[V2URLSettingTRTCView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, 0)];
    [self.trtcView.scanButton addTarget:self action:@selector(onScan:) forControlEvents:UIControlEventTouchUpInside];
    [self.trtcView.startButton addTarget:self action:@selector(onStart:) forControlEvents:UIControlEventTouchUpInside];
    [self.trtcView.cancelButton addTarget:self action:@selector(onCancelClick:) forControlEvents:UIControlEventTouchUpInside];

    self.cdnView.isPush = self.roomView.isPush = self.trtcView.isPush = self.isPush;
    CGFloat contentH = 420.0;
    CGFloat topOffset = (ScreenHeight - contentH)/2;
    NSDictionary *titlesAndViews = @{
        @"CDN":self.cdnView,
//        @"ROOM":self.roomView,
        @"RTC":self.trtcView,
    };
    self.segmentView = [[V2MainProtocolSelectSegmentView alloc] initWithFrame:CGRectMake(20, topOffset, ScreenWidth-40, contentH) titlesAndViews:titlesAndViews titleOrder:@[@"RTC", @"CDN"]];
    self.segmentView.delegate = self;
    [self.view addSubview:self.segmentView];
    [self.segmentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.view);
        make.centerX.equalTo(self.view);
        make.width.mas_equalTo(self.view).offset(-40);
        make.height.mas_equalTo(@(contentH));
    }];
    // config UITextField
    for (UIView *view in titlesAndViews.allValues) {
        for (UITextField *textField in view.subviews) {
            if ([textField isKindOfClass:[UITextField class]]) {
                textField.textColor = [UIColor whiteColor];
                textField.keyboardType = UIKeyboardTypeNumberPad;
                textField.returnKeyType = UIReturnKeyDone;
                textField.backgroundColor = UIColor.clearColor;
                textField.delegate = self;
                textField.layer.borderWidth = 1.0;
                textField.layer.borderColor = UIColorFromRGB(0x065AE3).CGColor;
                textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:textField.placeholder?:@"" attributes:@{
                    NSForegroundColorAttributeName : UIColorFromRGB(0x607573),
                }];
                textField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 40)];
                textField.leftView.backgroundColor = [UIColor clearColor];
                textField.leftViewMode = UITextFieldViewModeAlways;
                textField.layer.cornerRadius = 4.0;
            } else if ([textField isKindOfClass:[UIButton class]]) {
                textField.layer.cornerRadius = 4.0;
                textField.clipsToBounds = YES;
            }
        }
    }
    self.cdnView.backgroundColor = self.roomView.backgroundColor = self.trtcView.backgroundColor = UIColor.clearColor;
    
    [self.cdnView configSubview];
    [self.roomView configSubview];
    [self.trtcView configSubview];
}

- (void)startLoadingAnimation
{
    if (_loadingImageView != nil) {
        [self.view bringSubviewToFront:_loadingImageView];
        _loadingImageView.hidden = NO;
        [_loadingImageView startAnimating];
    }
}

- (void)stopLoadingAnimation
{
    if (_loadingImageView != nil) {
        _loadingImageView.hidden = YES;
        [_loadingImageView stopAnimating];
    }
}

- (void)setIsPush:(BOOL)isPush {
    if (_isPush == isPush) {
        return;
    }
    _isPush = isPush;
    self.cdnView.isPush = self.roomView.isPush = self.trtcView.isPush = isPush;
    [self.cdnView configSubview];
    [self.roomView configSubview];
    [self.trtcView configSubview];
    if (!self.isPush) {
        self.roomView.userIdInputTextField.text = [self defaultUserId];
    } else {
        self.roomView.userIdInputTextField.text = @"";
    }
}

- (void)onTap:(UITapGestureRecognizer *)tap {
    CGPoint point = [tap locationInView:self.view];
    UITextField *editTextField = nil;
    for (UIView *view in @[self.cdnView, self.trtcView, self.roomView]) {
        for (UITextField *textField in view.subviews) {
            if (textField.isEditing) {
                editTextField = textField;
                break;
            }
        }
    }
    if (editTextField && ![tap.view isEqual:editTextField]) {
        [editTextField resignFirstResponder];
        return;
    }
    if (CGRectContainsPoint(self.segmentView.frame, point)) {
        return;
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (IBAction)onGenerate:(UIButton *)sender {
    /// cdn 推流地址
    sender.enabled = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        sender.enabled = YES;
    });
    [self startLoadingAnimation];
    __weak __typeof(self) weakSelf = self;
    [self autoCreateUrl:^(NSError *error, NSString *pushUrl, NSDictionary *playUrls) {
        __strong __typeof(self) strongSelf = weakSelf;
        [strongSelf stopLoadingAnimation];
        if (error) {
            [strongSelf showText:@"创建推流地址失败" withDetailText:nil];
        } else {
            strongSelf.cdnPlayUrls = playUrls;
            strongSelf.cdnView.inputTextField.text = pushUrl;
        }
    }];
}

- (IBAction)onScan:(UIButton *)sender {
    NSLog(@"on click: #onScan#");
    V2QRScanViewController *vc = [[V2QRScanViewController alloc] init];
    vc.delegate = self;
    vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [self presentViewController:vc animated:YES completion:nil];
}

- (IBAction)onStart:(UIButton *)sender {
    NSLog(@"on click: #onStart#");
    UIView *selectedView = self.segmentView.selectedView;
    if ([selectedView isEqual:self.cdnView]) {
        if ([V2LiveUtils isRTMPUrl:self.cdnView.inputTextField.text]) {
            [self callBackOnStart:self.cdnView.inputTextField.text playUrls:self.cdnPlayUrls];
        } else {
            [self showText:@"请输入合法的 CDN 地址" withDetailText:nil];
        }
    } else if ([selectedView isEqual:self.roomView]) {
        if (self.isPush) {
            if (self.roomView.roomIdInputTextField.text.length > 0 && self.roomView.userIdInputTextField.text.length > 0) {
                NSString *url = [self generatePushUrl:self.roomView.roomIdInputTextField.text userId:self.roomView.userIdInputTextField.text isTRTC:NO];
                [self callBackOnStart:url playUrls:nil];
            } else {
                [self showText:@"请输入 roomId 和 remoteUserId" withDetailText:nil];
            }
        } else {
            if (self.roomView.roomIdInputTextField.text.length > 0 && self.roomView.remoteUserIdInputTextField.text.length > 0) {
                self.roomView.userIdInputTextField.text = [self defaultUserId];//[self randomId];
               NSString *url = [self generatePlayUrl:self.roomView.roomIdInputTextField.text
                                              userId:self.roomView.userIdInputTextField.text
                                        remoteUserId:self.roomView.remoteUserIdInputTextField.text
                                              isTRTC:NO rtcPlay:self.roomView.cancelButton.selected];
               [self callBackOnStart:url playUrls:nil];
            } else {
                [self showText:@"请输入 roomId 和 remoteUserId" withDetailText:nil];
            }
        }
    } else if ([selectedView isEqual:self.trtcView]) {
        if (self.trtcView.roomIdInputTextField.text.length > 0) {
            if (self.isPush) {
                if (self.trtcView.roomIdInputTextField.text.length > 0) {
                    NSString *url = [self generatePushUrl:self.trtcView.roomIdInputTextField.text userId:[self defaultUserId] isTRTC:YES];
                    [self callBackOnStart:url playUrls:nil];
                }
            } else {
                if (self.trtcView.roomIdInputTextField.text.length > 0) {
                    NSString *url = [self generatePlayUrl:self.trtcView.roomIdInputTextField.text
                                                   userId:[self defaultUserId]
                                             remoteUserId:nil
                                                   isTRTC:YES
                                                  rtcPlay:self.trtcView.cancelButton.selected];
                    [self callBackOnStart:url playUrls:nil];
                }
            }
        } else {
            [self showText:@"请输入 streamId" withDetailText:nil];
        }
    } else {
        NSLog(@"selectedView not found.");
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onRoomGenerate:(UIButton *)sender {
    self.roomView.roomIdInputTextField.text = [self defaultRoomId];
    self.roomView.userIdInputTextField.text = [self defaultUserId];
    self.roomView.remoteUserIdInputTextField.text = [self defaultRemoteUserId];
}

- (IBAction)onCancelClick:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -- private
- (void)makeFirstSubTextViewResponder{
    dispatch_async(dispatch_get_main_queue(), ^{
        for (UITextField *text in self.segmentView.selectedView.subviews) {
            if ([text isKindOfClass:[UITextField class]]) {
                [text becomeFirstResponder];
                break;
            }
        }
    });
}

#pragma mark -- textField
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark --  V2MainProtocolSelectSegmentViewProtocol
- (void)onSegmentView:(V2MainProtocolSelectSegmentView *)segmentView selectedIndex:(NSInteger)index {
    [self makeFirstSubTextViewResponder];
}

#pragma mark - ScanQRDelegate
- (void)onScanResult:(NSString *)originUrl {
    V2Log(@"originUrl:%@", originUrl);
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.isPush && ![self.segmentView.selectedView isEqual:self.cdnView]) {
            /// 非 cdn 扫码推流
            [self showText:@"当前不支持该功能" withDetailText:originUrl];
        } else if (self.isPush && [self.segmentView.selectedView isEqual:self.cdnView]) {
            /// cdn 扫码推流
            self.cdnView.inputTextField.text = originUrl;
            [self callBackOnStart:originUrl playUrls:@{}];
        } else if (!self.isPush) {
            /// 播放
            if ([originUrl hasPrefix:@"trtc://"] || [originUrl hasPrefix:@"room://"]) {
                V2URLSettingRoomView *view = (V2URLSettingRoomView *)self.segmentView.selectedView;
                BOOL isRtcPlay = NO;
                if ([view isKindOfClass:[V2URLSettingRoomView class]]) {
                    isRtcPlay = view.cancelButton.selected;
                }
                NSString *playUrl = [self generatePlayUrlByAppendUserInfo:originUrl isRtc:isRtcPlay];
                if (playUrl) {
                    [self callBackOnStart:playUrl playUrls:nil];
                }
            } else if ([V2LiveUtils isRTMPUrl:originUrl]) {
                [self callBackOnStart:originUrl playUrls:@{}];
            } else {
                [self showText:@"URL 地址无效" withDetailText:nil];
            }
        }
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    });
}

#pragma mark -- callBack
- (void)callBackOnStart:(NSString *)url playUrls:(NSDictionary *)playUrls {
    if (self.onStart) {
        self.onStart(self, url, playUrls, self.isPush);
    }
}


#pragma mark -- 生成 Room 地址
- (NSString *)generatePlayUrlByAppendUserInfo:(NSString *)originUrl isRtc:(BOOL)isRtc {
    V2Log(@"originUrl: %@", originUrl);

    if ([V2LiveUtils isTRTCUrl:originUrl] && [originUrl containsString:@"play"]) {
        NSMutableString *rtUrl = [NSMutableString stringWithString:originUrl];
        if (isRtc) {
            [rtUrl replaceOccurrencesOfString:@"play" withString:@"rtcplay" options:NSCaseInsensitiveSearch range:NSMakeRange(0, rtUrl.length)];
        }
        if (![rtUrl hasSuffix:@"?"]) {
            [rtUrl appendString:@"?"];
        }
        NSString *userId = [self randomId];
        NSString *userSig = [GenerateTestUserSig genTestUserSig:userId];
        //[GenerateTestUserSig genTestUserSig:userId sdkAppId:_SDKAppID secretKey:_SECRETKEY];
        [rtUrl appendFormat:@"sdkappid=%d&userid=%@&usersig=%@&appscene=live", SDKAPPID, userId, userSig];
        return rtUrl;
    } else if ([originUrl hasPrefix:@"room://"] && [originUrl containsString:@"remoteuserid"] && [originUrl containsString:@"strroomid"]) {
        NSMutableString *rtUrl = [NSMutableString stringWithString:originUrl];
        NSString *userId = [self randomId];
        NSString *userSig = [GenerateTestUserSig genTestUserSig:userId];
        //NSString *userSig = [GenerateTestUserSig genTestUserSig:userId sdkAppId:_SDKAppID secretKey:_SECRETKEY];
        [rtUrl appendFormat:@"&sdkappid=%d&userid=%@&usersig=%@&appscene=live%@", SDKAPPID, userId, userSig, isRtc?@"&rtcplay=1":@""];
        return rtUrl;
    } else {
        [self showText:@"URL 地址无效" withDetailText:originUrl];
        return nil;
    }
}

#define kLastTRTCRoomId         @"kLastTRTCRoomId"
#define kLastTRTCUserId         @"kLastTRTCUserId"
#define kLastTRTCRemoteUserId   @"kLastTRTCRemoteUserId"

- (NSString *)generatePlayUrl:(NSString *)roomId userId:(NSString *)userId remoteUserId:(NSString *)remoteUserId {
    return [self generatePlayUrl:roomId userId:userId remoteUserId:remoteUserId isTRTC:NO rtcPlay:NO];
}

- (NSString *)generatePlayUrl:(NSString *)roomId userId:(NSString *)userId remoteUserId:(NSString *)remoteUserId isTRTC:(BOOL)isTRTC rtcPlay:(BOOL)rtcPlay {
    if ([roomId length] == 0 || [userId length] == 0) {
        return nil;
    } else if (!isTRTC && remoteUserId.length == 0) {
        return nil;
    }
    [[NSUserDefaults standardUserDefaults] setObject:userId forKey:kLastTRTCUserId];
    [[NSUserDefaults standardUserDefaults] setObject:roomId forKey:kLastTRTCRoomId];
    if (remoteUserId) {
        [[NSUserDefaults standardUserDefaults] setObject:remoteUserId forKey:kLastTRTCRemoteUserId];
    }
    long long _SDKAppID = SDKAPPID;
    NSString *userSig = [GenerateTestUserSig genTestUserSig:userId];
    //[GenerateTestUserSig genTestUserSig:userId sdkAppId:_SDKAppID secretKey:_SECRETKEY];
    if (isTRTC) {
        if (rtcPlay) {
            return [NSString stringWithFormat:@"trtc://cloud.tencent.com/rtcplay/%@?sdkappid=%d&userid=%@&usersig=%@&appscene=live",
                    roomId, _SDKAppID, userId, userSig];
        } else {
            return [NSString stringWithFormat:@"trtc://cloud.tencent.com/play/%@?sdkappid=%d&userid=%@&usersig=%@&appscene=live",
                    roomId, _SDKAppID, userId, userSig];
        }
    } else {
        if (rtcPlay) {
            return [NSString stringWithFormat:@"room://cloud.tencent.com/rtc?sdkappid=%d&strroomid=%@&userid=%@&remoteuserid=%@&usersig=%@&appscene=live&rtcplay=1",
                    _SDKAppID, roomId, userId, remoteUserId, userSig];
        } else {
            return [NSString stringWithFormat:@"room://cloud.tencent.com/rtc?sdkappid=%d&strroomid=%@&userid=%@&remoteuserid=%@&usersig=%@&appscene=live",
                    _SDKAppID, roomId, userId, remoteUserId, userSig];
        }
    }
}

- (NSString *)generatePushUrl:(NSString *)roomId userId:(NSString *)userId {
    return [self generatePushUrl:roomId userId:userId isTRTC:NO];
}

- (NSString *)generatePushUrl:(NSString *)roomId userId:(NSString *)userId isTRTC:(BOOL)isTRTC {
    if (!roomId || !userId) {
        return nil;
    }
    [[NSUserDefaults standardUserDefaults] setObject:userId forKey:kLastTRTCUserId];
    [[NSUserDefaults standardUserDefaults] setObject:roomId forKey:kLastTRTCRoomId];
    long long _SDKAppID = SDKAPPID;
    NSString *userSig = [GenerateTestUserSig genTestUserSig:userId];
    if (isTRTC) {
        return [NSString stringWithFormat:@"trtc://cloud.tencent.com/push/%@?sdkappid=%d&userid=%@&usersig=%@&appscene=live",
                roomId, _SDKAppID, userId, userSig];
    } else {
        return [NSString stringWithFormat:@"room://cloud.tencent.com/rtc?sdkappid=%d&strroomid=%@&userid=%@&usersig=%@&appscene=live",
                _SDKAppID, roomId, userId, userSig];
    }
}

- (NSString *)defaultRoomId {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kLastTRTCRoomId] ?: [self randomId];
}

- (NSString *)defaultUserId {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kLastTRTCUserId] ?: [self randomId];
}

- (NSString *)defaultRemoteUserId {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kLastTRTCRemoteUserId] ?: [self randomId];
}

- (NSString *)randomId {
    return [NSString stringWithFormat:@"%@", @(arc4random() % 100000)];
}


- (void)showText:(NSString *)text withDetailText:(NSString *)detail {
    MBProgressHUD *hud = [MBProgressHUD HUDForView:self.view.window];
    if (hud == nil) {
        hud = [MBProgressHUD showHUDAddedTo:self.view.window animated:YES];
    }
    hud.mode = MBProgressHUDModeText;
    hud.label.text = text;
    hud.detailsLabel.text = detail;
    [hud showAnimated:YES];
    [hud hideAnimated:YES afterDelay:1];
}

#pragma mark -- net
//错误码
#define kError_InvalidParam                  -10001
#define kError_ConvertJsonFailed             -10002
#define kError_HttpError                     -10003
- (void)autoCreateUrl:(void(^)(NSError *error, NSString *pushUrl, NSDictionary *playUrls))complete {
    [self.class asyncSendHttpRequest:@"get_test_pushurl" httpServerAddr:@"https://lvb.qcloud.com/weapp/utils" HTTPMethod:@"GET" param:nil handler:^(int result, NSDictionary *resultDict) {
        if (complete) {
            NSError *error = nil;
            if (result != 0 || resultDict == nil) {
                error = [NSError errorWithDomain:@"com.net.error.lppush" code:result userInfo:resultDict];
            }
            NSDictionary *playUrls = resultDict;
            //@"url_play_acc" @"url_play_flv" @"url_play_hls" @"url_play_rtmp"
            complete(error, playUrls[@"url_push"], playUrls);
        }
    }];
}

//// callback
//typedef void(^OnNetCompleteBlock)(NSDictionary * _Nullable resultDict, NSError * _Nullable error);
//+ (void)getInterface:(NSString * _Nonnull)intefaceName complete:(OnNetCompleteBlock _Nullable)complete {
//    [self asyncSendHttpRequest:@"get_test_pushurl" httpServerAddr:@"https://lvb.qcloud.com/weapp/utils" HTTPMethod:@"GET" param:nil handler:^(int result, NSDictionary *resultDict) {
//        if (complete) {
//            NSError *error = nil;
//            if (result != 0 || resultDict == nil) {
//                error = [NSError errorWithDomain:@"com.net.error.lppush" code:result userInfo:resultDict];
//            }
//            complete(resultDict, error);
//        }
//    }];
//}

+ (void)asyncSendHttpRequest:(NSString*)request
              httpServerAddr:(NSString *)httpServerAddr
                  HTTPMethod:(NSString *)HTTPMethod
                       param:(NSDictionary *)param
                     handler:(void (^)(int result, NSDictionary* resultDict))handler {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSString* strUrl = @"";
        strUrl = [NSString stringWithFormat:@"%@/%@", httpServerAddr, request];
        NSURL *URL = [NSURL URLWithString:strUrl];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
        
        [request setHTTPMethod:HTTPMethod];
        [request setValue:@"application/json; charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
        [request setTimeoutInterval:30];
        for (NSString *key in param.allKeys) {
            [request setValue:param[key] forHTTPHeaderField:key];
        }
        
        NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error != nil)
            {
                NSLog(@"internalSendRequest failed，NSURLSessionDataTask return error code:%ld, des:%@", [error code], [error description]);
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler(kError_HttpError, nil);
                });
            }
            else
            {
                NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                NSDictionary* resultDict = [self jsonData2Dictionary:responseString];
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler(0, resultDict);
                });
            }
        }];
        
        [task resume];
    });
}

+ (NSDictionary *)jsonData2Dictionary:(NSString *)jsonData
{
    if (jsonData == nil) {
        return nil;
    }
    NSData *data = [jsonData dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err = nil;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&err];
    if (err) {
        NSLog(@"Json parse failed: %@", jsonData);
        return nil;
    }
    return dic;
}


@end
