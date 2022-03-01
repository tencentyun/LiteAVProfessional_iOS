//
//  TRTCEntranceViewController.m
//  TXLiteAVDemo_Enterprise
//
//  Created by bluedang on 2021/5/13.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "TRTCLiveEnterViewController.h"
#import "AppLocalized.h"
#import "ColorMacro.h"
#import "Masonry.h"
#import "QBImagePickerController.h"
#import "TCUtil.h"
#import "TRTCCloudManager.h"
#import "TRTCCustomerCrypt.h"
#import "TRTCLiveAnchorViewController.h"
#import "TRTCLiveAudienceViewController.h"

@interface TRTCCloud (Private)
+ (void)setNetEnv:(int)env;
@end

@interface TRTCLiveEnterViewController () <QBImagePickerControllerDelegate>

@property(strong, nonatomic) UIButton *  enterRoomBtn;
@property(nonatomic, retain) UITextView *toastView;

@property(strong, nonatomic) TRTCSettingsLargeInputItem *roomItem;
@property(strong, nonatomic) TRTCSettingsLargeInputItem *nameItem;

@property(strong, nonatomic) TRTCSettingsSegmentItem *mainVideoInputItem;
@property(strong, nonatomic) TRTCSettingsSegmentItem *audioInputItem;
@property(strong, nonatomic) TRTCSettingsSegmentItem *roomIdTypeItem;
@property(strong, nonatomic) TRTCSettingsSegmentItem *volumeType;
@property(strong, nonatomic) TRTCSettingsSegmentItem *soundsType;
@property(strong, nonatomic) TRTCSettingsSegmentItem *audioQualityItem;

@property(assign, nonatomic) BOOL                        isSpeedTesting;
@property(assign, nonatomic) BOOL                        isLoadingFile;
@property(nonatomic, retain) AVAsset *                   customSourceAsset;
@property(strong, nonatomic) TRTCSettingsLargeInputItem *cryptKeyItem;
@property(strong, nonatomic) TRTCSettingsSegmentItem    *subVideoInputItem;  //辅路视频源
@property(strong, nonatomic) TRTCSettingsSegmentItem    *videoCodecItem;     //编码选择
@property(strong, nonatomic) TRTCSettingsSegmentItem    *videoEncoderTypeItem; //编码类型

@property(strong, nonatomic) TRTCSettingsSegmentItem    *audioModeItem;      //音频场景
@property(strong, nonatomic) TRTCSettingsSegmentItem    *audio3AItem;        // 3A
@property(strong, nonatomic) TRTCSettingsSegmentItem    *audioRecvModeItem;  //音频接收
@property(strong, nonatomic) TRTCSettingsSegmentItem    *videoRecvModeItem;  //视频接收
@property(strong, nonatomic) TRTCSettingsSegmentItem    *envItem;
@property(strong, nonatomic) TRTCSettingsLargeInputItem *chorusCdnUrlItem;
@property(strong, nonatomic) TRTCSettingsMessageItem    *audioParallelMaxCountItem;
@property(strong, nonatomic) TRTCCloudManager           *cloudManager;

@end

@implementation TRTCLiveEnterViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.scene = TRTCAppSceneLIVE;
        self.title = TRTCLocalize(@"Demo.TRTC.Live.trtcLive");
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view).offset(-80);
    }];
    [self initUI];
    _isSpeedTesting = false;
    _isLoadingFile  = false;
    TRTCParams *params = [[TRTCParams alloc] init];
    _cloudManager   = [[TRTCCloudManager alloc] initWithParams:params scene:self.scene];
    if (self.scene == TRTCAppSceneVideoCall) {
        [self.items removeObject:self.roleItem];
        [self.items removeObject:self.audioModeItem];
    }
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

    self.toastView            = [[UITextView alloc] init];
    self.toastView.editable   = NO;
    self.toastView.selectable = NO;

    [_enterRoomBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view).offset(-30);
        make.leading.equalTo(self.view).offset(20);
        make.trailing.equalTo(self.view).offset(-20);
        make.height.mas_equalTo(50);
    }];
}

- (UIButton *)createButtonWithTitle:(NSString *)title action:(SEL)select {
    UIButton *button           = [UIButton buttonWithType:UIButtonTypeCustom];
    button                     = [UIButton buttonWithType:UIButtonTypeCustom];
    button.layer.cornerRadius  = 8;
    button.layer.masksToBounds = YES;
    button.backgroundColor     = UIColorFromRGB(0x2364db);
    [button setTitle:title forState:UIControlStateNormal];
    [button addTarget:self action:select forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    return button;
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

- (BOOL)isPureInt:(NSString *)string {
    NSScanner *scan = [NSScanner scannerWithString:string];
    int        val;
    return [scan scanInt:&val] && [scan isAtEnd];
}

- (void)setupConfig {
    self.cloudManager.chrousUri = self.chorusCdnUrlItem.content;
    // selectedIndex = 3 （3代表不选 走默认逻辑0）
    [self.cloudManager setVolumeType:self.volumeType.selectedIndex == 3 ? -1 : self.volumeType.selectedIndex];
    [self.cloudManager setAudioRoute:self.soundsType.selectedIndex];
    
    [self.cloudManager setAudioQuality:self.audioQualityItem.selectedIndex == 3 ? -1 : (self.audioQualityItem.selectedIndex + TRTCAudioQualitySpeech)];
    [self.cloudManager.videoConfig setSource:self.mainVideoInputItem.selectedIndex];
    [self.cloudManager.audioConfig setIsCustomCapture:self.audioInputItem.selectedIndex == 1];
    if (DEBUGSwitch) {
        [TRTCCloud setNetEnv:(int)self.envItem.selectedIndex];
        TRTCRemoteUserManager *remoteManager = [[TRTCRemoteUserManager alloc] initWithTrtc:[TRTCCloud sharedInstance]];

        [remoteManager enableAutoReceiveAudio:self.audioRecvModeItem.selectedIndex == 0 autoReceiveVideo:self.videoRecvModeItem.selectedIndex == 0];
        if (self.cryptKeyItem.content.length > 0) {
            [TRTCCustomerCrypt sharedInstance].encryptKey = self.cryptKeyItem.content;
            [self.cloudManager addCustomerCrypt];
        }else{
            // 密码为空, 更新 encryptKey 配置
            [TRTCCustomerCrypt sharedInstance].encryptKey = @"";
            [self.cloudManager addCustomerCrypt];
        }
        [self.cloudManager enableHEVCEncode:self.videoCodecItem.selectedIndex == 1];
        [self.cloudManager setVideoCodecType:self.videoEncoderTypeItem.selectedIndex];
        if (self.audio3AItem.selectedIndex < 2) {
            BOOL is3AEnabled = self.audio3AItem.selectedIndex;
            [self.cloudManager setAecEnabled:is3AEnabled];
            [self.cloudManager setAnsEnabled:is3AEnabled];
            [self.cloudManager setAgcEnabled:is3AEnabled];
        }

        [[TRTCCloud sharedInstance] setDefaultStreamRecvMode:self.audioRecvModeItem.selectedIndex == 0 video:self.videoRecvModeItem.selectedIndex == 0];
        if (self.audioModeItem.selectedIndex < 2) {
            int fast_mode_enable = 1;
            switch (self.audioModeItem.selectedIndex) {
                case 0:
                    fast_mode_enable = 1;
                    break;
                case 1:
                    fast_mode_enable = 0;
                    break;
                default:
                    break;
            }
            NSDictionary *json       = @{@"api" : @"enableRealtimeChorus", @"params" : @{@"enable" : @(fast_mode_enable)}};
            NSString *    jsonString = [self jsonStringFrom:json];
            [[TRTCCloud sharedInstance] callExperimentalAPI:jsonString];
        }

        TRTCVideoSource subVideoSource = self.subVideoInputItem.selectedIndex == 0 ? TRTCVideoSourceNone : self.subVideoInputItem.selectedIndex;
        [self.cloudManager.videoConfig setSubSource:subVideoSource];
        
        if (subVideoSource == TRTCVideoSourceCustom) {
            [self.cloudManager.videoConfig setVideoAsset:_customSourceAsset];
        }

        if (subVideoSource != TRTCVideoSourceNone) {
            self.cloudManager.videoConfig.isSmallVideoEnabled      = YES;
            self.cloudManager.videoConfig.isCustomSubStreamCapture = YES;
        } else {
            self.cloudManager.videoConfig.isSmallVideoEnabled      = NO;
            self.cloudManager.videoConfig.isCustomSubStreamCapture = NO;
        }
        [self.cloudManager enableHEVCEncode:self.videoCodecItem.selectedIndex == 1];
        self.cloudManager.remoteUserManager = remoteManager;
    }
}

- (NSString *)jsonStringFrom:(NSDictionary *)dict {
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:NULL];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

- (void)setupListItems {
    @weakify(self)
    NSMutableArray *items   = [NSMutableArray array];
    self.envItem            = [[TRTCSettingsSegmentItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.cloudEv") items:@[TRTCLocalize(@"Demo.TRTC.Live.product"), TRTCLocalize(@"Demo.TRTC.Live.test"), TRTCLocalize(@"Demo.TRTC.Live.experience")]selectedIndex:0 action:nil];

    NSString *rid           = [NSString stringWithFormat:@"%ld",(long)(arc4random() % 100000)];
    self.roomItem           = [[TRTCSettingsLargeInputItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.inputRoomId") placeHolder:rid];
    self.roomItem.maxLength = 10;
    
    NSString *name          = [NSString stringWithFormat:@"%ld",(long)(arc4random() % 100000)];
    self.nameItem           = [[TRTCSettingsLargeInputItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.inputUserId") placeHolder:name];
    self.nameItem.maxLength = 40;

    self.cryptKeyItem = [[TRTCSettingsLargeInputItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.password") placeHolder:@""];

    self.roleItem = [[TRTCSettingsSegmentItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.switchRole")
                                                             items:@[ TRTCLocalize(@"Demo.TRTC.Live.anchor"), TRTCLocalize(@"Demo.TRTC.Live.adudience") ]
                                                     selectedIndex:0
                                                            action:^(NSInteger index) {
                                                                @strongify(self)
                                                                [self.cloudManager setRole:index + TRTCRoleAnchor];
                                                            }];
    // 不同平台可能不支持
    NSMutableArray *options;
    if (_useCppWrapper) {
        // C++全平台接口不支持录屏
        options = [@[ TRTCLocalize(@"Demo.TRTC.Live.videoInput"), TRTCLocalize(@"Demo.TRTC.Live.camera") ] mutableCopy];
    } else {
        options = [@[ TRTCLocalize(@"Demo.TRTC.Live.camera"), TRTCLocalize(@"Demo.TRTC.Live.mediaFile"), TRTCLocalize(@"Demo.TRTC.Live.deviceAppCapture") ] mutableCopy];
        if (@available(iOS 11, *)) {
            [options addObject:TRTCLocalize(@"Demo.TRTC.Live.deviceCapture")];
        }
    }

    self.mainVideoInputItem = [[TRTCSettingsSegmentItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.videoInput")
                                                                       items:options
                                                               selectedIndex:0
                                                                      action:^(NSInteger index) {
        @strongify(self)
        [self.cloudManager setVideoInputType:index];
    }];

    options = [@[ TRTCLocalize(@"Demo.TRTC.Live.none"), TRTCLocalize(@"Demo.TRTC.Live.mediaFile"), TRTCLocalize(@"Demo.TRTC.Live.deviceAppCapture") ] mutableCopy];
    if (@available(iOS 11, *)) {
        [options addObject:TRTCLocalize(@"Demo.TRTC.Live.deviceCapture")];
    }

    self.subVideoInputItem = [[TRTCSettingsSegmentItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.Auxiliary") items:options selectedIndex:0 action:^(NSInteger index) {
        @strongify(self)
        [self.cloudManager setSubVideoInputType:index];
    }];

    self.audioInputItem = [[TRTCSettingsSegmentItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.autioInput")
                                                                   items:@[
                                                                       TRTCLocalize(@"Demo.TRTC.Live.sdkCapture"),
                                                                       TRTCLocalize(@"Demo.TRTC.Live.customCapture"),
                                                                       TRTCLocalize(@"Demo.TRTC.Live.none"),
                                                                   ]
                                                           selectedIndex:0
                                                                  action:^(NSInteger index) {
                                                                      @strongify(self)
                                                                      [self.cloudManager setAudioInputType:index];
                                                                  }];

    self.volumeType = [[TRTCSettingsSegmentItem alloc]
                       initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.audioType")
                       items:@[ TRTCLocalize(@"Demo.TRTC.Live.audioTypeAuto"), TRTCLocalize(@"Demo.TRTC.Live.audioTypeMedia"), TRTCLocalize(@"Demo.TRTC.Live.audioTypeCalling"),
                                TRTCLocalize(@"Demo.TRTC.Live.notChoose")]
                       selectedIndex:0
                       action:^(NSInteger index) {
                                @strongify(self)
                                //index = 3 (不选)
                                if (index == 3) {
                                    [self.cloudManager setVolumeType:-1];
                                } else {
                                    [self.cloudManager setVolumeType:index];
                                }
               }];

    self.soundsType = [[TRTCSettingsSegmentItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.audioOutput")
                                                               items:@[ TRTCLocalize(@"Demo.TRTC.Live.speaker"), TRTCLocalize(@"Demo.TRTC.Live.earPhone") ]
                                                       selectedIndex:0
                                                              action:^(NSInteger index) {
                                                                  @strongify(self)
                                                                  [self.cloudManager setAudioRoute:index];
                                                              }];

    self.audioQualityItem = [[TRTCSettingsSegmentItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.audioQuality")
                                                                     items:@[ TRTCLocalize(@"Demo.TRTC.Live.talk"), TRTCLocalize(@"Demo.TRTC.Live.default"), TRTCLocalize(@"Demo.TRTC.Live.music"),
                                                                     TRTCLocalize(@"Demo.TRTC.Live.notChoose")]
                                                             selectedIndex:1
                                                                    action:^(NSInteger index) {
                                                                        @strongify(self)
                                                                        //index = 3 (不选)
                                                                        if (index == 3) {
                                                                            //-1 位无效值
                                                                            [self.cloudManager setAudioQuality:-1];
                                                                        } else {
                                                                            [self.cloudManager setAudioQuality:index + TRTCAudioQualitySpeech];
                                                                        }
                                                                    }];

    self.roomIdTypeItem = [[TRTCSettingsSegmentItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.roomType")
                                                                   items:@[ TRTCLocalize(@"Demo.TRTC.Live.int"), TRTCLocalize(@"Demo.TRTC.Live.string") ]
                                                           selectedIndex:0
                                                                  action:^(NSInteger index) {
                                                                      @strongify(self)
                                                                      [self.cloudManager setRoomIdType:index];
                                                                  }];

    self.videoCodecItem    = [[TRTCSettingsSegmentItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.encoderType") items:@[ @"264", @"265" ] selectedIndex:1 action:nil];
    
    self.videoEncoderTypeItem = [[TRTCSettingsSegmentItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.codecType") items:@[TRTCLocalize(@"Demo.TRTC.Live.codecTypeSoft"), TRTCLocalize(@"Demo.TRTC.Live.codecTypeHard")] selectedIndex:1 action:nil];

    self.audioModeItem     = [[TRTCSettingsSegmentItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.audioScene")
                                                                  items:@[ TRTCLocalize(@"Demo.TRTC.Live.chorus"), TRTCLocalize(@"Demo.TRTC.Live.normal") ]
                                                          selectedIndex:1
                                                                     action:^(NSInteger index){
        @strongify(self)
        self.cloudManager.enableChorus = !index;
        if(index == 0) {
            self.chorusCdnUrlItem = [[TRTCSettingsLargeInputItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.inputUrl")
                                                                           placeHolder:TRTCLocalize(@"Demo.TRTC.Live.inputUrl")];
            self.chorusCdnUrlItem.maxLength = 250;
            [self.items insertObject:self.chorusCdnUrlItem atIndex:[self.items indexOfObject:self.audioModeItem] + 1];
        } else {
            [self.items removeObjectIdenticalTo:self.chorusCdnUrlItem];
        }
        [self.tableView reloadData];
    }];

    self.audio3AItem       = [[TRTCSettingsSegmentItem alloc] initWithTitle:@"3A"
                                                                items:@[ TRTCLocalize(@"Demo.TRTC.Live.close"), TRTCLocalize(@"Demo.TRTC.Live.open"), TRTCLocalize(@"Demo.TRTC.Live.notChoose") ]
                                                        selectedIndex:2
                                                               action:nil];
    self.audioRecvModeItem = [[TRTCSettingsSegmentItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.audioReceive")
                                                                      items:@[ TRTCLocalize(@"Demo.TRTC.Live.auto"), TRTCLocalize(@"Demo.TRTC.Live.manual") ]
                                                              selectedIndex:0
                                                                     action:nil];
    self.videoRecvModeItem = [[TRTCSettingsSegmentItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.videoReceive")
                                                                      items:@[ TRTCLocalize(@"Demo.TRTC.Live.auto"), TRTCLocalize(@"Demo.TRTC.Live.manual") ]
                                                              selectedIndex:0
                                                                     action:nil];
    self.audioParallelMaxCountItem = [[TRTCSettingsMessageItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.audioParallelMaxCount")
                                                                placeHolder:TRTCLocalize(@"")
                                                                    content:nil
                                                                actionTitle:TRTCLocalize(@"Demo.TRTC.Meeting.setting")
                                                                     action:^(NSString *count) {
            UInt32 maxCount = [count intValue];
            [self.cloudManager setRemoteAudioParallelParams:maxCount];
        }];

    if (DEBUGSwitch) {
    items = [@[
             self.roomItem, self.nameItem, self.cryptKeyItem, self.roleItem, self.envItem, self.mainVideoInputItem, self.subVideoInputItem,
             self.videoCodecItem, self.audioModeItem, self.videoEncoderTypeItem, self.audioInputItem,
             self.volumeType, self.soundsType, self.audioQualityItem, self.audio3AItem, self.audioRecvModeItem, self.videoRecvModeItem,
             self.roomIdTypeItem, self.audioParallelMaxCountItem ] mutableCopy];
    } else {
        items =
            [@[ self.roomItem, self.nameItem, self.roleItem, self.mainVideoInputItem, self.audioInputItem, self.volumeType, self.soundsType,
                self.audioQualityItem, self.roomIdTypeItem, self.audioParallelMaxCountItem ] mutableCopy];
    }

    self.items = items;
}

- (float)heightForString:(UITextView *)textView andWidth:(float)width {
    CGSize sizeToFit = [textView sizeThatFits:CGSizeMake(width, MAXFLOAT)];
    return sizeToFit.height;
}

- (void)toastTip:(NSString *)toastInfo time:(NSInteger)time {
    @weakify(self)
    dispatch_async(dispatch_get_main_queue(), ^{
        @strongify(self)
        UITextView *toastViewTmp = self.toastView;
        [toastViewTmp removeFromSuperview];

        CGRect frameRC   = [[UIScreen mainScreen] bounds];
        frameRC.origin.y = frameRC.size.height - 110;
        frameRC.size.height -= 110;
        frameRC.size.height = [self heightForString:toastViewTmp andWidth:frameRC.size.width];

        toastViewTmp.frame = frameRC;

        toastViewTmp.text            = toastInfo;
        toastViewTmp.backgroundColor = [UIColor whiteColor];
        toastViewTmp.alpha           = 0.5;

        [self.view addSubview:toastViewTmp];

        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, time * NSEC_PER_SEC);

        dispatch_after(popTime, dispatch_get_main_queue(), ^() {
            [toastViewTmp removeFromSuperview];
        });
    });
}

- (void)showMeidaPicker {
    QBImagePickerController *imagePicker    = [[QBImagePickerController alloc] init];
    imagePicker.delegate                    = self;
    imagePicker.allowsMultipleSelection     = YES;
    imagePicker.showsNumberOfSelectedAssets = YES;
    imagePicker.minimumNumberOfSelection    = 1;
    imagePicker.maximumNumberOfSelection    = 1;
    imagePicker.mediaType                   = QBImagePickerMediaTypeVideo;
    imagePicker.title                       = TRTCLocalize(@"Demo.TRTC.Live.videoSource");

    [self.navigationController pushViewController:imagePicker animated:YES];
}

#pragma mark - Actions

- (void)onSpeedTestBtnClick:(UIButton *)button {
    button.selected = !button.selected;
    if (_isSpeedTesting) {
        [_cloudManager stopSpeedTest];
        _isSpeedTesting = false;
        return;
    }
    @weakify(self)
    NSString *userId = self.nameItem.content.length == 0 ? self.nameItem.placeHolder : self.nameItem.content;
    [_cloudManager startSpeedTest:userId
                       completion:^(TRTCSpeedTestResult *result, NSInteger completedCount, NSInteger totalCount) {
                           @strongify(self)
                           [self toastTip:[result description] time:3];
                           if (completedCount == totalCount) {
                               self.isSpeedTesting = false;
                               button.selected     = !button.selected;
                           }
                       }];
    _isSpeedTesting = true;
}

- (void)onEnterRoomBtnClick:(UIButton *)button {
    if (self.isLoadingFile) {
        return;
    }

    if (self.mainVideoInputItem.selectedIndex == 1 || self.subVideoInputItem.selectedIndex == 1) {
        [self showMeidaPicker];
    } else {
        [self startLive];
    }
}

- (void)startLive {
    NSString *userId = self.nameItem.content.length == 0 ? self.nameItem.placeHolder : self.nameItem.content;
    NSString *roomId = self.roomItem.content.length == 0 ? self.roomItem.placeHolder : self.roomItem.content;

    
    NSCharacterSet *set = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString *trimmedStr = [roomId stringByTrimmingCharactersInSet:set];
    if (!trimmedStr.length) {
        [self toastTip:@"invalid roomId" time:2];
        return;
    }
    roomId = trimmedStr;
    if (self.cloudManager.roomIdType == TRTCIntRoomId) {
        if (![self isPureInt:roomId]) {
            [self toastTip:@"invalid roomId" time:2];
            return;
        }
    }

    [self setupConfig];

    if (self.roleItem.selectedIndex == 0) {
        _cloudManager.userId                 = userId;
        _cloudManager.roomId                 = roomId;
        _cloudManager.params.role            = TRTCRoleAnchor;
        TRTCLiveAnchorViewController *liveVC = [TRTCLiveAnchorViewController initWithTRTCCloudManager:_cloudManager];
        [self.navigationController pushViewController:liveVC animated:YES];
    } else {
        _cloudManager.params.role              = TRTCRoleAudience;
        _cloudManager.userId                   = userId;
        _cloudManager.roomId                   = roomId;
        TRTCLiveAudienceViewController *liveVC = [TRTCLiveAudienceViewController initWithTRTCCloudManager:_cloudManager];
        if (!_cloudManager.enableChorus) {
            [_cloudManager enterLiveRoom:roomId userId:userId];
        }
        [self.navigationController pushViewController:liveVC animated:YES];
    }
}

#pragma mark - QBIamgePicker Delegate

- (void)qb_imagePickerController:(QBImagePickerController *)imagePickerController didFinishPickingAssets:(NSArray *)assets {
    [self.navigationController popViewControllerAnimated:YES];
    PHVideoRequestOptions *options = [PHVideoRequestOptions new];
    options.deliveryMode           = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
    options.networkAccessAllowed   = YES;

    __weak __typeof(self) weakSelf = self;
    options.progressHandler        = ^(double progress, NSError *_Nullable error, BOOL *_Nonnull stop, NSDictionary *_Nullable info) {
        NSString *process = [[NSString alloc] initWithFormat:@"%@ %d%%", TRTCLocalize(@"Demo.TRTC.Live.progress"), (int)(progress * 100)];
        [weakSelf toastTip:process time:2];
    };

    self.isLoadingFile = true;
    [[PHImageManager defaultManager] requestAVAssetForVideo:assets.firstObject
                                                    options:options
                                              resultHandler:^(AVAsset *_Nullable avAsset, AVAudioMix *_Nullable audioMix, NSDictionary *_Nullable info) {
                                                  weakSelf.customSourceAsset              = avAsset;
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

- (void)dealloc
{
    NSLog(@"TRTCLiveEnterViewController dealloc");
}
@end
