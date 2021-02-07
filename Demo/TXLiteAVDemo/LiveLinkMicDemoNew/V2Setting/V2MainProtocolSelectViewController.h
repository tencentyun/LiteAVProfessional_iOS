//
//  V2MainProtocolSelectViewController.h
//  TXLiteAVDemo
//
//  Created by coddyliu on 2020/12/5.
//  Copyright © 2020 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface V2MainProtocolSelectViewController : UIViewController
@property (nonatomic, assign) BOOL isPush;
@property (nonatomic, strong) void (^onStart)(V2MainProtocolSelectViewController *vc, NSString *pushUrl, NSDictionary *playUrls, BOOL isPush);
@end

NS_ASSUME_NONNULL_END
