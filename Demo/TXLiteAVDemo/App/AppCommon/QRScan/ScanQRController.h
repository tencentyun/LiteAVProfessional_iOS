//
//  ScanQRController.h
//  RTMPiOSDemo
//
//  Created by 蓝鲸 on 16/4/1.
//  Copyright © 2016年 tencent. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@protocol ScanQRDelegate <NSObject>

- (void)onScanResult:(NSString *)result;
- (void)cancelScanQR;

@end

@interface ScanQRController : UIViewController {
    BOOL                        _qrResult;
    AVCaptureSession *          _captureSession;
    AVCaptureVideoPreviewLayer *_videoPreviewLayer;
}

@property(nonatomic, weak) id<ScanQRDelegate> delegate;
@property(nonatomic, retain) UITextField *    textField;

@end
