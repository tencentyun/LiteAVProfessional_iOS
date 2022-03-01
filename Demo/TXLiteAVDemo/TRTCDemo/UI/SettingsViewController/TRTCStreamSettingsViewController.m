/*
 * Module:   TRTCStreamSettingsViewController
 *
 * Function: 混流设置页
 *
 *    1. 通过TRTCCloudManager来开启关闭云端混流。
 *
 *    2. 显示房间的直播地址二维码。
 *
 */

#import "TRTCStreamSettingsViewController.h"

#import "AppLocalized.h"
#import "ColorMacro.h"
#import "MBProgressHUD.h"
#import "Masonry.h"
#import "NSString+Common.h"
#import "QRCode.h"
#import "TCUtil.h"
#import "UIButton+TRTC.h"

@interface TRTCStreamSettingsViewController ()

@property(strong, nonatomic) UIImageView *qrCodeView;
@property(strong, nonatomic) UILabel *    qrCodeTitle;
@property(strong, nonatomic) UIButton *   button;

@property(strong, nonatomic) TRTCSettingsSegmentItem *mixedFlowItem;
@property(strong, nonatomic) TRTCSettingsSegmentItem *backgroundImageItem;
@property(strong, nonatomic) TRTCSettingsMessageItem *mixedFlowIDItem;

@end

@implementation TRTCStreamSettingsViewController

- (NSString *)title {
    return TRTCLocalize(@"Demo.TRTC.Live.stream");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (DEBUGSwitch) {
        TRTCStreamConfig *    config = self.trtcCloudManager.streamConfig;
        __weak __typeof(self) wSelf  = self;
        self.mixedFlowItem           = [[TRTCSettingsSegmentItem alloc]
            initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.cloudMixedStream")
                    items:@[ TRTCLocalize(@"Demo.TRTC.Live.close"), TRTCLocalize(@"Demo.TRTC.Live.manual"), TRTCLocalize(@"Demo.TRTC.Live.audioOnly"), TRTCLocalize(@"Demo.TRTC.Live.preset") ]
            selectedIndex:config.mixMode
                   action:^(NSInteger index) {
                       [wSelf onSelectMixModeIndex:index];
                   }];
        self.backgroundImageItem =
            [[TRTCSettingsSegmentItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.backgroundImage")
                                                     items:@[ TRTCLocalize(@"Demo.TRTC.Live.none"), TRTCLocalize(@"Demo.TRTC.Live.picOne"), TRTCLocalize(@"Demo.TRTC.Live.picTwo") ]
                                             selectedIndex:0
                                                    action:^(NSInteger index) {
                                                        [wSelf onSelectBackgroundImage:index];
                                                    }];

        self.mixedFlowIDItem = [[TRTCSettingsMessageItem alloc] initWithTitle:TRTCLocalize(@"Demo.TRTC.Live.MixedStreamID")
                                                                  placeHolder:TRTCLocalize(@"Demo.TRTC.Live.CustomStreamID")
                                                                      content:nil
                                                                  actionTitle:TRTCLocalize(@"Demo.TRTC.Live.setting")
                                                                       action:^(NSString *content) {
                                                                           [wSelf setMixStreamId:content];
                                                                       }];
        self.items           = [@[
            self.mixedFlowItem,
            self.backgroundImageItem,
            self.mixedFlowIDItem,
        ] mutableCopy];
    }
    [self setupSubviews];
    [self updateStreamInfo];
}

- (void)setupSubviews {
    [self.tableView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.trailing.equalTo(self.view);
        make.height.mas_equalTo(self.items.count * 50);
    }];

    self.qrCodeTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 20)];

    self.qrCodeTitle.text      = TRTCLocalize(@"Demo.TRTC.Live.streamUrl");
    self.qrCodeTitle.textColor = UIColorFromRGB(0x999999);
    [self.view addSubview:self.qrCodeTitle];

    self.qrCodeView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background"]];
    [self.view addSubview:_qrCodeView];

    [self.qrCodeTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.tableView.mas_bottom).offset(20);
        make.centerX.mas_equalTo(0);
    }];

    [self.qrCodeView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.qrCodeTitle).offset(30);
        make.leading.equalTo(self.view).offset(100);
        make.trailing.equalTo(self.view).offset(-100);
        make.height.mas_equalTo(self.qrCodeView.mas_width);
    }];

    self.button = [UIButton trtc_cellButtonWithTitle:TRTCLocalize(@"Demo.TRTC.Live.copy")];
    [self.view addSubview:self.button];
    [self.button addTarget:self action:@selector(onClickShareButton:) forControlEvents:UIControlEventTouchDown];
    [self.button setHighlighted:NO];

    [self.button mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.qrCodeView.mas_bottom).offset(20);
        make.width.mas_equalTo(100);
        make.height.mas_equalTo(40);
        make.centerX.mas_equalTo(0);
    }];
}

#pragma mark - Actions

- (void)onSelectMixModeIndex:(NSInteger)index {
    [self.trtcCloudManager setMixMode:index];
    [self updateStreamInfo];
}

- (void)onSelectBackgroundImage:(NSInteger)index {
    if (index == 0) {
        [self.trtcCloudManager setMixBackgroundImage:nil];
    } else {
        NSString *imageName = @[ @"51", @"52" ][index - 1];
        [self.trtcCloudManager setMixBackgroundImage:imageName];
    }
}

- (void)setMixStreamId:(NSString *)streamId {
    [self.trtcCloudManager setMixStreamId:streamId];
}

- (IBAction)onClickShareButton:(UIButton *)button {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string        = [self.trtcCloudManager getCdnUrlOfUser:self.trtcCloudManager.userId];
    MBProgressHUD *hud       = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode                 = MBProgressHUDModeText;
    hud.label.text           = TRTCLocalize(@"Demo.TRTC.Live.urlAlreadyCopy");
    [hud showAnimated:YES];
    [hud hideAnimated:YES afterDelay:1];
}

- (void)updateStreamInfo {
    NSString *shareUrl    = [self.trtcCloudManager getCdnUrlOfUser:self.trtcCloudManager.userId];
    self.qrCodeView.image = [QRCode qrCodeWithString:shareUrl size:self.qrCodeView.frame.size];
}

@end
