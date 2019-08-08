//
//  WebRTCViewController.h
//  TXLiteAVDemo
//
//  Created by lijie on 2018/1/22.
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TXLivePlayer.h"

@interface WebRTCViewController : UIViewController {

    UIView                   *_pusherView;
    NSMutableDictionary      *_playerViewDic;      // [userID, view]
    NSMutableArray           *_placeViewArray;     // 用来界面显示占位,view
    
    UITextField              *_txtRoomId;          // 房间号
    UITextField              *_txtUserId;          // 账号
    UITextField              *_txtUserPwd;         // 密码
    UIButton                 *_btnJoin;
    UIButton                 *_btnCamera;
    UIButton                 *_btnMute;
    UIButton                 *_btnLog;
    UIButton                 *_btnEnv;             // 正式环境 or 测试环境
    
    BOOL                     _join_switch;
    BOOL                     _camera_switch;
    BOOL                     _mute_switch;
    BOOL                     _env_switch;
    
    BOOL                     _appIsInActive;
    BOOL                     _appIsBackground;
    
    UITextView               *_logView;
    UIView                   *_coverView;
    NSInteger                _log_switch;  // 0:隐藏log  1:显示SDK内部的log  2:显示业务层log

}

@end


/**
 * 房间里面有多个TXLivePlayer，而TXLivePlayer的事件通知没有携带userID信息，则无法区分出是谁的事件，所以加一个包装类
 */

@protocol WebRTCPlayerListener <NSObject>
@optional
-(void)onPlayEvent:(NSString*)userID withEvtID:(int)evtID andParam:(NSDictionary*)param;
-(void)onNetStatus:(NSString*)userID withParam: (NSDictionary*) param;
@end

@interface WebRTCPlayerListenerWrapper : NSObject <TXLivePlayListener>
@property (nonatomic, strong) NSString *userID;
@property (nonatomic, weak) id<WebRTCPlayerListener> delegate;
@end
