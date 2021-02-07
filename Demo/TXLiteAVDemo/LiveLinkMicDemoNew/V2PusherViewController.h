//
//  V2PusherViewController.h
//  TXLiteAVDemo
//
//  Created by coddyliu on 2020/11/26.
//  Copyright © 2020 Tencent. All rights reserved.
//

#import "V2SettingsBaseViewController.h"
#import "V2TXLivePusher.h"

NS_ASSUME_NONNULL_BEGIN

@class V2TXLivePusher;
//@class TXView;
@interface V2PusherViewController : V2SettingsBaseViewController
@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong, readonly) V2TXLivePusher *pusher;
@property (nonatomic, strong) UIView *smallPreView;
@property (nonatomic, assign) BOOL muteVideo;
@property (nonatomic, assign) BOOL muteAudio;
@property (nonatomic, assign) BOOL usefrontCamera;
@property (nonatomic, strong) NSString *playUrl;
@property (nonatomic, strong) dispatch_block_t onStatusUpdate;
- (void)setPusherMode:(int)mode;
- (instancetype)initWithUrl:(NSString *)url;

- (V2TXLiveCode)startPush;
- (void)stopPush;
@end

NS_ASSUME_NONNULL_END
