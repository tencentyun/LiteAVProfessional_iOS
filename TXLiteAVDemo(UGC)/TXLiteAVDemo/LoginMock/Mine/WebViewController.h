//
//  WebViewController.h
//  TXLiteAVDemo
//
//  Created by peterwtma on 2021/7/21.
//  Copyright © 2021 Tencent. All rights reserved.
//
#import <UIKit/UIKit.h>

@interface WebViewController : UIViewController
- (instancetype)initWithUrlString:(NSString*)urlString
                  withTitleString:(NSString*)titleString;
@end

