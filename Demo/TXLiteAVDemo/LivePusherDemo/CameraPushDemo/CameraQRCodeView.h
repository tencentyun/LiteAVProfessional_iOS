//
//  CameraQRCodeView.h
//  TXLiteAVDemo
//
//  Created by adams on 2021/7/22.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface                             CameraQRCodeModel : NSObject
@property(nonatomic, strong) NSString *title;
@property(nonatomic, strong) NSString *link;
@property(nonatomic, assign) BOOL      selected;
@property(nonatomic, strong) UIImage * qrImage;
@end

@interface CameraQRCodeView : UIView
- (void)loadStreamData:(NSDictionary *)streamDictionary;
- (void)hide;
- (void)show;
@end

@interface                                      CameraQRCodeCell : UICollectionViewCell
@property(nonatomic, strong) CameraQRCodeModel *qrCodeModel;
@end

NS_ASSUME_NONNULL_END
