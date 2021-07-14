//
//  TRTCLiveAnchorViewController.m
//  TXLiteAVDemo
//
//  Created by bluedang on 2021/5/25.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "TRTCLiveAnchorViewController.h"
#import "TRTCBroadcastExtensionLauncher.h"
#import "Masonry.h"
#import "AppLocalized.h"
#import "ColorMacro.h"

@interface TRTCLiveAnchorViewController ()
@property (strong, nonatomic) UIButton *captureBtn;
@end

@implementation TRTCLiveAnchorViewController


+ (instancetype)initWithTRTCCloudManager:(TRTCCloudManager*)cloudManager {
    TRTCLiveAnchorViewController *liveVC = [[TRTCLiveAnchorViewController alloc] initWithNibName:@"TRTCLiveViewController" bundle:nil];
    liveVC.cloudManager = cloudManager;

    [cloudManager setDelegate:liveVC];
    return liveVC;

}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
    [self setupAnchorCloudManager];
    if (self.cloudManager.videoInputType == TRTCVideoCaptureDevice) {
        [self setupScreenCaptureUI];
    }
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [self layoutViews];
}

- (void)setupUI {
    [self.switchRoleBtn setHidden:true];
}

- (void)setupScreenCaptureUI {

    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:TRTCLocalize(@"Demo.TRTC.Live.startScreenCapture") forState:UIControlStateNormal];
    [button setTitleColor:[UIColor cyanColor] forState:UIControlStateNormal];
    [button setTitle:TRTCLocalize(@"Demo.TRTC.Live.stopScreenCapture") forState:UIControlStateSelected];
    [button setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
    button.backgroundColor = [UIColor grayColor];
    [self.view addSubview:button];
    button.clipsToBounds = YES;
    button.layer.cornerRadius = 5.0;
    [button addTarget:self action:@selector(onClickScreenCastButton:) forControlEvents:UIControlEventTouchUpInside];
    [button mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.equalTo([NSValue valueWithCGSize: CGSizeMake(120, 50)]);
        make.centerX.equalTo(self.view.mas_centerX);
        make.bottom.equalTo(self.view.mas_bottomMargin).offset(-50);
    }];
    self.captureBtn = button;
    
    [self.localPreView setBackgroundColor:UIColorFromRGB(0x293035)];
    self.localPreView.autoresizesSubviews = YES;
    [self.localPreView showText:TRTCLocalize(@"Demo.TRTC.Live.screenWait")];
}

- (void)onClickScreenCastButton:(UIButton*)button {
    if (button.isSelected) {
        [self.cloudManager stopScreenCapture];
    } else {
        [self.cloudManager startScreenCapture];
        [TRTCBroadcastExtensionLauncher launch];
    }
}

#pragma mark - TRTCCloudManagerDelegate delegate

- (void)onUserVideoAvailable:(NSString*)userId available:(bool)available {
    if (!available) {
        if (![userId isEqualToString:self.mainViewUserId]) {
            return;
        }
        self.mainViewUserId = self.cloudManager.userId;
    } else {
        [self.cloudManager.viewDic[userId] setDelegate:self];
    }
    
    [self layoutViews];
}

- (void)onScreenCaptureIsStarted:(BOOL)enabled {
    self.captureBtn.selected = enabled;
    if (enabled) {
        [self.localPreView showText:TRTCLocalize(@"Demo.TRTC.Live.screenCapture")];
    } else {
        [self.localPreView showText:TRTCLocalize(@"Demo.TRTC.Live.screenStop")];
    }
}


@end
