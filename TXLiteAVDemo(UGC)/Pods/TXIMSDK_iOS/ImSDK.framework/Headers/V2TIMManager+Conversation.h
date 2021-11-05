/////////////////////////////////////////////////////////////////////
//
//                     腾讯云通信服务 IMSDK
//
//  模块名称：V2TIMManager+Conversation
//
//  会话接口，里面包含了会话的获取，删除，更新的逻辑
//
/////////////////////////////////////////////////////////////////////

#import "V2TIMManager.h"
#import "V2TIMManager+Group.h"
#import "V2TIMManager+Message.h"

@protocol V2TIMConversationListener;
@class V2TIMConversation;

/////////////////////////////////////////////////////////////////////////////////
//
//                         消息会话相关接口
//
/////////////////////////////////////////////////////////////////////////////////

@interface V2TIMManager (Conversation)

/// 获取会话列表成功的回调，nextSeq：下一次分页拉取的游标 isFinished：会话列表是否已经拉取完毕
typedef void(^V2TIMConversationResultSucc)(NSArray<V2TIMConversation *>*list, uint64_t nextSeq, BOOL isFinished);

/// 会话类型
typedef NS_ENUM(NSInteger, V2TIMConversationType) {
    V2TIM_C2C                             = 1,  ///< 单聊
    V2TIM_GROUP                           = 2,  ///< 群聊
};

/**
 *  1.1 设置会话监听器
 */
- (void)setConversationListener:(id<V2TIMConversationListener>)listener;

/**
 *  1.2 获取会话列表
 *
 *  - 一个会话对应一个聊天窗口，比如跟一个好友的 1v1 聊天，或者一个聊天群，都是一个会话。
 *  - 由于历史的会话数量可能很多，所以该接口希望您采用分页查询的方式进行调用，每次分页拉取的个数建议为 100 个。
 *  - 该接口拉取的是本地缓存的会话，如果服务器会话有更新，SDK 内部会自动同步，然后在 V2TIMConversationListener 告知客户。
 *  - 该接口获取的会话默认已经按照会话 lastMessage -> timestamp 做了排序，timestamp 越大，会话越靠前。
 *  - 如果会话全部拉取完毕，成功回调里面的 isFinished 字段值为 YES。
 *
 *  @param nextSeq 分页拉取游标，第一次默认取传 0，后续分页拉传上一次分页拉取回调里的 nextSeq
 *  @param count  分页拉取的个数，一次分页拉取不宜太多，会影响拉取的速度，建议每次拉取 100 个会话
 */
- (void)getConversationList:(uint64_t)nextSeq count:(int)count succ:(V2TIMConversationResultSucc)succ fail:(V2TIMFail)fail;

/**
 *  1.3 删除会话
 * 
 * @note 请注意如下特殊逻辑:
 * - 删除会话会在本地删除的同时，在服务器也会同步删除。
 * - 会话内的消息不会从服务器删除，如果其他人在此会话继续发言，仍然可以从后台拉取该会话的漫游消息。
 */
- (void)deleteConversation:(NSString *)conversationID succ:(V2TIMSucc)succ fail:(V2TIMFail)fail;

/**
 *  1.4 设置会话草稿
 *
 *  只在本地保存，不会存储 Server，不能多端同步，程序卸载重装会失效。
 */
- (void)setConversationDraft:(NSString *)conversationID draftText:(NSString *)draftText succ:(V2TIMSucc)succ fail:(V2TIMFail)fail;
@end

/////////////////////////////////////////////////////////////////////////////////
//
//                         会话变更监听器
//
/////////////////////////////////////////////////////////////////////////////////

@protocol V2TIMConversationListener <NSObject>
@optional
/**
 * 同步服务器会话开始，SDK 会在登录成功或者断网重连后自动同步服务器会话，您可以监听这个事件做一些 UI 进度展示操作。
 */
- (void)onSyncServerStart;

/**
 * 同步服务器会话完成，如果会话有变更，会通过 onNewConversation | onConversationChanged 回调告知客户
 */
- (void)onSyncServerFinish;

/**
 * 同步服务器会话失败
 */
- (void)onSyncServerFailed;

/**
 * 有新的会话（比如收到一个新同事发来的单聊消息、或者被拉入了一个新的群组中），可以根据会话的 lastMessage -> timestamp 重新对会话列表做排序。
 */
- (void)onNewConversation:(NSArray<V2TIMConversation*> *) conversationList;

/**
 * 某些会话的关键信息发生变化（未读计数发生变化、最后一条消息被更新等等），可以根据会话的 lastMessage -> timestamp 重新对会话列表做排序。
 */
- (void)onConversationChanged:(NSArray<V2TIMConversation*> *) conversationList;

@end

/////////////////////////////////////////////////////////////////////////////////
//
//                         会话对象 V2TIMConversation
//
/////////////////////////////////////////////////////////////////////////////////
/// 会话对象
@interface V2TIMConversation : NSObject

/// 会话类型
@property(nonatomic,assign,readonly) V2TIMConversationType type;

/// 会话唯一 ID，如果是 C2C 单聊，组成方式为 c2c_userID，如果是群聊，组成方式为 group_groupID
@property(nonatomic,strong,readonly) NSString *conversationID;

/// 如果会话类型为 C2C 单聊，userID 会存储对方的用户ID，否则为 nil
@property(nonatomic,strong,readonly) NSString *userID;

/// 如果会话类型为群聊，groupID 会存储当前群的群 ID，否则为 nil
@property(nonatomic,strong,readonly) NSString *groupID;

/// 会话展示名称（群组：群名称 >> 群 ID；C2C：对方好友备注 >> 对方昵称 >> 对方的 userID）
@property(nonatomic,strong,readonly) NSString *showName;

/// 会话展示头像（群组：群头像；C2C：对方头像）
@property(nonatomic,strong,readonly) NSString *faceUrl;

/// 会话未读消息数量,直播群（AVChatRoom）不支持未读计数，默认为 0
@property(nonatomic,assign,readonly) int unreadCount;

/// 消息接收选项（群会话有效）
@property(nonatomic,assign,readonly) V2TIMGroupReceiveMessageOpt recvOpt;

/// 会话最后一条消息，可以通过 lastMessage -> timestamp 对会话做排序，timestamp 越大，会话越靠前
@property(nonatomic,strong,readonly) V2TIMMessage *lastMessage;

/// 草稿信息，设置草稿信息请调用 setConversationDraft() 接口
@property(nonatomic,strong,readonly) NSString *draftText;

/// 草稿编辑时间，草稿设置的时候自动生成
@property(nonatomic,assign,readonly) NSDate *draftTimestamp;

@end
