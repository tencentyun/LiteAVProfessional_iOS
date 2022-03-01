//
//  CameraStartPushViewController.m
//  TXLiteAVDemo
//
//  Created by adams on 2021/7/20.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "CameraStartPushViewController.h"

#import <MBProgressHUD.h>
#import <Masonry.h>

#import "AppLocalized.h"
#import "CameraPushViewController.h"
#import "CameraStartPushAlertView.h"
#import "ColorMacro.h"
#import "GenerateTestUserSig.h"
#import "ScanQRController.h"
#import "TCHttpUtil.h"

@class TCRTCUtil;
@interface CameraStartPushViewController () <UITextFieldDelegate, ScanQRDelegate> {
    __block UILabel *_lastLabel;
}
@property(nonatomic, strong) UIView *  navigationBar;
@property(nonatomic, strong) UILabel * navigationTitleLabel;
@property(nonatomic, strong) UIButton *navigationBackBtn;
@property(nonatomic, strong) UIButton *navigationHelpBtn;

@property(nonatomic, strong) UIButton *   generateStreamBtn;
@property(nonatomic, strong) UILabel *    inputStreamAddressLabel;
@property(nonatomic, strong) UITextField *inputStreamTextField;
@property(nonatomic, strong) UIButton *   scanBtn;
@property(nonatomic, strong) UIButton *   pushStreamBtn;

@property(nonatomic, strong) CameraStartPushAlertView *alertView;

@end

@implementation CameraStartPushViewController

#pragma mark - lazy property
- (UIView *)navigationBar {
    if (!_navigationBar) {
        _navigationBar                 = [[UIView alloc] initWithFrame:CGRectZero];
        _navigationBar.backgroundColor = UIColor.clearColor;
    }
    return _navigationBar;
}

- (UILabel *)navigationTitleLabel {
    if (!_navigationTitleLabel) {
        _navigationTitleLabel                           = [[UILabel alloc] initWithFrame:CGRectZero];
        _navigationTitleLabel.adjustsFontSizeToFitWidth = true;
        _navigationTitleLabel.textAlignment             = NSTextAlignmentCenter;
        _navigationTitleLabel.font                      = [UIFont fontWithName:@"PingFangSC-Semibold" size:21];
        _navigationTitleLabel.text                      = V2Localize(@"MLVB.MainMenu.pushcameraTitle");
        _navigationTitleLabel.textColor                 = UIColor.whiteColor;
    }
    return _navigationTitleLabel;
}

- (UIButton *)navigationBackBtn {
    if (!_navigationBackBtn) {
        _navigationBackBtn = [[UIButton alloc] initWithFrame:CGRectZero];
        [_navigationBackBtn setImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
        [_navigationBackBtn addTarget:self action:@selector(backBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _navigationBackBtn;
}

- (UIButton *)navigationHelpBtn {
    if (!_navigationHelpBtn) {
        _navigationHelpBtn = [[UIButton alloc] initWithFrame:CGRectZero];
        [_navigationHelpBtn setImage:[UIImage imageNamed:@"help_small"] forState:UIControlStateNormal];
        [_navigationHelpBtn addTarget:self action:@selector(helpBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _navigationHelpBtn;
}

- (UIButton *)generateStreamBtn {
    if (!_generateStreamBtn) {
        _generateStreamBtn                 = [[UIButton alloc] initWithFrame:CGRectZero];
        _generateStreamBtn.backgroundColor = UIColorFromRGB(0x0062E3);
        [_generateStreamBtn setTitle:V2Localize(@"MLVB.CameraStartPush.Automatically") forState:UIControlStateNormal];
        [_generateStreamBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        _generateStreamBtn.layer.cornerRadius                   = 2;
        _generateStreamBtn.titleLabel.adjustsFontSizeToFitWidth = true;
        _generateStreamBtn.titleLabel.font                      = [UIFont fontWithName:@"PingFangSC-Semibold" size:18];
        [_generateStreamBtn addTarget:self action:@selector(generateStreamBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _generateStreamBtn;
}

- (UILabel *)inputStreamAddressLabel {
    if (!_inputStreamAddressLabel) {
        _inputStreamAddressLabel           = [[UILabel alloc] initWithFrame:CGRectZero];
        _inputStreamAddressLabel.text      = V2Localize(@"MLVB.CameraStartPush.Enter");
        _inputStreamAddressLabel.font      = [UIFont fontWithName:@"PingFangSC-Semibold" size:16];
        _inputStreamAddressLabel.textColor = UIColor.whiteColor;
    }
    return _inputStreamAddressLabel;
}

- (UITextField *)inputStreamTextField {
    if (!_inputStreamTextField) {
        _inputStreamTextField = [[UITextField alloc] initWithFrame:CGRectZero];
        NSAttributedString *placeholder =
            [[NSAttributedString alloc] initWithString:V2Localize(@"MLVB.CameraStartPush.Pleaseenter")
                                            attributes:@{NSForegroundColorAttributeName : UIColorFromRGB(0x4F75BD), NSFontAttributeName : [UIFont fontWithName:@"PingFangSC-Regular" size:14]}];
        _inputStreamTextField.attributedPlaceholder = placeholder;
        _inputStreamTextField.layer.borderColor     = UIColorFromRGB(0x0B73E2).CGColor;
        _inputStreamTextField.layer.borderWidth     = 1;
        _inputStreamTextField.delegate              = self;
        _inputStreamTextField.textColor             = UIColor.whiteColor;
        UIView *paddingView                         = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 46)];
        _inputStreamTextField.leftView              = paddingView;
        _inputStreamTextField.leftViewMode          = UITextFieldViewModeAlways;
    }
    return _inputStreamTextField;
}

- (UIButton *)scanBtn {
    if (!_scanBtn) {
        _scanBtn                 = [[UIButton alloc] initWithFrame:CGRectZero];
        _scanBtn.backgroundColor = UIColorFromRGB(0x0062E3);
        [_scanBtn setImage:[UIImage imageNamed:@"scan"] forState:UIControlStateNormal];
        [_scanBtn setImage:[UIImage imageNamed:@"scan"] forState:UIControlStateHighlighted];
        _scanBtn.layer.cornerRadius = 2;
        [_scanBtn addTarget:self action:@selector(scanBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _scanBtn;
}

- (UIButton *)pushStreamBtn {
    if (!_pushStreamBtn) {
        _pushStreamBtn                 = [[UIButton alloc] initWithFrame:CGRectZero];
        _pushStreamBtn.backgroundColor = UIColorFromRGB(0x0062E3);
        [_pushStreamBtn setTitle:V2Localize(@"MLVB.CameraStartPush.Startstreaming") forState:UIControlStateNormal];
        [_pushStreamBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        _pushStreamBtn.layer.cornerRadius = 2;
        [_pushStreamBtn addTarget:self action:@selector(pushBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        _pushStreamBtn.titleLabel.adjustsFontSizeToFitWidth = true;
    }
    return _pushStreamBtn;
}

- (CameraStartPushAlertView *)alertView {
    if (!_alertView) {
        __weak typeof(self) weakSelf = self;
        _alertView                   = [[CameraStartPushAlertView alloc] initWithFrame:CGRectZero
                                                    generateCallback:^(PushType pushType) {
                                                        __strong typeof(weakSelf) strongSelf = weakSelf;
                                                        switch (pushType) {
                                                            case RTMP:
                                                                [strongSelf generateRTMPURL:pushType];
                                                                break;
                                                            case RTC:
                                                                [strongSelf generateRTCURL:pushType];
                                                                break;
                                                            default:
                                                                break;
                                                        }
                                                    }];
        _alertView.alpha             = 0;
    }
    return _alertView;
}

#pragma mark - life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupView];
}

- (void)dealloc {
    NSLog(@"%@ dealloc", NSStringFromClass(self.class));
}

#pragma mark - initView
- (void)setupView {
    // 背景色
    self.view.backgroundColor = [UIColor whiteColor];
    NSArray *colors           = @[
        (__bridge id)[UIColor colorWithRed:19.0 / 255.0 green:41.0 / 255.0 blue:75.0 / 255.0 alpha:1].CGColor,
        (__bridge id)[UIColor colorWithRed:5.0 / 255.0 green:12.0 / 255.0 blue:23.0 / 255.0 alpha:1].CGColor
    ];
    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.colors           = colors;
    gradientLayer.startPoint       = CGPointMake(0, 0);
    gradientLayer.endPoint         = CGPointMake(1, 1);
    gradientLayer.frame            = self.view.bounds;
    [self.view.layer insertSublayer:gradientLayer atIndex:0];

    [self setupNaivgationBar];
    [self setupDescription];
    [self setupStreamView];
    [self setupAlertView];
}

- (void)setupNaivgationBar {
    [self.view addSubview:self.navigationBar];
    [self.navigationBar addSubview:self.navigationBackBtn];
    [self.navigationBar addSubview:self.navigationTitleLabel];
    [self.navigationBar addSubview:self.navigationHelpBtn];

    [self.navigationBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view.mas_left);
        make.right.equalTo(self.view.mas_right);
        if (@available(iOS 11.0, *)) {
            make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        } else {
            make.top.equalTo(self.view.mas_top).offset(20);
        }
        make.height.mas_equalTo(44);
    }];

    [self.navigationBackBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.navigationBar.mas_left);
        make.centerY.equalTo(self.navigationBar.mas_centerY);
        make.size.mas_equalTo(CGSizeMake(44, 44));
    }];

    [self.navigationTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.navigationBar.mas_centerX);
        make.centerY.equalTo(self.navigationBar.mas_centerY);
        make.width.equalTo(self.navigationBar.mas_width).multipliedBy(0.6);
    }];

    [self.navigationHelpBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.navigationBar.mas_right).offset(-11);
        make.centerY.equalTo(self.navigationBar.mas_centerY);
        make.size.mas_equalTo(CGSizeMake(23, 22));
    }];
}

- (void)setupDescription {
    UILabel *descriptionLabel  = [[UILabel alloc] initWithFrame:CGRectZero];
    descriptionLabel.font      = [UIFont fontWithName:@"PingFangSC-Semibold" size:16];
    descriptionLabel.textColor = UIColor.whiteColor;
    descriptionLabel.text      = V2Localize(@"MLVB.CameraStartPush.Twophones");
    [self.view addSubview:descriptionLabel];

    [descriptionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view.mas_left).offset(25);
        make.top.equalTo(self.navigationBar.mas_bottom).offset(23);
        make.right.equalTo(self.view.mas_right).offset(-25);
    }];

    NSArray *tips = @[ V2Localize(@"MLVB.CameraStartPush.Amobilephone"), V2Localize(@"MLVB.CameraStartPush.BInput") ];
    for (NSString *tipStr in tips) {
        UILabel *tipLabel                  = [[UILabel alloc] initWithFrame:CGRectZero];
        tipLabel.font                      = [UIFont fontWithName:@"PingFangSC-Regular" size:14];
        tipLabel.textColor                 = UIColorFromRGB(0x7689BC);
        tipLabel.text                      = tipStr;
        tipLabel.numberOfLines             = 2;
        tipLabel.adjustsFontSizeToFitWidth = true;
        [self.view addSubview:tipLabel];

        [tipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(descriptionLabel.mas_left);
            make.right.equalTo(descriptionLabel.mas_right);
            if (!_lastLabel) {
                make.top.equalTo(descriptionLabel.mas_bottom).offset(7);
            } else {
                make.top.equalTo(_lastLabel.mas_bottom);
            }
            _lastLabel = tipLabel;
        }];
    }
}

- (void)setupStreamView {
    [self.view addSubview:self.generateStreamBtn];
    [self.view addSubview:self.inputStreamAddressLabel];
    [self.view addSubview:self.inputStreamTextField];
    [self.view addSubview:self.scanBtn];
    [self.view addSubview:self.pushStreamBtn];

    [self.generateStreamBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_lastLabel.mas_bottom).offset(14);
        make.left.equalTo(self.view.mas_left).offset(25);
        make.right.equalTo(self.view.mas_right).offset(-25);
        make.height.mas_equalTo(54);
    }];

    [self.inputStreamAddressLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view.mas_left).offset(25);
        make.top.equalTo(self.generateStreamBtn.mas_bottom).offset(76);
    }];

    [self.inputStreamTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.inputStreamAddressLabel.mas_bottom).offset(9);
        make.left.equalTo(self.view.mas_left).offset(25);
        make.right.equalTo(self.view.mas_right).offset(-25);
        make.height.mas_equalTo(46);
    }];

    [self.scanBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.inputStreamTextField.mas_bottom).offset(14);
        make.left.equalTo(self.view.mas_left).offset(25);
        make.right.equalTo(self.view.mas_right).offset(-25);
        make.height.mas_equalTo(54);
    }];

    [self.pushStreamBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.scanBtn.mas_bottom).offset(101);
        make.left.equalTo(self.view.mas_left).offset(25);
        make.right.equalTo(self.view.mas_right).offset(-25);
        make.height.mas_equalTo(54);
    }];
}

- (void)setupAlertView {
    [self.view addSubview:self.alertView];
    [self.alertView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view.mas_left);
        make.right.equalTo(self.view.mas_right);
        make.top.equalTo(self.view.mas_top);
        make.bottom.equalTo(self.view.mas_bottom);
    }];
}

#pragma mark - generateURL
- (void)generateRTMPURL:(PushType)pushType {
    __weak typeof(self) weakSelf = self;
    [MBProgressHUD showHUDAddedTo:self.view animated:true];
    [TCHttpUtil
        asyncSendHttpRequest:@"get_test_pushurl"
              httpServerAddr:kHttpServerAddr
                  HTTPMethod:@"GET"
                       param:nil
                     handler:^(int result, NSDictionary *resultDict) {
                         __strong typeof(weakSelf) strongSelf = weakSelf;
                         [MBProgressHUD hideHUDForView:strongSelf.view animated:true];
                         if (result != 0 || resultDict == nil) {
                             [strongSelf showText:LivePlayerLocalize(@"LivePusherDemo.CameraPush.failedtogetpushstreamaddress") withDetailText:nil];
                         } else {
                             NSString *    pusherUrl   = resultDict[kPUSH_URL];
                             NSString *    rtmpPlayUrl = resultDict[kRTMP_PLAY_URL];
                             NSString *    flvPlayUrl  = resultDict[kFLV_PLAY_URL];
                             NSString *    hlsPlayUrl  = resultDict[kHLS_PLAY_URL];
                             NSString *    lebPlayUrl  = [rtmpPlayUrl stringByReplacingOccurrencesOfString:@"rtmp://" withString:@"webrtc://"];
                             NSDictionary *streamDictionary =
                                 @{kPUSH_URL : pusherUrl,
                                   kPUSH_TYPE : @(pushType),
                                   kRTMP_PLAY_URL : rtmpPlayUrl,
                                   kFLV_PLAY_URL : flvPlayUrl,
                                   kHLS_PLAY_URL : hlsPlayUrl,
                                   kLEB_PLAY_URL : lebPlayUrl};
                             CameraPushViewController *cameraPushVC = [[CameraPushViewController alloc] init];
                             cameraPushVC.streamURLDictionary       = streamDictionary;
                             NSLog(@"—————— streamURLDictionary = %@", streamDictionary);
                             [strongSelf.navigationController pushViewController:cameraPushVC animated:YES];
                         }
                     }];
}

- (void)generateRTCURL:(PushType)pushType {
    NSMutableDictionary *streamDictionary = [TCRTCUtil generateRTCURL];
    [streamDictionary setValue:@(pushType) forKey:kPUSH_TYPE];
    CameraPushViewController *cameraPushVC = [[CameraPushViewController alloc] init];
    cameraPushVC.streamURLDictionary       = streamDictionary;
    [self.navigationController pushViewController:cameraPushVC animated:YES];
}

- (void)showText:(NSString *)text withDetailText:(NSString *)detail {
    MBProgressHUD *hud    = [MBProgressHUD HUDForView:self.view];
    hud.mode              = MBProgressHUDModeText;
    hud.label.text        = text;
    hud.detailsLabel.text = detail;
    [hud showAnimated:YES];
    [hud hideAnimated:YES afterDelay:2];
}

#pragma mark - Event
- (void)backBtnClick:(UIButton *)sender {
    [self.navigationController popViewControllerAnimated:true];
}

- (void)helpBtnClick:(UIButton *)sender {
    NSURL *        helpUrl = [NSURL URLWithString:@"https://cloud.tencent.com/document/product/454/7879"];
    UIApplication *myApp   = [UIApplication sharedApplication];
    if ([myApp canOpenURL:helpUrl]) {
        [myApp openURL:helpUrl];
    }
}

- (void)generateStreamBtnClick:(UIButton *)sender {
    [self.alertView show];
}

- (void)scanBtnClick:(UIButton *)sender {
    ScanQRController *scanQRViewController = [[ScanQRController alloc] init];
    scanQRViewController.delegate          = self;
    [self.navigationController pushViewController:scanQRViewController animated:NO];
}

- (void)pushBtnClick:(UIButton *)sender {
    if (self.inputStreamTextField.text.length > 0) {
        NSMutableDictionary *streamDictionary = [TCRTCUtil generateRTCURL];
        [streamDictionary setObject:self.inputStreamTextField.text forKey:kPUSH_URL];
        if ([self.inputStreamTextField.text hasPrefix:@"trtc://"]) {
            [streamDictionary setObject:@(RTC) forKey:kPUSH_TYPE];
        } else {
            [streamDictionary setObject:@(RTMP) forKey:kPUSH_TYPE];
        }
        CameraPushViewController *cameraPushVC = [[CameraPushViewController alloc] init];
        cameraPushVC.streamURLDictionary       = streamDictionary;
        [self.navigationController pushViewController:cameraPushVC animated:YES];
    }
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - ScanQRDelegate
- (void)onScanResult:(NSString *)result {
    self.inputStreamTextField.text = result;
}
@end

@implementation TCRTCUtil

+ (NSMutableDictionary *)generateRTCURL {
    NSString *userId      = [TCRTCUtil generateRandomNumberFrom:100000 to:999999];
    NSString *streamId    = [TCRTCUtil generateRandomNumberFrom:100000 to:999999];
    NSString *pushURL     = [NSString stringWithFormat:@"%@%@?sdkappid=%d&userid=%@&usersig=%@", RTC_PUSH_URL, streamId, SDKAPPID, userId, [GenerateTestUserSig genTestUserSig:userId]];
    NSString *rtmpPlayURL = [NSString stringWithFormat:@"%@%@", RTMP_PLAY_URL, streamId];
    NSString *flvPlayURL  = [NSString stringWithFormat:@"%@%@.flv", HTTP_PLAY_URL, streamId];
    NSString *hlsPlayURL  = [NSString stringWithFormat:@"%@%@.m3u8", HTTP_PLAY_URL, streamId];
    //    NSString *accPlayURL = [NSString stringWithFormat:@"%@%@",RTMP_PLAY_URL,streamId];
    NSString *           lebPlayURL          = [rtmpPlayURL stringByReplacingOccurrencesOfString:@"rtmp://" withString:@"webrtc://"];
    NSMutableDictionary *streamURLDictionary = [NSMutableDictionary dictionaryWithDictionary:@{
        kPUSH_URL : pushURL,
        kRTMP_PLAY_URL : rtmpPlayURL,
        kFLV_PLAY_URL : flvPlayURL,
        kHLS_PLAY_URL : hlsPlayURL,
        //                                                                                                kACC_PLAY_URL: accPlayURL,
        kLEB_PLAY_URL : lebPlayURL,
        kRTC_PLAY_URL : streamId
    }];
    return streamURLDictionary;
}

+ (NSString *)generateRandomNumberFrom:(NSInteger)from to:(NSInteger)to {
    NSInteger x = arc4random() % (to - from + 1) + from;
    return [NSString stringWithFormat:@"%ld", (long)x];
}

@end
