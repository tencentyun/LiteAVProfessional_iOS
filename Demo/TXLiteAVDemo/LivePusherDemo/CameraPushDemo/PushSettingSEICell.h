//
//  PushSettingSEICell.h
//  TXLiteAVDemo
//
//  Created by leiran on 2021/10/12.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class PushSettingSEICell;
@protocol PushSettingSEICellDelegate <NSObject>

- (void)onSend:(PushSettingSEICell *)cell seiMessagePayloadType:(int)payloadType msg:(NSString *)msg;

@end

@interface PushSettingSEICell : UITableViewCell
@property (nonatomic, weak) id<PushSettingSEICellDelegate> delegate;
- (void)setSEIPayloadType:(NSInteger)type msg:(NSString *)msg;
@end

NS_ASSUME_NONNULL_END
