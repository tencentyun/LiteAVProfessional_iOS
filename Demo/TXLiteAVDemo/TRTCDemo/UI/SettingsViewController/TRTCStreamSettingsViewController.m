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
#import "UIButton+TRTC.h"
#import "NSString+Common.h"
#import "QRCode.h"
#import "MBProgressHUD.h"
#import "Masonry.h"
#import "ColorMacro.h"
#import "AppLocalized.h"

@interface TRTCStreamSettingsViewController ()

@property (strong, nonatomic) UIImageView *qrCodeView;
@property (strong, nonatomic) UILabel *qrCodeTitle;
@property (strong, nonatomic) UIButton *button;

@end

@implementation TRTCStreamSettingsViewController

- (NSString *)title {
    return TRTCLocalize(@"Demo.TRTC.Live.stream");
}

- (void)viewDidLoad {
    [super viewDidLoad];
            
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setupSubviews];
        [self updateStreamInfo];
    });
}

- (void)setupSubviews {
    [self.tableView setHidden:true];
    
    self.qrCodeTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 20)];
    self.qrCodeTitle.text = TRTCLocalize(@"Demo.TRTC.Live.streamUrl");
    self.qrCodeTitle.textColor = UIColorFromRGB(0x999999);
    [self.view addSubview:self.qrCodeTitle];
    
    self.qrCodeView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background"]];
    [self.view addSubview:_qrCodeView];
    
    [self.qrCodeTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(20);
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

- (IBAction)onClickShareButton:(UIButton *)button {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = [self.trtcCloudManager getCdnUrlOfUser:self.trtcCloudManager.userId];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.label.text = TRTCLocalize(@"Demo.TRTC.Live.urlAlreadyCopy");
    [hud showAnimated:YES];
    [hud hideAnimated:YES afterDelay:1];
}

- (void)updateStreamInfo {
    NSString *shareUrl = [self.trtcCloudManager getCdnUrlOfUser:self.trtcCloudManager.userId];
    self.qrCodeView.image = [QRCode qrCodeWithString:shareUrl size:self.qrCodeView.frame.size];
}

@end
