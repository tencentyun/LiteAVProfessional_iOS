//
//  TRTCLiveViewController.h
//  TXLiteAVDemo
//
//  Created by bluedang on 2021/5/17.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TRTCCloudManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface TRTCLiveViewController : UIViewController <TRTCCloudManagerDelegate>

+ (instancetype)initWithTRTCCloudManager:(TRTCCloudManager*)cloudManager;

@property (weak, nonatomic) IBOutlet UIView *holderView;
@property (weak, nonatomic) IBOutlet UIButton *switchRoleBtn;
@property (weak, nonatomic) IBOutlet UIButton *switchCamBtn;
@property (weak, nonatomic) IBOutlet UIButton *closeCamBtn;
@property (weak, nonatomic) IBOutlet UIButton *muteMic;
@property (weak, nonatomic) IBOutlet UIButton *beautyBtn;
@property (weak, nonatomic) IBOutlet UIButton *audioEffectBtn;
@property (weak, nonatomic) IBOutlet UIButton *settingsBtn;
@property (weak, nonatomic) IBOutlet UIButton *userControlBtn;
@property (weak, nonatomic) IBOutlet UIButton *cdnBtn;
@property (weak, nonatomic) IBOutlet UIButton *stackLogBtn;
@property (strong, nonatomic) UIButton *logBtn;

@property (weak, nonatomic) IBOutlet UIStackView *featureBtnStackView;

@property (weak, nonatomic) TRTCCloudManager *cloudManager;
@property (strong, nonatomic) TRTCVideoView *localPreView;
@property (strong, nonatomic) NSString *mainViewUserId;

- (void)onLogBtnClick:(UIButton*)button;
- (void)layoutViews;
- (void)setupAnchorCloudManager;
- (void)setupAudienceCloudManager;
- (void)toastTip:(NSString *)toastInfo, ...;

@end

NS_ASSUME_NONNULL_END
