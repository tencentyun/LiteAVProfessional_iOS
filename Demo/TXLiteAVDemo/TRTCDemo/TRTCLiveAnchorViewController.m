//
//  TRTCLiveAnchorViewController.m
//  TXLiteAVDemo
//
//  Created by bluedang on 2021/5/25.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "TRTCLiveAnchorViewController.h"

#import "AppLocalized.h"
#import "ColorMacro.h"
#import "Masonry.h"
#import "TRTCBroadcastExtensionLauncher.h"

@interface                                   TRTCLiveAnchorViewController ()
@property(strong, nonatomic) UIButton *      captureBtn;
@property(assign, nonatomic) dispatch_once_t once;
@property(assign, nonatomic) BOOL            isScreenCaptureFlag;
@end

@implementation TRTCLiveAnchorViewController

+ (instancetype)initWithTRTCCloudManager:(TRTCCloudManager *)cloudManager {
    TRTCLiveAnchorViewController *liveVC = [[TRTCLiveAnchorViewController alloc] initWithNibName:@"TRTCLiveViewController" bundle:nil];
    liveVC.cloudManager                  = cloudManager;

    [cloudManager setDelegate:liveVC];
    return liveVC;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setupUI];
    [self setupCloudManager];
    if (self.cloudManager.videoInputType == TRTCVideoCaptureDevice || self.cloudManager.subVideoInputType == TRTCVideoCaptureDevice) {
        [self setupScreenCaptureUI];
    }
    
    if (self.cloudManager.videoInputType == TRTCVideoCaptureScreen) {
        [self setupScreenCaptureTOWeb];
    }
    
    self.isScreenCaptureFlag = false;
    [self.cloudManager startLiveWithRoomId:self.cloudManager.roomId userId:self.cloudManager.userId];
    [self.cloudManager setAudioEnabled:YES];
    [self setupChorus];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    dispatch_once(&_once, ^{
        [self layoutViews];
    });
}

- (void)setupUI {
    [self.switchRoleBtn setHidden:true];
    [self.cdnSettingBtn setHidden:true];
}

- (void)setupScreenCaptureUI {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:TRTCLocalize(@"Demo.TRTC.Live.startScreenCapture") forState:UIControlStateNormal];
    [button setTitleColor:[UIColor cyanColor] forState:UIControlStateNormal];
    [button setTitle:TRTCLocalize(@"Demo.TRTC.Live.stopScreenCapture") forState:UIControlStateSelected];
    [button setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
    button.backgroundColor = [UIColor grayColor];
    [self.view addSubview:button];
    button.clipsToBounds      = YES;
    button.layer.cornerRadius = 5.0;
    [button addTarget:self action:@selector(onClickScreenCastButton:) forControlEvents:UIControlEventTouchUpInside];
    [button mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.equalTo([NSValue valueWithCGSize:CGSizeMake(120, 50)]);
        make.centerX.equalTo(self.view.mas_centerX);
        make.bottom.equalTo(self.view.mas_bottom).offset(-50);
    }];
    self.captureBtn = button;

    [self.localPreView setBackgroundColor:UIColorFromRGB(0x293035)];
    self.localPreView.autoresizesSubviews = YES;
    [self.localPreView showText:TRTCLocalize(@"Demo.TRTC.Live.screenWait")];
}

- (void)setupScreenCaptureTOWeb {
    UIWebView *webview = [[UIWebView alloc] init];
    [webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://cloud.tencent.com/"]]];
    [self.localPreView insertSubview:webview atIndex:0];
    [webview mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.localPreView);
    }];
}

- (void)onClickScreenCastButton:(UIButton *)button {
    self.isScreenCaptureFlag = !self.isScreenCaptureFlag;
    if (button.isSelected) {
        [self.cloudManager stopScreenCapture];
    } else {
        [self.cloudManager startScreenCapture];
        [TRTCBroadcastExtensionLauncher launch];
    }
}

#pragma mark - TRTCCloudManagerDelegate delegate

- (void)onScreenCaptureIsStarted:(BOOL)enabled {
    if (self.isScreenCaptureFlag && !enabled) {
        [self.cloudManager stopScreenCapture];
        self.isScreenCaptureFlag = !self.isScreenCaptureFlag;
    }
    self.captureBtn.selected = enabled;
    if (enabled) {
        [self.localPreView showText:TRTCLocalize(@"Demo.TRTC.Live.screenCapture")];
    } else {
        [self.localPreView showText:TRTCLocalize(@"Demo.TRTC.Live.screenStop")];
    }
}
- (void)dealloc
{
    self.cloudManager.videoConfig.isEnabled = YES;
    self.cloudManager.videoConfig.localRenderParams.rotation = 0;
}

@end
