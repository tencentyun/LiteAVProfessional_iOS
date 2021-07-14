//
//  TRTCEntranceViewController.m
//  TXLiteAVDemo_Enterprise
//
//  Created by bluedang on 2021/5/13.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "TRTCLiveEnterViewController.h"
#import "TRTCCloudManager.h"
#import "TRTCLiveAnchorViewController.h"
#import "TRTCLiveAudienceViewController.h"
#import "Masonry.h"
#import "ColorMacro.h"
#import "AppLocalized.h"

#import "QBImagePickerController.h"

@interface TRTCLiveEnterViewController () <QBImagePickerControllerDelegate>

@property (strong, nonatomic) UIButton *enterRoomBtn;
@property (nonatomic, retain) UITextView* toastView;

@property (strong, nonatomic) TRTCSettingsLargeInputItem* roomItem;
@property (strong, nonatomic) TRTCSettingsLargeInputItem* nameItem;
@property (strong, nonatomic) TRTCSettingsSegmentItem *mainVideoInputItem;
@property (strong, nonatomic) TRTCSettingsSegmentItem *audioInputItem;
@property (strong, nonatomic) TRTCSettingsSegmentItem *roomIdTypeItem;
@property (strong, nonatomic) TRTCSettingsSegmentItem *volumeType;
@property (strong, nonatomic) TRTCSettingsSegmentItem *soundsType;
@property (strong, nonatomic) TRTCSettingsSegmentItem *audioQualityItem;

@property (strong, nonatomic) TRTCCloudManager *cloudManager;
@property (assign, nonatomic) BOOL isSpeedTesting;
@property (assign, nonatomic) BOOL isLoadingFile;
@end

@implementation TRTCLiveEnterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initUI];
    _isSpeedTesting = false;
    _isLoadingFile = false;
    _cloudManager = [TRTCCloudManager new];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}

- (void)initUI {
    [self setupBackgroudColor];
    [self setupListItems];
    
    _enterRoomBtn = [self createButtonWithTitle:TRTCLocalize(@"Demo.TRTC.Live.enterRoom") action:@selector(onEnterRoomBtnClick:)];
        
    self.toastView = [[UITextView alloc] init];
    self.toastView.editable = NO;
    self.toastView.selectable = NO;

    [_enterRoomBtn mas_makeConstraints:^(MASConstraintMaker* make) {
        make.bottom.equalTo(self.view).offset(-30);
        make.leading.equalTo(self.view).offset(20);
        make.trailing.equalTo(self.view).offset(-20);
        make.height.mas_equalTo(50);
    }];
}

- (UIButton*)createButtonWithTitle:(NSString*)title action:(SEL)select {
    UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
    button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.layer.cornerRadius = 8;
    button.layer.masksToBounds = YES;
    button.backgroundColor = UIColorFromRGB(0x2364db);
    [button setTitle:title forState:UIControlStateNormal];
    [button addTarget:self action:select forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    return button;
}

- (void)setupBackgroudColor {
    UIColor *startColor = [UIColor colorWithRed:19.0 / 255.0 green:41.0 / 255.0 blue:75.0 / 255.0 alpha:1];
    UIColor *endColor = [UIColor colorWithRed:5.0 / 255.0 green:12.0 / 255.0 blue:23.0 / 255.0 alpha:1];

    NSArray* colors = @[(id)startColor.CGColor, (id)endColor.CGColor];

    CAGradientLayer *layer = [CAGradientLayer layer];
    layer.colors = colors;
    layer.startPoint = CGPointMake(0, 0);
    layer.endPoint = CGPointMake(1, 1);
    layer.frame = self.view.bounds;
    
    [self.view.layer insertSublayer:layer atIndex:0];
}

- (BOOL)isPureInt:(NSString *)string{
    NSScanner* scan = [NSScanner scannerWithString:string];
    int val;
    return [scan scanInt:&val] && [scan isAtEnd];
}

- (void)setupConfig {
    [self.cloudManager setVolumeType:self.volumeType.selectedIndex];
    [self.cloudManager setAudioRoute:self.soundsType.selectedIndex];
    [self.cloudManager setAudioQuality:(self.audioQualityItem.selectedIndex + TRTCAudioQualitySpeech)];
}

- (void)setupListItems {
    NSMutableArray *items = [NSMutableArray array];
    self.roomItem = [[TRTCSettingsLargeInputItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.inputRoomId")
                                                          placeHolder:@"132456"];
    [items addObject:self.roomItem];
    self.roomItem.maxLength = 9;
    
    self.nameItem = [[TRTCSettingsLargeInputItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.inputUserId")
                                                          placeHolder:@"132456"];
    [items addObject:self.nameItem];
    self.nameItem.maxLength = 40;
    
    
    self.roleItem = [[TRTCSettingsSegmentItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.switchRole")
                                                             items:@[TRTCLocalize(@"Demo.TRTC.Live.anchor"), TRTCLocalize(@"Demo.TRTC.Live.adudience")]
                                                     selectedIndex:0
                                                            action:^(NSInteger index) {
        [self.cloudManager setRole:index + TRTCRoleAnchor];
    }];
    [items addObject:self.roleItem];

    // 不同平台可能不支持
    self.mainVideoInputItem = [[TRTCSettingsSegmentItem alloc]
                                                        initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.videoInput")
                                                                items:@[TRTCLocalize(@"Demo.TRTC.Live.camera"), TRTCLocalize(@"Demo.TRTC.Live.mediaFile"), TRTCLocalize(@"Demo.TRTC.Live.deviceCapture"),
                                                                    TRTCLocalize(@"Demo.TRTC.Live.none"),
                                                                ]
                                                           selectedIndex:0
                                                                  action:^(NSInteger index) {
        [self.cloudManager setVideoInputType:index];
    }];
    [items addObject:self.mainVideoInputItem];
    
    
    self.audioInputItem = [[TRTCSettingsSegmentItem alloc]
                                                        initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.autioInput")
                                                                   items:@[TRTCLocalize(@"Demo.TRTC.Live.sdkCapture"), TRTCLocalize(@"Demo.TRTC.Live.customCapture"),
                                                                       TRTCLocalize(@"Demo.TRTC.Live.none"),
                                                                   ]
                                                           selectedIndex:0
                                                                  action:^(NSInteger index) {
        [self.cloudManager setAudioInputType:index];
    }];
    [items addObject:self.audioInputItem];
    
    

    self.volumeType = [[TRTCSettingsSegmentItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.audioType")
                                                               items:@[TRTCLocalize(@"Demo.TRTC.Live.audioTypeAuto"), TRTCLocalize(@"Demo.TRTC.Live.audioTypeMedia"), TRTCLocalize(@"Demo.TRTC.Live.audioTypeCalling")]
                                                       selectedIndex:0
                                                              action:^(NSInteger index) {
        [self.cloudManager setVolumeType:index];
    }];
    [items addObject:self.volumeType];

    
    self.soundsType = [[TRTCSettingsSegmentItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.audioOutput")
                                                               items:@[TRTCLocalize(@"Demo.TRTC.Live.speaker"), TRTCLocalize(@"Demo.TRTC.Live.earPhone")]
                                                       selectedIndex:0
                                                              action:^(NSInteger index) {
        [self.cloudManager setAudioRoute:index];
    }];
    [items addObject:self.soundsType];
    
    self.audioQualityItem = [[TRTCSettingsSegmentItem alloc]
                                                         initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.audioQuality")
                                                            items:@[TRTCLocalize(@"Demo.TRTC.Live.talk"), TRTCLocalize(@"Demo.TRTC.Live.default"), TRTCLocalize(@"Demo.TRTC.Live.music")]
                                                             selectedIndex:1
                                                                    action:^(NSInteger index) {
        [self.cloudManager setAudioQuality:index + TRTCAudioQualitySpeech];
    }];
    [items addObject:self.audioQualityItem];
    
    self.roomIdTypeItem = [[TRTCSettingsSegmentItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.roomType")
                                                             items:@[TRTCLocalize(@"Demo.TRTC.Live.int"), TRTCLocalize(@"Demo.TRTC.Live.string")]
                                                     selectedIndex:0
                                                            action:^(NSInteger index) {
        [self.cloudManager setRoomIdType:index];
    }];
    [items addObject:self.roomIdTypeItem];

    self.items = items;
}

- (float)heightForString:(UITextView *)textView andWidth:(float)width {
    CGSize sizeToFit = [textView sizeThatFits:CGSizeMake(width, MAXFLOAT)];
    return sizeToFit.height;
}

- (void)toastTip:(NSString *)toastInfo time:(NSInteger)time{
    dispatch_async(dispatch_get_main_queue(), ^{
        UITextView *toastViewTmp = self.toastView;
        [toastViewTmp removeFromSuperview];
        
        CGRect frameRC = [[UIScreen mainScreen] bounds];
        frameRC.origin.y = frameRC.size.height - 110;
        frameRC.size.height -= 110;
        frameRC.size.height = [self heightForString:toastViewTmp andWidth:frameRC.size.width];
        
        toastViewTmp.frame = frameRC;
        
        toastViewTmp.text = toastInfo;
        toastViewTmp.backgroundColor = [UIColor whiteColor];
        toastViewTmp.alpha = 0.5;
        
        [self.view addSubview:toastViewTmp];
        
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, time * NSEC_PER_SEC);
        
        dispatch_after(popTime, dispatch_get_main_queue(), ^() {
            [toastViewTmp removeFromSuperview];
        });
    });
}

- (void)showMeidaPicker {
    QBImagePickerController* imagePicker = [[QBImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.allowsMultipleSelection = YES;
    imagePicker.showsNumberOfSelectedAssets = YES;
    imagePicker.minimumNumberOfSelection = 1;
    imagePicker.maximumNumberOfSelection = 1;
    imagePicker.mediaType = QBImagePickerMediaTypeVideo;
    imagePicker.title = @"选择视频源";

    [self.navigationController pushViewController:imagePicker animated:YES];
}


#pragma mark - Actions

- (void)onSpeedTestBtnClick:(UIButton*)button {
    button.selected = !button.selected;
    if (_isSpeedTesting) {
        [_cloudManager stopSpeedTest];
        _isSpeedTesting = false;
        return;
    }
    
    NSString *userId = self.nameItem.content.length == 0 ? self.nameItem.placeHolder : self.nameItem.content;
    [_cloudManager startSpeedTest:userId completion:^(TRTCSpeedTestResult* result,
                                                      NSInteger completedCount,
                                                      NSInteger totalCount) {
        [self toastTip:[result description] time:3];
        if (completedCount == totalCount) {
            self.isSpeedTesting = false;
            button.selected = !button.selected;
        }
    }];
    _isSpeedTesting = true;
}

- (void)onEnterRoomBtnClick:(UIButton*)button {
    if (self.isLoadingFile) { return; }
    
    if (self.mainVideoInputItem.selectedIndex == 1) {
        [self showMeidaPicker];
    } else {
        [self startLive];
    }
}

- (void)startLive {
    
    NSString *userId = self.nameItem.content.length == 0 ? self.nameItem.placeHolder : self.nameItem.content;
    NSString *roomId = self.roomItem.content.length == 0 ? self.roomItem.placeHolder : self.roomItem.content;
    
    if (self.cloudManager.roomIdType == TRTCIntRoomId) {
        if (![self isPureInt:roomId]){
            [self toastTip:@"invalid roomId" time:2];
            return;
        }
    }
    
    [self setupConfig];
    
    if (self.roleItem.selectedIndex == 0) {
        TRTCLiveAnchorViewController *liveVC = [TRTCLiveAnchorViewController initWithTRTCCloudManager:_cloudManager];
        [_cloudManager startLiveWithRoomId:roomId userId:userId];
        [self.navigationController pushViewController:liveVC animated:YES];
    } else {
        TRTCLiveAudienceViewController *liveVC = [TRTCLiveAudienceViewController initWithTRTCCloudManager:_cloudManager];
        [_cloudManager enterLiveRoom:roomId userId:userId];
        [self.navigationController pushViewController:liveVC animated:YES];
    }

}

#pragma mark - QBIamgePicker Delegate

- (void)qb_imagePickerController:(QBImagePickerController *)imagePickerController didFinishPickingAssets:(NSArray *)assets
{
    [self.navigationController popViewControllerAnimated:YES];
    PHVideoRequestOptions *options = [PHVideoRequestOptions new];
    options.deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
    options.networkAccessAllowed = YES;
    
    __weak __typeof(self) weakSelf = self;
    options.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
        NSString *process = [[NSString alloc] initWithFormat:@"%@ %d%%" , TRTCLocalize(@"Demo.TRTC.Live.progress") ,(int)(progress * 100)];
        [weakSelf toastTip:process time:2];
    };
    
    self.isLoadingFile = true;
    [[PHImageManager defaultManager] requestAVAssetForVideo:assets.firstObject options:options resultHandler:^(AVAsset * _Nullable avAsset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
        weakSelf.cloudManager.customSourceAsset = avAsset;
        dispatch_async(dispatch_get_main_queue(), ^{
            @autoreleasepool {
                weakSelf.isLoadingFile = false;
                [weakSelf startLive];
            };
        });
    }];
}

- (void)qb_imagePickerControllerDidCancel:(QBImagePickerController *)imagePickerController {
    [self.navigationController popViewControllerAnimated:YES];
}


@end
