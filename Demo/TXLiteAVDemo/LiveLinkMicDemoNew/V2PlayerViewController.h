//
//  TRTCV2PlayerViewController.h
//  TXLiteAVDemo
//
//  Created by coddyliu on 2020/11/25.
//  Copyright © 2020 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "V2SettingsBaseViewController.h"
#import "V2TXLivePlayer.h"

NS_ASSUME_NONNULL_BEGIN

@interface                                             V2PlayerViewController : V2SettingsBaseViewController
@property(nonatomic, strong, readonly) V2TXLivePlayer *player;
@property(nonatomic, strong) NSString *                url;
@property(nonatomic, strong) UIView *                  smallPreView;
@property(nonatomic, assign) BOOL                      muteVideo;
@property(nonatomic, assign) BOOL                      muteAudio;
@property(nonatomic, strong) dispatch_block_t          onStatusUpdate;
@property(nonatomic, strong, readonly) NSString *      userId;
@property(nonatomic, assign) BOOL                      isLoading;
- (V2TXLiveCode)startPlay;
- (V2TXLiveCode)stopPlay;
@end

NS_ASSUME_NONNULL_END
