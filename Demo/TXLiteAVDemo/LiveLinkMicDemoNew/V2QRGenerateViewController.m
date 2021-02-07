//
//  V2QRGenerateViewController.m
//  TXLiteAVDemo_Enterprise
//
//  Created by coddyliu on 2020/7/23.
//  Copyright © 2020 Tencent. All rights reserved.
//

#import "V2QRGenerateViewController.h"
#import "MBProgressHUD.h"

//#define L(x) NSLocalizedString(x, nil)

@interface V2QRGenerateViewController ()
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIImageView *qrcodeImageView;
@property (weak, nonatomic) IBOutlet UIButton *qrcodeCopyBtn;
@property(nonatomic, strong) NSString *currentPlayURL;
@property(nonatomic, strong) NSDictionary *playTypeButtons;

@end

@implementation V2QRGenerateViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapGesture:)];
    [self.view addGestureRecognizer:tap];
    
    for (UIButton *btn in self.playTypeButtons.allValues) {
        btn.titleLabel.lineBreakMode = NSLineBreakByClipping;
    }
    self.qrcodeCopyBtn.titleLabel.lineBreakMode = NSLineBreakByClipping;
    [self showQRCodeContent];
}

- (void)onTapGesture:(UITapGestureRecognizer *)tap {
    if (CGRectContainsPoint(self.contentView.frame, [tap locationInView:self.view])) {
        return;
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)showQRCodeContent {
    dispatch_async(dispatch_get_main_queue(),^{
        self.currentPlayURL = self.playURL;
        if (self.currentPlayURL.length == 0) {
            self.qrcodeImageView.image = nil;
        } else {
            CGSize size = self.qrcodeImageView.bounds.size;
            size.width *= 2;
            size.height *= 2;
            self.qrcodeImageView.image = [V2QRGenerateViewController qrCodeWithString:self.currentPlayURL size:size];
        }
    });
}

#pragma mark - actions

- (IBAction)onQRCodeCopy:(UIButton *)sender {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = self.currentPlayURL;
    [self showText:@"已添加至剪切板"];
}
- (IBAction)onClosePage:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


+ (UIImage *)qrCodeWithString:(NSString *)string size:(CGSize)outputSize
{
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    [filter setValue:data forKey: @"inputMessage"];
    [filter setValue:@"Q" forKey: @"inputCorrectionLevel"];
    CIImage *qrCodeImage = filter.outputImage;
    CGRect imageSize = CGRectIntegral(qrCodeImage.extent);
    CIImage *ciImage = [qrCodeImage imageByApplyingTransform:CGAffineTransformMakeScale(outputSize.width/CGRectGetWidth(imageSize), outputSize.height/CGRectGetHeight(imageSize))];
    return [UIImage imageWithCIImage:ciImage];
}

- (void)showText:(NSString *)text {
    [self showText:text withDetailText:nil];
}

- (void)showText:(NSString *)text withDetailText:(NSString *)detail {
    MBProgressHUD *hud = [self getHud];
    hud.mode = MBProgressHUDModeText;
    hud.label.text = text;
    hud.detailsLabel.text = detail;
    [hud.button addTarget:self action:@selector(onCloseHUD:) forControlEvents:UIControlEventTouchUpInside];
    [hud.button setTitle:@"关闭" forState:UIControlStateNormal];
    [hud showAnimated:YES];
    [hud hideAnimated:YES afterDelay:2];
}

- (MBProgressHUD *)getHud {
    MBProgressHUD *hud = [MBProgressHUD HUDForView:self.view];
    if (hud == nil) {
        hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    }
    return hud;
}

- (void)onCloseHUD:(id)sender {
    [[MBProgressHUD HUDForView:self.view] hideAnimated:YES];
}

@end
