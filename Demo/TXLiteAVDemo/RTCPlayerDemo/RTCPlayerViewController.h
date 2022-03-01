//
//  RTCPlayerViewController.h
//  TXLiteAVDemo
//
//  Created by adams on 2021/7/22.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "V2TXLivePlayer.h"

NS_ASSUME_NONNULL_BEGIN

@interface RTCPlayerViewController : UIViewController

@property(nonatomic, strong, readonly) V2TXLivePlayer *player;
@property(nonatomic, strong) NSString *                url;
@property(nonatomic, assign) BOOL                      muteVideo;
@property(nonatomic, assign) BOOL                      muteAudio;
@property(nonatomic, strong) dispatch_block_t          onStatusUpdate;
@property(nonatomic, strong, readonly) NSString *      userId;
@property(nonatomic, assign) BOOL                      isLoading;

- (V2TXLiveCode)startPlay;
- (V2TXLiveCode)stopPlay;

@end

NS_ASSUME_NONNULL_END
