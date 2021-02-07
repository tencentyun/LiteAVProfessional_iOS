//
//  V2MainItemCell.h
//  TXLiteAVDemo
//
//  Created by coddyliu on 2020/11/27.
//  Copyright © 2020 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "V2TXLivePlayer.h"
#import "V2TXLivePusher.h"

NS_ASSUME_NONNULL_BEGIN

@class V2MainViewController;
@interface V2MainItemCell : UICollectionViewCell
@property (nonatomic, assign) BOOL isBusy; // being pushing or playing
@property (nonatomic, weak) V2MainViewController *delegate;
@property (nonatomic, strong) void (^onSetUrlBtnClick)(V2MainItemCell *cell);

- (void)onViewControllerDidAppear:(UIViewController *)viewController;
///url 推流/拉流地址  playUrls：cdn自动生成推流地址时才有
- (void)startWithUrl:(NSString *)url playUrls:(NSDictionary * _Nullable)playUrls;
@end

@class V2PusherViewController;
@interface V2MainItemPushCell : V2MainItemCell
@property (nonatomic, strong) V2PusherViewController *relateVC;
- (void)setPusherMode:(V2TXLiveMode)mode;
@end

@class V2PlayerViewController;
@interface V2MainItemPlayCell : V2MainItemCell
@property (nonatomic, strong) V2PlayerViewController *relateVC;
- (void)stopPlay;
@end

NS_ASSUME_NONNULL_END
