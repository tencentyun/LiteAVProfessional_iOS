//
//  V2QRScanViewController.h
//  TXLiteAVDemo
//
//  Created by coddyliu on 2020/12/5.
//  Copyright © 2020 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ScanQRDelegate <NSObject>
- (void)onScanResult:(NSString *)result;
@end

@interface V2QRScanViewController : UIViewController {
    BOOL                        _qrResult;
    AVCaptureSession *          _captureSession;
    AVCaptureVideoPreviewLayer *_videoPreviewLayer;
}
@property (nonatomic, weak) id<ScanQRDelegate> delegate;
@property (nonatomic, retain) UITextField* textField;

@end

NS_ASSUME_NONNULL_END
