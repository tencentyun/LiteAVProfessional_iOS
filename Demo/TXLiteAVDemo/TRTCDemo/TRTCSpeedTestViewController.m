//
//  TRTCSpeedTestViewController.m
//  TXLiteAVDemo
//
//  Created by bluedang on 2021/6/10.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "TRTCSpeedTestViewController.h"

#import "AppLocalized.h"
#import "ColorMacro.h"
#import "Masonry.h"
#import "TRTCCloud.h"
#import "TRTCCloudManager.h"
#import "UIButton+TRTC.h"
#import "UITextField+TRTC.h"

@interface                                TRTCSpeedTestViewController () <UITextFieldDelegate>
@property(strong, nonatomic) UILabel *    userIdLabel;
@property(strong, nonatomic) UILabel *    speedTestLabel;
@property(strong, nonatomic) UITextField *userIdTextField;
@property(strong, nonatomic) UITextView * speedResultTextView;
@property(strong, nonatomic) UIButton *   startButton;

@property(strong, nonatomic) TRTCCloudManager *cloudManager;
@property(assign, nonatomic) BOOL              isSpeedTesting;
@end

@implementation TRTCSpeedTestViewController

- (TRTCCloudManager *)cloudManager {
    if (!_cloudManager) {
        TRTCParams *params = [[TRTCParams alloc] init];
        _cloudManager = [[TRTCCloudManager alloc] initWithParams:params scene:TRTCAppSceneLIVE];
    }
    return _cloudManager;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = TRTCLocalize(@"Demo.TRTC.Live.trtcSpeedTest");
    [self setupBackgroudColor];
    [self setupUI];
    [self setupRandomUserId];
    self.isSpeedTesting = false;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    [self layouViews];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}

- (void)didMoveToParentViewController:(UIViewController *)parent {
    if (![parent isEqual:self.parentViewController]) {
        if (_isSpeedTesting) {
            self.isSpeedTesting = false;
            [_cloudManager stopSpeedTest];
        }
    }
}

- (void)setupBackgroudColor {
    UIColor *startColor = [UIColor colorWithRed:19.0 / 255.0 green:41.0 / 255.0 blue:75.0 / 255.0 alpha:1];
    UIColor *endColor   = [UIColor colorWithRed:5.0 / 255.0 green:12.0 / 255.0 blue:23.0 / 255.0 alpha:1];

    NSArray *colors = @[ (id)startColor.CGColor, (id)endColor.CGColor ];

    CAGradientLayer *layer = [CAGradientLayer layer];
    layer.colors           = colors;
    layer.startPoint       = CGPointMake(0, 0);
    layer.endPoint         = CGPointMake(1, 1);
    layer.frame            = self.view.bounds;

    [self.view.layer insertSublayer:layer atIndex:0];
}

- (void)setupUI {
    _userIdLabel         = [[UILabel alloc] initWithFrame:CGRectZero];
    _speedTestLabel      = [[UILabel alloc] initWithFrame:CGRectZero];
    _userIdTextField     = [UITextField trtc_textFieldWithDelegate:self];
    _speedResultTextView = [[UITextView alloc] initWithFrame:CGRectZero];
    [_speedResultTextView setEditable:false];
    [_speedResultTextView setSelectable:false];
    _speedResultTextView.backgroundColor = UIColorFromRGB(0x0D2C5B);
    _speedResultTextView.textColor       = UIColorFromRGB(0x939393);
    _speedResultTextView.font            = [UIFont systemFontOfSize:15];
    _startButton                         = [UIButton trtc_cellButtonWithTitle:TRTCLocalize(@"Demo.TRTC.startSpeedTest")];

    _userIdLabel.text = TRTCLocalize(@"Demo.TRTC.speedTestUserId");
    [_userIdLabel setTextColor:[UIColor whiteColor]];
    _speedTestLabel.text = TRTCLocalize(@"Demo.TRTC.speedTestResult");
    [_speedTestLabel setTextColor:[UIColor whiteColor]];
    [_startButton setTitle:TRTCLocalize(@"Demo.TRTC.startSpeedTest") forState:UIControlStateNormal];
    [_startButton addTarget:self action:@selector(onStartButtonClick:) forControlEvents:UIControlEventTouchUpInside];

    _userIdLabel.adjustsFontSizeToFitWidth    = true;
    _speedTestLabel.adjustsFontSizeToFitWidth = true;
    _startButton.adjustsImageWhenHighlighted  = true;

    //    _userIdTextField.keyboardType = UIKeyboardTypeNumberPad;
    _userIdTextField.delegate = self;

    [self.view addSubview:_userIdLabel];
    [self.view addSubview:_userIdTextField];
    [self.view addSubview:_speedTestLabel];
    [self.view addSubview:_speedResultTextView];
    [self.view addSubview:_startButton];
}

- (void)layouViews {
    [self.userIdLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        UInt32 y = self.navigationController.navigationBar.frame.size.height + self.navigationController.navigationBar.frame.origin.y;
        make.top.mas_equalTo(@(y + 10));
        make.leading.mas_equalTo(40);
        make.height.mas_equalTo(29);
        make.trailing.mas_equalTo(-40);
    }];

    [self.userIdTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.userIdLabel.mas_bottom).offset(10);
        make.height.mas_equalTo(40);
        make.trailing.equalTo(self.userIdLabel.mas_trailing);
        make.leading.equalTo(self.userIdLabel.mas_leading);
    }];

    [self.speedTestLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.userIdTextField.mas_bottom).offset(10);
        make.height.mas_equalTo(29);
        make.trailing.equalTo(self.userIdLabel.mas_trailing);
        make.leading.equalTo(self.userIdLabel.mas_leading);
    }];

    [self.startButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(50);
        make.trailing.equalTo(self.userIdLabel.mas_trailing);
        make.leading.equalTo(self.userIdLabel.mas_leading);
        make.bottom.equalTo(self.view.mas_bottom).offset(-50);
    }];

    [self.speedResultTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.speedTestLabel.mas_bottom).offset(10);
        make.trailing.equalTo(self.userIdLabel.mas_trailing);
        make.leading.equalTo(self.userIdLabel.mas_leading);
        make.bottom.equalTo(self.startButton.mas_top).offset(-20);
    }];
}

- (void)setupRandomUserId {
    _userIdTextField.attributedPlaceholder = [UITextField trtc_textFieldPlaceHolderFor:[@((UInt32)(CACurrentMediaTime() * 10)) stringValue]];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:true];
}

- (void)beginSpeedTest {
    _isSpeedTesting = true;

    __weak typeof(self) weakSelf = self;
    NSString *          userId   = _userIdTextField.text.length == 0 ? _userIdTextField.placeholder : _userIdTextField.text;

    [self.cloudManager startSpeedTest:userId
                           completion:^(TRTCSpeedTestResult *_Nonnull result, NSInteger completedCount, NSInteger totalCount) {
                               __strong typeof(weakSelf) strongSelf = weakSelf;
                               NSString *                printResult =
                                   [[NSString alloc] initWithFormat:
                                                         @"current server：%ld, total server: %ld\n"
                                                          "current ip: %@, quality: %ld, upLostRate: %.2f%%\n"
                                                          "downLostRate: %.2f%%, rtt: %u\n\n",
                                                         (long)completedCount, (long)totalCount, result.ip, result.quality, result.upLostRate * 100, result.downLostRate * 100, result.rtt];

                               strongSelf.speedResultTextView.text = [strongSelf.speedResultTextView.text stringByAppendingString:printResult];

                               if (completedCount == totalCount) {
                                   self.isSpeedTesting = false;
                                   [self.startButton setTitle:TRTCLocalize(@"Demo.TRTC.completedTest") forState:UIControlStateNormal];
                                   return;
                               }

                               float     percent    = completedCount / (float)totalCount;
                               NSString *strPercent = [[NSString alloc] initWithFormat:@"%.2f %%", percent * 100];
                               [strongSelf.startButton setTitle:strPercent forState:UIControlStateNormal];
                           }];
}

- (void)onStartButtonClick:(UIButton *)sender {
    if (_isSpeedTesting) {
        return;
    }

    if ([_startButton isSelected]) {
        [_startButton setTitle:TRTCLocalize(@"Demo.TRTC.startSpeedTest") forState:UIControlStateNormal];
        _speedResultTextView.text = @"";
    } else {
        [self beginSpeedTest];
        self.startButton.highlighted = true;
        [_startButton setTitle:@"0 %" forState:UIControlStateNormal];
    }

    _startButton.selected = !_startButton.selected;
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    int maxCount = 40;
    return maxCount >= (textField.text.length + string.length);
}

@end
