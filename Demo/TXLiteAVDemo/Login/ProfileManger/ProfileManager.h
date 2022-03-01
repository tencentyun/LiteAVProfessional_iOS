//
//  ProfileManager.h
//  TXLiteAVDemo
//
//  Created by peterwtma on 2021/7/23.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import <UIKit/UIKit.h>

/// 通用成功回调
typedef void (^CommonSucc)(void);
/// 通用失败回调
typedef void (^CommonFailed)(NSString * _error);

extern NSString * const tokenKey;

//LoginResultModel
@interface LoginResultModel : NSObject
@property(nonatomic, strong)NSString *token;
@property(nonatomic, strong)NSString *phone;
@property(nonatomic, strong)NSString *name;
@property(nonatomic, strong)NSString *avatar;
@property(nonatomic, strong)NSString *userId;
@property(nonatomic, strong)NSString *userSig;
@end

@interface ProfileManager : NSObject
@property(nonatomic, strong)NSString *sessionId;
@property(nonatomic, strong)NSNumber *captcha_web_appid;
@property(nonatomic, strong)NSString *countryCode;
@property(nonatomic, strong)NSString *phone;
@property(nonatomic, strong)NSString *code;
@property(nonatomic, strong)LoginResultModel *curUserModel;
+(instancetype)shared;
-(void)requestGslb:(CommonSucc)succ fail:(CommonFailed)fail;
-(void)login:(CommonSucc)succ fail:(CommonFailed)fail autoLogin:(BOOL)autoLogin;
-(void)sendVerifyCode:(NSString*)ticket randomStr:(NSString*)randomStr sucess:(CommonSucc)succ failed:(CommonFailed)fail;
-(BOOL)autoLogin:(CommonSucc)succ fail:(CommonFailed)fail;
-(void)removeLoginCache;
-(void)synchronizUserInfo;
-(void)setNickName:(NSString*)name success:(CommonSucc)succ failed:(CommonFailed)fail;
-(void)resign:(CommonSucc)succ failed:(CommonFailed)fail;
-(NSString*)curUserID;
-(NSString*)curUserSig;
-(void)notLoginEnter:(CommonSucc)succ;
//免登录自动登录
-(void)notLoginAutoLogin:(CommonSucc)succ;
@end

