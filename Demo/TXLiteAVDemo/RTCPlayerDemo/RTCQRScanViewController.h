//
//  RTCQRScanViewController.h
//  TXLiteAVDemo
//
//  Created by adams on 2020/7/22.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ScanQRDelegate <NSObject>
- (void)onScanResult:(NSString *)result;
@end

@interface RTCQRScanViewController : UIViewController {
    BOOL                        _qrResult;
    AVCaptureSession *          _captureSession;
    AVCaptureVideoPreviewLayer *_videoPreviewLayer;
}

@property(nonatomic, weak) id<ScanQRDelegate> delegate;
@property(nonatomic, retain) UITextField *    textField;

@end

NS_ASSUME_NONNULL_END
