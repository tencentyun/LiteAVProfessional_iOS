//
//  LoginViewController.h
//  TXLiteAVDemo
//
//  Created by peterwtma on 2021/7/21.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
/**
 *协议文本
 */
@interface TRTCLoginAgreementTextView : UITextView

@end


@interface LoginViewController : UIViewController
@property (nonatomic, strong, readonly) UIActivityIndicatorView *loading;
@property (nonatomic, assign, readonly) BOOL phoneNumberVaild;
/// 输入框背景.
@property (nonatomic, strong) UIImageView *inputBackImage;
/// 同意按钮.
@property (nonatomic, strong) UIButton *agreementBtn;
/// 同意协议
@property (nonatomic, strong) TRTCLoginAgreementTextView *agreementTextView;

- (void)loginSucc;

- (NSMutableAttributedString*)setTextFieldAttribute:(NSString*)text;

@end



NS_ASSUME_NONNULL_END
