//
//  LebLauncherViewController.m
//  TXLiteAVDemo
//
//  Created by abyyxwang on 2021/5/11.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "LebLauncherViewController.h"
#import <Masonry/Masonry.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import "LebQRScanViewController.h"
#import "LebLiveUtils.h"
#import "LebPlayerViewController.h"
#import "AppLocalized.h"

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 \
alpha:1.0]



@interface LebLauncherViewController ()<ScanQRDelegate>

@property (nonatomic, strong) UILabel *playLabel;
@property (nonatomic, strong) UIButton *scranCodeBtn;
@property (nonatomic, strong) UIButton *startPlayBtn;
@property (nonatomic, strong) UITextField *inputTextField;

@end

@implementation LebLauncherViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initUI];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;
}

- (void)initUI {
    self.title = V2Localize(@"MLVB.lebLauncher.title");
    
    CAGradientLayer *layer = [CAGradientLayer layer];
    layer.colors = @[(__bridge id)UIColorFromRGB(0x13294B).CGColor, (__bridge id)UIColorFromRGB(0x000000).CGColor];
    layer.startPoint = CGPointMake(0, 0);
    layer.endPoint = CGPointMake(0, 1.0);
    layer.frame = self.view.bounds;
    [self.view.layer insertSublayer:layer atIndex:0];

    
    
    self.playLabel = [[UILabel alloc]initWithFrame:CGRectMake(20, 100, 300, 20)];
    self.playLabel.text = V2Localize(@"MLVB.lebLauncher.inputUrl");
    self.playLabel.textColor = [UIColor whiteColor];
    [self.view addSubview:self.playLabel];
    
    self.inputTextField = [[UITextField alloc] initWithFrame:CGRectZero];
    self.inputTextField.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.inputTextField.layer.borderWidth = 1.0;
    self.inputTextField.font = [UIFont systemFontOfSize:16];
    self.inputTextField.text = @"webrtc://5664.liveplay.myqcloud.com/live/5664_harchar1";
    self.inputTextField.textColor = [UIColor whiteColor];
    [self.view addSubview:self.inputTextField];
    [self.inputTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view.mas_left).offset(20);
        make.right.equalTo(self.view.mas_right).offset(-20);
        make.top.equalTo(self.playLabel.mas_bottom).offset(10);
        make.height.mas_equalTo(48);
    }];
    
    self.scranCodeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.view addSubview:self.scranCodeBtn];
    [self.scranCodeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.inputTextField.mas_bottom).offset(20);
        make.left.mas_equalTo(self.view.mas_left).offset(20);
        make.right.mas_equalTo(self.view.mas_right).offset(-20);
        make.height.mas_equalTo(48);
    }];
    self.scranCodeBtn.backgroundColor = UIColorFromRGB(0x2243EC);
    [self.scranCodeBtn setImage:[UIImage imageNamed:@"livepusher_ic_qcode"] forState:UIControlStateNormal];
    self.scranCodeBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.scranCodeBtn addTarget:self action:@selector(onScranCodeBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    
    self.startPlayBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.view addSubview:self.startPlayBtn];
    [self.startPlayBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.scranCodeBtn.mas_bottom).offset(20);
        make.left.mas_equalTo(self.view.mas_left).offset(20);
        make.right.mas_equalTo(self.view.mas_right).offset(-20);
        make.height.mas_equalTo(48);
    }];
    self.startPlayBtn.titleLabel.font = [UIFont systemFontOfSize:16.0];
    self.startPlayBtn.backgroundColor = UIColorFromRGB(0x2243EC);
    [self.startPlayBtn setTitle:V2Localize(@"V2.Live.LinkMicNew.startstreampull") forState:UIControlStateNormal];
    [self.startPlayBtn addTarget:self action:@selector(onStartPlayButtonClick:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)onScranCodeBtnClick:(UIButton *)sender {
    LebQRScanViewController *vc = [[LebQRScanViewController alloc] init];
    vc.delegate = self;
    vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)onStartPlayButtonClick:(UIButton *)sender {
    if (![LebLiveUtils isWebrtcUrl:self.inputTextField.text]) {
        [self showText:@"" withDetailText:LivePlayerLocalize(@"LivePlayer.lebLauncher.enterplayeraddress")];
        return;
    }
    LebPlayerViewController *playViewController = [[LebPlayerViewController alloc] init];
    playViewController.url = self.inputTextField.text;
    playViewController.muteAudio = NO;
    playViewController.muteVideo = NO;
    [playViewController startPlay];
    [self.navigationController pushViewController:playViewController animated:YES];
}

#pragma mark - ScanQRDelegate
- (void)onScanResult:(nonnull NSString *)result {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.inputTextField.text = result;
        if (self.presentedViewController) {
            [self.presentedViewController dismissViewControllerAnimated:NO completion:nil];
        }
    });
}

- (void)showText:(NSString *)text withDetailText:(NSString *)detail {
    MBProgressHUD *hud = [MBProgressHUD HUDForView:[UIApplication sharedApplication].delegate.window];
    if (hud == nil) {
        hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].delegate.window animated:YES];
    }
    hud.mode = MBProgressHUDModeText;
    hud.label.text = text;
    hud.detailsLabel.text = detail;
    [hud showAnimated:YES];
    [hud hideAnimated:YES afterDelay:1];
}


@end
