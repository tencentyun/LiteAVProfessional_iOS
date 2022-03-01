//
//  IMMsgManager.m
//  TXLiteAVDemo
//
//  Created by lijie on 2017/11/1.
//  Copyright © 2017年 Tencent. All rights reserved.
//
#import "IMMsgManager.h"

#import <mach/mach_time.h>
#import <sys/sysctl.h>

#import "ImSDK/ImSDK.h"

#define CMD_PUSHER_CHANGE   @"notifyPusherChange"
#define CMD_CUSTOM_TEXT_MSG @"CustomTextMsg"
#define CMD_CUSTOM_CMD_MSG  @"CustomCmdMsg"
#define CMD_LINK_MIC        @"linkmic"
#define CMD_PK              @"pk"

#define ErrMsg(x) [@"[IM] " stringByAppendingString:x]

#if DEBUG
#define Log NSLog
#else
#define Log(...)
#endif

@interface IMMsgManager () <V2TIMSDKListener, V2TIMAdvancedMsgListener, V2TIMGroupListener> {
    MLVBLoginInfo *  _config;
    dispatch_queue_t _queue;

    NSString *       _groupID;            // 群ID
    TIMConversation *_groupConversation;  // 群会话上下文
}

@property(nonatomic, assign) BOOL    isOwner;  // 是否是群主
@property(nonatomic, copy) NSString *ownerGroupID;

@end

@implementation IMMsgManager
- (instancetype)initWithConfig:(MLVBLoginInfo *)config {
    if (self = [super init]) {
        _config = config;
        _queue  = dispatch_queue_create("RoomMsgMgrQueue", DISPATCH_QUEUE_SERIAL);

        [[V2TIMManager sharedInstance] addAdvancedMsgListener:self];
        [[V2TIMManager sharedInstance] setGroupListener:self];
        _groupID = @"0";
        _isOwner = NO;
    }
    return self;
}

- (void)prepareToDealloc {
    [[V2TIMManager sharedInstance] removeAdvancedMsgListener:self];
}

- (void)asyncRun:(void (^)(void))block {
    dispatch_async(_queue, ^{
        block();
    });
}

- (void)syncRun:(void (^)(void))block {
    dispatch_sync(_queue, ^{
        block();
    });
}

- (void)switchGroup:(NSString *)groupID {
    _groupID           = groupID;
    _groupConversation = [[TIMManager sharedInstance] getConversation:TIM_GROUP receiver:groupID];
}

#pragma mark - Time
double getSystemUptime(void) {
    struct timeval boottime;
    int            mib[2] = {CTL_KERN, KERN_BOOTTIME};
    size_t         size   = sizeof(boottime);
    time_t         now;
    time_t         uptime = -1;

    (void)time(&now);

    if (sysctl(mib, 2, &boottime, &size, NULL, 0) != -1 && boottime.tv_sec != 0) {
        uptime = now - boottime.tv_sec;
    }

    // 这里对精度要求只到秒，为方便处理统一转换为毫秒
    return uptime * 1000;
}

- (void)setLoginServerTime:(uint64_t)loginServerTime {
    _loginServerTime = loginServerTime;
    _loginUptime     = getSystemUptime();
    Log(@"[IM] setLoginServerTime: %llu, %llu", _loginServerTime, _loginUptime);
}

- (uint64_t)currentTimestamp {
    uint64_t elapse = getSystemUptime() - _loginUptime;
    return _loginServerTime + elapse;
}

- (BOOL)isExpired:(uint64_t)timestamp {
    uint64_t current = [self currentTimestamp];
    Log(@"current: %llu, timestamp: %llu", current, timestamp);
    uint64_t diff;
    if (current > timestamp) {
        diff = current - timestamp;
    } else {
        diff = timestamp - current;
    }
    return diff > 10000;
}

#pragma mark -
- (void)loginWithCompletion:(void (^)(int errCode, NSString *errMsg))completion {
    [self asyncRun:^{
        [[V2TIMManager sharedInstance] login:self->_config.userID
            userSig:self->_config.userSig
            succ:^{
                if (completion) {
                    completion(0, nil);
                }
            }
            fail:^(int code, NSString *msg) {
                if (completion) {
                    completion(code, ErrMsg(msg));
                }
            }];
    }];
}

- (void)logout:(void (^)(int errCode, NSString *errMsg))completion {
    [self asyncRun:^{
        [[V2TIMManager sharedInstance]
            logout:^{
                if (completion) {
                    completion(0, nil);
                }
            }
            fail:^(int code, NSString *msg) {
                if (completion) {
                    completion(code, ErrMsg(msg));
                }
            }];
    }];
}

- (void)enterRoom:(NSString *)groupID completion:(void (^)(int errCode, NSString *errMsg))completion {
    [self asyncRun:^{
        __weak __typeof(self) weakSelf = self;
        [[V2TIMManager sharedInstance] joinGroup:groupID
            msg:nil
            succ:^{
                //切换群会话的上下文环境
                [weakSelf switchGroup:groupID];

                if (completion) {
                    completion(0, nil);
                }
            }
            fail:^(int code, NSString *msg) {
                if (completion) {
                    completion(code, ErrMsg(msg));
                }
            }];
    }];
}

- (void)quitGroup:(NSString *)groupID completion:(void (^)(int errCode, NSString *errMsg))completion {
    [self asyncRun:^{
        // 如果是群主，那么就解散该群，如果不是群主，那就退出该群
        if (self->_isOwner && [self->_ownerGroupID isEqualToString:groupID]) {
            [[V2TIMManager sharedInstance] dismissGroup:groupID
                succ:^{
                    if (completion) {
                        completion(0, nil);
                    }
                }
                fail:^(int code, NSString *msg) {
                    if (completion) {
                        completion(code, ErrMsg(msg));
                    }
                }];

        } else {
            [[V2TIMManager sharedInstance] quitGroup:groupID
                succ:^{
                    if (completion) {
                        completion(0, nil);
                    }
                }
                fail:^(int code, NSString *msg) {
                    if (completion) {
                        completion(code, ErrMsg(msg));
                    }
                }];
        }
    }];
}

- (void)sendNotifyMessage {
    NSDictionary *data = @{@"cmd" : CMD_PUSHER_CHANGE};
    if (_groupConversation) {
        [[V2TIMManager sharedInstance] sendGroupCustomMessage:[self dictionary2JsonData:data]
            to:self->_groupConversation.getReceiver
            priority:V2TIM_PRIORITY_NORMAL
            succ:^{
                Log(@"sendCustomMessage success");
            }
            fail:^(int code, NSString *desc) {
                Log(@"sendCustomMessage failed, data[%@]", data);
            }];
    }
}

// CustomElem{"cmd":"CustomCmdMsg", "data":{"userName":"xxx", "userAvatar":"xxx", "cmd":"xx", msg:"xx"}}
- (void)sendRoomCustomMsg:(NSString *)cmd msg:(NSString *)msg completion:(void (^)(int errCode, NSString *errMsg))completion {
    [self asyncRun:^{
        NSDictionary *data = @{
            @"cmd" : cmd,
            @"msg" : msg == nil ? @"" : msg,
            @"userName" : self->_config.userName,
            @"userAvatar" : self->_config.userAvatar,
        };
        NSDictionary *customMsg = @{@"cmd" : CMD_CUSTOM_CMD_MSG, @"data" : data};
        [[V2TIMManager sharedInstance] sendGroupCustomMessage:[self dictionary2JsonData:customMsg]
            to:self->_groupConversation.getReceiver
            priority:V2TIM_PRIORITY_NORMAL
            succ:^{
                Log(@"sendCustomMessage success");
                if (completion) completion(0, nil);
            }
            fail:^(int code, NSString *desc) {
                Log(@"sendCustomMessage failed, data[%@]", data);
                if (completion) completion(code, desc);
            }];
    }];
}

- (void)sendCCCustomMessage:(NSString *)userID data:(NSData *)data completion:(void (^)(int code, NSString *msg))completion {
    [[V2TIMManager sharedInstance] sendC2CCustomMessage:data
        to:userID
        succ:^{
            Log(@"sendCCCustomMessage success");
            if (completion) {
                completion(0, nil);
            };
        }
        fail:^(int code, NSString *desc) {
            Log(@"sendCCCustomMessage failed, data[%@]", data);
            if (completion) {
                completion(code, ErrMsg(desc));
            }
        }];
}

// 一条消息两个Elem：CustomElem{“cmd”:”CustomTextMsg”, “data”:{nickName:“xx”, headPic:”xx”}} + TextElem
- (void)sendGroupTextMsg:(NSString *)textMsg completion:(void (^)(int errCode, NSString *errMsg))completion {
    [self asyncRun:^{
        TIMCustomElem *msgHead  = [[TIMCustomElem alloc] init];
        NSDictionary * userInfo = @{@"nickName" : self->_config.userName, @"headPic" : self->_config.userAvatar};
        NSDictionary * headData = @{@"cmd" : CMD_CUSTOM_TEXT_MSG, @"data" : userInfo};
        msgHead.data            = [self dictionary2JsonData:headData];

        TIMTextElem *msgBody = [[TIMTextElem alloc] init];
        msgBody.text         = textMsg;

        TIMMessage *msg = [[TIMMessage alloc] init];
        [msg addElem:msgHead];
        [msg addElem:msgBody];

        if (self->_groupConversation) {
            [self->_groupConversation sendMessage:msg
                succ:^{
                    Log(@"sendGroupTextMsg success");
                    if (completion) completion(0, nil);
                }
                fail:^(int code, NSString *msg) {
                    Log(@"sendGroupTextMsg failed, textMsg[%@]", textMsg);
                    if (completion) completion(code, msg);
                }];
        }
    }];
}

#pragma mark - Group Management
- (void)createGroupWithID:(NSString *)groupID name:(NSString *)groupName completion:(void (^)(int errCode, NSString *errMsg))completion {
    // TODO: Test if initialization finished
    __weak __typeof(self) wself = self;
    [[V2TIMManager sharedInstance] createGroup:@"AVChatRoom"
        groupID:groupID
        groupName:groupName
        succ:^(NSString *groupID) {
            __strong __typeof(wself) self = wself;
            [self switchGroup:groupID];
            if (completion) {
                completion(0, nil);
            }
        }
        fail:^(int code, NSString *desc) {
            if (code == 10025) {
                code = 0;
                Log(@"群组 %@ 已被使用，并且操作者为群主，可以直接使用", groupID);
                [self switchGroup:groupID];
            }
            completion(code, ErrMsg(desc));
        }];
}

- (void)deleteGroupWithID:(NSString *)groupID completion:(void (^)(int errCode, NSString *errMsg))completion {
    [[V2TIMManager sharedInstance] dismissGroup:groupID
        succ:^{
            if (completion) {
                completion(0, nil);
            }
        }
        fail:^(int code, NSString *msg) {
            if (completion) {
                completion(code, ErrMsg(msg));
            }
        }];
}

- (void)getGroupMemberList:(NSString *)groupID completion:(void (^)(int code, NSString *msg, NSArray<MLVBAudienceInfo *> *members))completion {
    [[V2TIMManager sharedInstance] getGroupMemberList:groupID
        filter:V2TIM_GROUP_MEMBER_FILTER_COMMON
        nextSeq:0
        succ:^(uint64_t nextSeq, NSArray<V2TIMGroupMemberFullInfo *> *memberList) {
            NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:memberList.count];
            for (V2TIMGroupMemberFullInfo *memberInfo in memberList) {
                MLVBAudienceInfo *info = [[MLVBAudienceInfo alloc] init];
                info.userID            = memberInfo.userID;
                info.userName          = memberInfo.nickName ?: @"";
                info.userAvatar        = memberInfo.faceURL;
                [result addObject:info];
            }
            completion(0, nil, result);
        }
        fail:^(int code, NSString *desc) {
            completion(code, ErrMsg(desc), nil);
        }];
}
#pragma mark - V2TIMAdvancedMsgListener

- (void)onRecvNewMessage:(V2TIMMessage *)msg {
    if (msg.userID.length > 0) {
        [self onRecvC2CMsg:msg];
    } else if (msg.groupID.length > 0) {
        // 目前只处理当前群消息
        if ([msg.groupID isEqualToString:self->_groupID]) {
            [self onRecvGroupMsg:msg];
        }
    }
}

- (void)onRecvC2CMsg:(V2TIMMessage *)msg {
    if (msg.elemType == V2TIM_ELEM_TYPE_CUSTOM) {
        V2TIMCustomElem *customElem = msg.customElem;
        NSDictionary *   dict       = [self jsonData2Dictionary:customElem.data];

        NSString *cmd  = nil;
        id        data = nil;
        if (dict) {
            cmd  = dict[@"cmd"];
            data = dict[@"data"];
        }

        // 连麦相关的消息
        if (cmd && [cmd isEqualToString:CMD_LINK_MIC] && [data isKindOfClass:[NSDictionary class]]) {
            NSString *type      = data[@"type"];
            uint64_t  timestamp = [data[@"timestamp"] unsignedLongLongValue];
            if ([self isExpired:timestamp]) {
                return;
            }
            if (type && [type isEqualToString:@"request"]) {
                NSString *message = data[@"reason"];
                if (_delegate && [_delegate respondsToSelector:@selector(onRecvJoinAnchorRequest:userID:userName:userAvatar:reason:)]) {
                    [_delegate onRecvJoinAnchorRequest:data[@"roomID"] userID:msg.sender userName:data[@"userName"] userAvatar:data[@"userAvatar"] reason:message];
                }
            } else if (type && [type isEqualToString:@"response"]) {
                NSString *resultStr = data[@"result"];
                NSString *message   = data[@"reason"];
                NSString *roomID    = data[@"roomID"];
                BOOL      result    = NO;
                if (resultStr && [resultStr isEqualToString:@"accept"]) {
                    result = YES;
                }
                if (_delegate && [_delegate respondsToSelector:@selector(onRecvJoinAnchorResponse:result:message:)]) {
                    [_delegate onRecvJoinAnchorResponse:roomID result:result message:message];
                }

            } else if (type && [type isEqualToString:@"kickout"]) {
                NSString *roomID = data[@"roomID"];
                if (_delegate && [_delegate respondsToSelector:@selector(onRecvJoinAnchorKickout:)]) {
                    [_delegate onRecvJoinAnchorKickout:roomID];
                }
            }
        }
        // 跨房主播PK相关的消息
        else if (cmd && [cmd isEqualToString:CMD_PK] && [data isKindOfClass:[NSDictionary class]]) {
            NSString *type      = data[@"type"];
            uint64_t  timestamp = [data[@"timestamp"] unsignedLongLongValue];
            if ([self isExpired:timestamp]) {
                return;
            }

            if (type && [type isEqualToString:@"request"]) {
                NSString *action = data[@"action"];
                if (action && [action isEqualToString:@"start"]) {  // 收到PK请求的消息
                    if (_delegate && [_delegate respondsToSelector:@selector(onRequestRoomPK:userID:userName:userAvatar:streamUrl:)]) {
                        [_delegate onRequestRoomPK:data[@"roomID"] userID:msg.sender userName:data[@"userName"] userAvatar:data[@"userAvatar"] streamUrl:data[@"accelerateURL"]];
                    }

                } else if (action && [action isEqualToString:@"stop"]) {  // 收到PK结束的消息
                    if (_delegate && [_delegate respondsToSelector:@selector(onRecvPKFinishRequest:userID:)]) {
                        [_delegate onRecvPKFinishRequest:data[@"roomID"] userID:msg.sender];
                    }
                }

            } else if (type && [type isEqualToString:@"response"]) {
                NSString *result = data[@"result"];
                if (result && [result isEqualToString:@"accept"]) {  // 收到接收PK的消息
                    if (_delegate && [_delegate respondsToSelector:@selector(onRecvPKResponse:userID:result:message:streamUrl:)]) {
                        [_delegate onRecvPKResponse:data[@"roomID"] userID:msg.sender result:YES message:@"" streamUrl:data[@"accelerateURL"]];
                    }

                } else if (result && [result isEqualToString:@"reject"]) {  // 收到拒绝PK的消息
                    if (_delegate && [_delegate respondsToSelector:@selector(onRecvPKResponse:userID:result:message:streamUrl:)]) {
                        [_delegate onRecvPKResponse:data[@"roomID"] userID:msg.sender result:NO message:data[@"reason"] streamUrl:nil];
                    }
                }
            }
        }
    }
}

- (void)onRecvGroupMsg:(V2TIMMessage *)msg {
    NSString *cmd  = nil;
    id        data = nil;

    if (msg.elemType == V2TIM_ELEM_TYPE_CUSTOM) {
        V2TIMCustomElem *customElem = msg.customElem;
        NSDictionary *   dict       = [self jsonData2Dictionary:customElem.data];
        if (dict) {
            cmd  = dict[@"cmd"];
            data = dict[@"data"];
        }

        // 群自定义消息处理
        if (cmd && [cmd isEqualToString:CMD_CUSTOM_CMD_MSG] && [data isKindOfClass:[NSDictionary class]]) {
            if (_delegate && [_delegate respondsToSelector:@selector(onRecvGroupCustomMsg:userID:cmd:msg:userName:userAvatar:)]) {
                [_delegate onRecvGroupCustomMsg:_groupID userID:msg.sender cmd:data[@"cmd"] msg:data[@"msg"] userName:data[@"userName"] userAvatar:data[@"userAvatar"]];
            }
        } else if ([cmd isEqualToString:CMD_PUSHER_CHANGE]) {
            [_delegate onMemberChange:_groupID];
        }
        V2TIMElem *elem = customElem.nextElem;
        if (!elem) {
            return;
        }
        if ([elem isKindOfClass:[V2TIMTextElem class]]) {
            V2TIMTextElem *textElem = (V2TIMTextElem *)elem;
            NSString *     msgText  = textElem.text;

            // 群文本消息处理
            if ([cmd isEqualToString:CMD_CUSTOM_TEXT_MSG] && [data isKindOfClass:[NSDictionary class]]) {
                NSDictionary *userInfo = (NSDictionary *)data;
                NSString *    nickName = nil;
                NSString *    headPic  = nil;
                if (userInfo) {
                    nickName = userInfo[@"nickName"];
                    headPic  = userInfo[@"headPic"];
                }

                if (_delegate) {
                    [_delegate onRecvGroupTextMsg:_groupID userID:msg.sender textMsg:msgText userName:nickName userAvatar:headPic];
                }
            } else if ([cmd isEqualToString:CMD_PUSHER_CHANGE]) {
                [_delegate onMemberChange:_groupID];
            }
        }
    }
}

#pragma mark - V2TIMGroupListener
- (void)onMemberEnter:(NSString *)groupID memberList:(NSArray<V2TIMGroupMemberInfo *> *)memberList {
    if (![_groupID isEqualToString:groupID]) {
        return;
    }
    V2TIMGroupMemberInfo *member = memberList.firstObject;
    MLVBAudienceInfo *    info   = [[MLVBAudienceInfo alloc] init];
    info.userID                  = member.userID;
    info.userName                = member.nickName;
    info.userAvatar              = member.faceURL;
    if (self.delegate) {
        [self.delegate onGroupMemberEnter:groupID user:info];
    }
}

- (void)onMemberLeave:(NSString *)groupID member:(V2TIMGroupMemberInfo *)member {
    if (![_groupID isEqualToString:groupID]) {
        return;
    }
    MLVBAudienceInfo *info = [[MLVBAudienceInfo alloc] init];
    info.userID            = member.userID;
    info.userName          = member.nickName;
    info.userAvatar        = member.faceURL;
    if (self.delegate) {
        [self.delegate onGroupMemberLeave:groupID user:info];
    }
}

- (void)onGroupDismissed:(NSString *)groupID opUser:(V2TIMGroupMemberInfo *)opUser {
    if (![_groupID isEqualToString:groupID]) {
        return;
    }
    if (self.delegate) {
        [self.delegate onGroupDelete:_groupID];
    }
}

- (void)onReceiveRESTCustomData:(NSString *)groupID data:(NSData *)data {
    if (![_groupID isEqualToString:groupID]) {
        return;
    }
    NSDictionary *dict = [self jsonData2Dictionary:data];
    if (dict == nil) {
        return;
    }

    NSString *cmd = dict[@"cmd"];
    if (cmd == nil) {
        return;
    }
    // 群成员有变化
    if ([cmd isEqualToString:CMD_PUSHER_CHANGE]) {
        if (self.delegate) {
            [self.delegate onMemberChange:groupID];
        }
    }
}

#pragma mark - TIMUserStatusListener
/**
 *  踢下线通知
 */
- (void)onKickedOffline {
    if ([self.delegate respondsToSelector:@selector(onForceOffline)]) {
        [self.delegate onForceOffline];
    }
}

#pragma mark - utils

- (NSData *)dictionary2JsonData:(NSDictionary *)dict {
    if ([NSJSONSerialization isValidJSONObject:dict]) {
        NSError *error = nil;
        NSData * data  = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
        if (error) {
            Log(@"dictionary2JsonData failed: %@", dict);
            return nil;
        }
        return data;
    }
    return nil;
}

- (NSDictionary *)jsonData2Dictionary:(NSData *)jsonData {
    if (jsonData == nil) {
        return nil;
    }
    NSError *     err = nil;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&err];
    if (err) {
        Log(@"JjsonData2Dictionary failed: %@", jsonData);
        return nil;
    }
    return dic;
}

#pragma mark - 连麦

// 向userID发起连麦请求
// {cmd:"linkmic", data:{type: “request”, roomID:”xxx”, userID:"xxxx", userName:"xxxx", userAvatar:"xxxx"}}
- (void)sendJoinAnchorRequest:(NSString *)userID roomID:(NSString *)roomID {
    [self asyncRun:^{
        NSDictionary *data = @{
            @"type" : @"request",
            @"roomID" : roomID,
            @"userID" : self->_config.userID,
            @"userName" : self->_config.userName,
            @"userAvatar" : self->_config.userAvatar,
            @"timestamp" : @([self currentTimestamp])
        };
        NSDictionary *msgDic = @{@"cmd" : CMD_LINK_MIC, @"data" : data};

        [self sendCCCustomMessage:userID data:[self dictionary2JsonData:msgDic] completion:nil];
    }];
}

// 向userID发起连麦响应，result为："accept“ or "reject"
// {cmd:"linkmic", data:{type: “response”, roomID:”xxx”, result: "xxxx"，message:"xxxx }}
- (void)sendJoinAnchorResponseWithUID:(NSString *)userID roomID:(NSString *)roomID result:(BOOL)result reason:(NSString *)reason {
    [self asyncRun:^{
        NSString *resultStr = @"reject";
        if (result) {
            resultStr = @"accept";
        }
        NSDictionary *data   = @{@"type" : @"response", @"roomID" : roomID, @"result" : resultStr, @"reason" : reason ?: @"", @"timestamp" : @([self currentTimestamp])};
        NSDictionary *msgDic = @{@"cmd" : CMD_LINK_MIC, @"data" : data};

        [self sendCCCustomMessage:userID data:[self dictionary2JsonData:msgDic] completion:nil];
    }];
}

// 群主向userID发出踢出连麦消息
// {cmd:"linkmic", data:{type: "kickout”, roomID:”xxx”}}
- (void)sendJoinAnchorKickout:(NSString *)userID roomID:(NSString *)roomID {
    [self asyncRun:^{
        NSDictionary *data   = @{@"type" : @"kickout", @"roomID" : roomID, @"timestamp" : @([self currentTimestamp])};
        NSDictionary *msgDic = @{@"cmd" : CMD_LINK_MIC, @"data" : data};

        [self sendCCCustomMessage:userID data:[self dictionary2JsonData:msgDic] completion:nil];
    }];
}

// 向userID发起PK请求
// {"cmd":"pk", "data":{"roomID":"XXX", "type":"request", "action":"start", "userID":"XXX", "userName":"XXX", "userAvatar":"XXX", "accelerateURL":"XXX"} }
- (void)sendPKRequest:(NSString *)userID roomID:(NSString *)roomID withAccelerateURL:(NSString *)accelerateURL {
    [self asyncRun:^{
        NSDictionary *data = @{
            @"roomID" : roomID,
            @"type" : @"request",
            @"action" : @"start",
            @"userID" : self->_config.userID,
            @"userName" : self->_config.userName,
            @"userAvatar" : self->_config.userAvatar,
            @"accelerateURL" : accelerateURL,
            @"timestamp" : @([self currentTimestamp])
        };
        NSDictionary *msgDic = @{@"cmd" : CMD_PK, @"data" : data};

        [self sendCCCustomMessage:userID data:[self dictionary2JsonData:msgDic] completion:nil];
    }];
}

// 请求结束PK
// {"cmd":"pk", "data":{"roomID":"XXX", "type":"request", "action":"stop", "userID":"XXX", "userName":"XXX", "userAvatar":"XXX"} }
- (void)sendPKFinishRequest:(NSString *)userID roomID:(NSString *)roomID completion:(void (^)(int errCode, NSString *errMsg))completion {
    [self asyncRun:^{
        NSDictionary *data = @{
            @"roomID" : roomID,
            @"type" : @"request",
            @"action" : @"stop",
            @"userID" : self->_config.userID,
            @"userName" : self->_config.userName,
            @"userAvatar" : self->_config.userAvatar,
            @"timestamp" : @([self currentTimestamp])
        };
        NSDictionary *msgDic = @{@"cmd" : CMD_PK, @"data" : data};

        [self sendCCCustomMessage:userID data:[self dictionary2JsonData:msgDic] completion:completion];
    }];
}

// 接收PK
// {"cmd":"pk", "data":{"roomID":"XXX", "type":"response", "result":"accept",  "reason":"" , "accelerateURL":"XXX"} }
- (void)acceptPKRequest:(NSString *)userID roomID:(NSString *)roomID withAccelerateURL:(NSString *)accelerateURL {
    [self asyncRun:^{
        NSDictionary *data   = @{@"roomID" : roomID, @"type" : @"response", @"result" : @"accept", @"reason" : @"", @"accelerateURL" : accelerateURL, @"timestamp" : @([self currentTimestamp])};
        NSDictionary *msgDic = @{@"cmd" : CMD_PK, @"data" : data};

        [self sendCCCustomMessage:userID data:[self dictionary2JsonData:msgDic] completion:nil];
    }];
}

// 拒绝PK
// {"cmd":"pk", "data":{"roomID":"XXX",  "type":"response", "result":"reject",  "reason":"" } }
- (void)rejectPKRequest:(NSString *)userID roomID:(NSString *)roomID reason:(NSString *)reason {
    [self asyncRun:^{
        NSDictionary *data   = @{@"roomID" : roomID, @"type" : @"response", @"result" : @"reject", @"reason" : reason, @"timestamp" : @([self currentTimestamp])};
        NSDictionary *msgDic = @{@"cmd" : CMD_PK, @"data" : data};

        [self sendCCCustomMessage:userID data:[self dictionary2JsonData:msgDic] completion:nil];
    }];
}

#pragma mark - 个人信息
- (void)setSelfProfile:(NSString *)userName avatarURL:(NSString *)avatarURL completion:(void (^)(int code, NSString *msg))completion {
    V2TIMUserFullInfo *info = [[V2TIMUserFullInfo alloc] init];
    info.nickName           = userName;
    info.faceURL            = avatarURL;
    [[V2TIMManager sharedInstance] setSelfInfo:info
        succ:^{
            Log(@"[IM} modifySelfProfile succeed");
            if (completion) {
                completion(0, nil);
            }
        }
        fail:^(int code, NSString *desc) {
            Log(@"[IM} modifySelfProfile failed: %d, %@", code, desc);
            if (completion) {
                completion(code, ErrMsg(desc));
            }
        }];
}

- (void)getProfile:(void (^)(int code, NSString *msg, NSString *nickname, NSString *avatar))completion {
    if (completion == nil) return;
    NSString *loginUser = [[V2TIMManager sharedInstance] getLoginUser];
    [[V2TIMManager sharedInstance] getUsersInfo:@[ loginUser ]
        succ:^(NSArray<V2TIMUserFullInfo *> *infoList) {
            V2TIMUserFullInfo *profile = infoList.firstObject;
            completion(0, nil, profile.nickName, profile.faceURL);
        }
        fail:^(int code, NSString *desc) {
            completion(code, desc, nil, nil);
        }];
}
@end
