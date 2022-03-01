//
//  TRTCLoginAlertView.h
//  TXLiteAVDemo_Enterprise
//
//  Created by peterwtma on 2021/7/26.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
//ContryModel
@interface TRTCLoginCountryModel : NSObject
@property (nonatomic, strong) NSString *code;
@property (nonatomic, strong) NSString *displayEN;
@property (nonatomic, strong) NSString *displayZH;
@property (nonatomic, strong) NSString *displayTitle;
@property (nonatomic, strong) NSString *countryName;
+ (NSMutableArray*)getLoginCountryList;
@end

@interface TRTCLoginAlertContextView : UIView
@property (nonatomic, copy) void(^willDissmiss)(void);
@property (nonatomic, copy) void(^didDismiss)(void);
- (void)show;
- (void)dismiss;
@end

//弹出的UIView
@interface TRTCLoginCountryAlert : TRTCLoginAlertContextView
@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) void(^didSelect)(TRTCLoginCountryModel* model);
@end
NS_ASSUME_NONNULL_END
