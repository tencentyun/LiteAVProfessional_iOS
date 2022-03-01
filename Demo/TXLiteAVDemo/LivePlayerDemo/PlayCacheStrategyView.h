//
//  PlayCacheStrategyView.h
//  TXLiteAVDemo_Enterprise
//
//  Created by gg on 2021/8/24.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PlayCacheStrategyView : UIView

@property (nonatomic, copy) NSArray <NSString *>*dataSource;

@property (nonatomic, copy) NSString *titleText;

@property (nonatomic, copy) NSString *closeText;

@property (nonatomic, assign) NSInteger selectIndex;

@property (nonatomic, copy) void(^didSelectIndex)(NSInteger index);

- (void)show;

- (void)dismiss;

@end

NS_ASSUME_NONNULL_END
