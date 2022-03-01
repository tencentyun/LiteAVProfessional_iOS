//
//  ProfileManager.m
//  TXLiteAVDemo
//
//  Created by peterwtma on 2021/7/23.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "ProfileManager.h"
#import <V2TIMManager.h>
#import <TIMComm.h>
#import "GenerateTestUserSig.h"
#import "AppLocalized.h"
#import "TCUtil.h"

NSString * const tokenKey = @"com.tencent.trtcScences.demo";

//主线程异步队列
#define dispatch_main_async_safe(block)\
    if ([NSThread isMainThread]) {\
        block();\
    } else {\
        dispatch_async(dispatch_get_main_queue(), block);\
    }

//#if DEBUG
//NSString* loginBaseUrl = @"https://demos.trtc.tencent-cloud.com/dev/";
//#else
//NSString* loginBaseUrl = @"https://demos.trtc.tencent-cloud.com/prod/";
//#endif
NSString* loginBaseUrl = @"https://demos.trtc.tencent-cloud.com/prod/";

//LoginModel
@interface GslbModel : NSObject
@property(nonatomic, assign)NSString* service;
@property(nonatomic, assign)NSInteger captcha_web_appid;
@property(nonatomic, assign)NSInteger captcha_wxmini_appid;
@end


//LoginModel
@interface LoginModel : NSObject
@property(nonatomic, assign)NSInteger errorCode;
@property(nonatomic, strong)NSString* errorMessage;
@property(nonatomic, strong)LoginResultModel* data;
@end

//UserModel
@interface UserModel : NSObject
@property(nonatomic, strong)NSString* phone;
@property(nonatomic, strong)NSString* name;
@property(nonatomic, strong)NSString* avatar;
@property(nonatomic, strong)NSString* userId;
@end

@implementation UserModel

-(instancetype)initWithUserID:(NSString*)userID{
    self = [super init];
    if(self) {
        self.userId = userID;
        self.name = @"initName";
        self.avatar = @"https://wx4.sinaimg.cn/large/006DFKaTly1fhvvnpuwe2j30gq0gqmy4.jpg";
        self.phone = nil;
    }
    return self;
}

-(BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[UserModel class]]) {
        if ([self.userId isEqualToString:((UserModel*)object).userId]) {
            return true;
        }
    }
    return false;
}

@end

//NameModel
@interface NameModel : NSObject
@property(nonatomic, assign)NSInteger errorCode;
@property(nonatomic, strong)NSString* errorMessage;
@end

//VerifyResultModel
@interface VerifyResultModel : NSObject
@property(nonatomic, strong)NSString *sessionId;
@property(nonatomic, strong)NSString *requestId;
@property(nonatomic, strong)NSString *codeStr;
@end

//VerifyModel
@interface VerifyModel : NSObject
@property(nonatomic, assign)NSInteger errorCode;
@property(nonatomic, strong)NSString *errorMessage;
@property(nonatomic, strong)VerifyResultModel *data;
@end

//ResignModel
@interface ResignModel : NSObject
@property(nonatomic, strong)NSString *codeStr;
@property(nonatomic, strong)NSString *errorMessage;
@property(nonatomic, assign)NSInteger errorCode;
@end

//QueryModel
@interface QueryModel : NSObject
@property(nonatomic, assign)NSInteger errorCode;
@property(nonatomic, strong)NSString  *errorMessage;
@property(nonatomic, strong)UserModel *data;
@end


@implementation LoginResultModel

@end

@interface ProfileManager()

@end


@implementation ProfileManager

static ProfileManager *instance = nil;
+(instancetype)shared{
    if(!instance) {
        instance = [[ProfileManager alloc] init];
    }
    return instance;
}

-(instancetype)init{
    self = [super init];
    if (self) {
        self.countryCode = @"86";
        self.sessionId = @"";
        self.curUserModel = [[LoginResultModel alloc] init];
    }
    return self;
}

-(void)synchronizUserInfo{
    if (!self.curUserModel) {
        return;
    }
    
    V2TIMUserFullInfo* userInfo = [[V2TIMUserFullInfo alloc] init];
    userInfo.nickName = self.curUserModel.name;
    userInfo.faceURL = self.curUserModel.avatar;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSData* cacheData = [[NSUserDefaults standardUserDefaults] objectForKey:tokenKey];
        id cacheInfo = [[NSJSONSerialization JSONObjectWithData:cacheData options:0 error:nil]mutableCopy];
        [cacheInfo setObject:self.curUserModel.avatar forKey:@"avatar"];
        NSData* cacheDate =  [TCUtil dictionary2JsonData:cacheInfo];
        [NSUserDefaults.standardUserDefaults setObject:cacheDate forKey:tokenKey];
    });
    
    if([V2TIMManager sharedInstance]) {
        [[V2TIMManager sharedInstance] setSelfInfo:userInfo succ:^{
                NSLog(@"set profile success");
            } fail:^(int code, NSString *desc) {
                NSLog(@"set profile failed.");
            }];
    }
}

-(void)requestGslb:(CommonSucc)succ fail:(CommonFailed)fail {
    NSString *gslbUrl = [loginBaseUrl stringByAppendingString:@"base/v1/gslb"];
    
    NSURL *URL = [NSURL URLWithString:gslbUrl];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    NSURLSessionTask *dataTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"SendRequest failed, NSURLSessionDataTask return error code: %ld, des: %@", (long)[error code], [error description]);
        } else {
            NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSDictionary *resultDict = [TCUtil jsonData2Dictionary:responseString];
            
            if( [[resultDict objectForKey:@"errorCode"] isEqual:@0]) {
                if (![resultDict objectForKey:@"data"]) {
                    fail(@"response decode failed");
                }
                NSDictionary* data = [resultDict objectForKey:@"data"];
               self.captcha_web_appid = [data objectForKey:@"captcha_web_appid"];
                NSString *sessionId  = [data objectForKey:@"sessionId"];
                if(sessionId.length>0){
                    self.sessionId = [data objectForKey:@"sessionId"];
                }
                dispatch_main_async_safe(succ)
                return;
            } else {
                fail(LoginNetworkLocalize(@"LoginNetwork.ProfileManager.sendfailed"));
                return;
            }

        }
    }];
    [dataTask resume];
}

-(BOOL)autoLogin:(CommonSucc)succ fail:(CommonFailed)fail {
    NSData* cacheData = [[NSUserDefaults standardUserDefaults] objectForKey:tokenKey];
    if (cacheData) {
        NSError *jsonError;
        id cacheInfo = [NSJSONSerialization JSONObjectWithData:cacheData options:0 error:&jsonError];
        self.curUserModel.avatar = [cacheInfo objectForKey:@"avatar"];
        self.curUserModel.userSig = [cacheInfo objectForKey:@"userSig"];
        self.curUserModel.phone = [cacheInfo objectForKey:@"phone"];
        self.curUserModel.userId = [cacheInfo objectForKey:@"userId"];
        self.curUserModel.token = [cacheInfo objectForKey:@"token"];
        self.curUserModel.name = [cacheInfo objectForKey:@"name"];
        
        [self login:succ fail:fail autoLogin:true];
        return true;
    }
    return false;
}

-(void)notLoginEnter:(CommonSucc)succ {
    NSString *userId = self.curUserModel.userId;
    self.curUserModel.avatar = @"https://imgcache.qq.com/qcloud/public/static//avatar1_100.20191230.png";
    self.curUserModel.userSig =  [GenerateTestUserSig genTestUserSig:userId];
    self.curUserModel.phone = userId;
    self.curUserModel.userId = userId;
    self.curUserModel.name = self.curUserModel.name;
    self.curUserModel.token = [GenerateTestUserSig genTestUserSig:userId];
    
    NSMutableDictionary* result = [[NSMutableDictionary alloc]initWithCapacity:6];
    [result setObject:self.curUserModel.avatar forKey:@"avatar"];
    [result setObject:self.curUserModel.userSig forKey:@"userSig"];
    [result setObject:self.curUserModel.phone forKey:@"phone"];
    [result setObject:self.curUserModel.userId forKey:@"userId"];
    [result setObject:self.curUserModel.name forKey:@"name"];
    [result setObject:self.curUserModel.token forKey:@"token"];
    NSData* cacheDate =  [TCUtil dictionary2JsonData:result];
    
    [NSUserDefaults.standardUserDefaults setObject:cacheDate forKey:tokenKey];

    dispatch_main_async_safe(succ)
}

-(void)notLoginAutoLogin:(CommonSucc)succ {
    NSData* cacheData = [[NSUserDefaults standardUserDefaults] objectForKey:tokenKey];
    if (cacheData) {
        NSDictionary *cacheInfo = [[NSJSONSerialization JSONObjectWithData:cacheData options:0 error:nil]mutableCopy];
        self.curUserModel.avatar = [cacheInfo objectForKey:@"avatar"];
        self.curUserModel.userSig = [cacheInfo objectForKey:@"userSig"];
        self.curUserModel.phone = [cacheInfo objectForKey:@"phone"];
        self.curUserModel.userId = [cacheInfo objectForKey:@"userId"];
        self.curUserModel.token = [cacheInfo objectForKey:@"token"];
        self.curUserModel.name = [cacheInfo objectForKey:@"name"];
        dispatch_main_async_safe(succ)
    }
}
-(void)sendVerifyCode:(NSString*)ticket randomStr:(NSString*)randomStr sucess:(CommonSucc)succ failed:(CommonFailed)fail{
    assert(ticket.length > 0 && randomStr.length > 0 && self.phone.length > 0);
    
    NSString* verifyCodeUrl = [loginBaseUrl stringByAppendingString:@"base/v1/auth_users/user_verify_by_picture"];
    NSString* phoneValue = self.phone;
    assert(phoneValue.length > 0);
    
    
    NSString* phoneCode = [self.countryCode stringByAppendingString:phoneValue];
    
    NSMutableDictionary *param = [[NSMutableDictionary alloc] init];
    [param setObject:phoneCode forKey:@"phone"];
    [param setObject:ticket forKey:@"ticket"];
    [param setObject:randomStr forKey:@"randstr"];
    
    [param setObject:[NSString stringWithFormat:@"%@",self.captcha_web_appid] forKey:@"appId"];
    NSData* data = [TCUtil dictionary2JsonData:param];

    NSURL *URL = [NSURL URLWithString:verifyCodeUrl];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    [request setValue:[NSString stringWithFormat:@"%ld",(long)[data length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:data];

    NSURLSessionTask *dataTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"SendRequest failed, NSURLSessionDataTask return error code: %ld, des: %@", (long)[error code], [error description]);
        } else {
            NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSDictionary *resultDict = [TCUtil jsonData2Dictionary:responseString];
            
            if( [[resultDict objectForKey:@"errorCode"] isEqual:@0]) {
                if (![resultDict objectForKey:@"data"]) {
                    fail(@"response decode failed");
                }
                NSDictionary* data = [resultDict objectForKey:@"data"];
                NSString *sessionId  = [data objectForKey:@"sessionId"];
                if(sessionId.length>0){
                    self.sessionId = [data objectForKey:@"sessionId"];
                }
                dispatch_main_async_safe(succ)
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    fail(LoginNetworkLocalize(@"LoginNetwork.ProfileManager.sendfailed"));
                });
            }

        }
    }];
    [dataTask resume];
}

/// 登录
/// -Parameters
/// - success: 登录成功
/// - failed: 登录失败
/// -error: 错误信息
-(void) login:(CommonSucc)succ fail:(CommonFailed)fail autoLogin:(BOOL)autoLogin  {
    NSString* phoneValue;
    NSString* codeValue;
    NSString* phoneCode;
    NSData* data;
    NSString* loginUrl = loginBaseUrl;
    if(autoLogin) {
        phoneCode = self.curUserModel.phone;
        NSMutableDictionary *param = [[NSMutableDictionary alloc] init];
        [param setObject:self.curUserModel.userId forKey:@"userId"];
        [param setObject:self.curUserModel.token forKey:@"token"];
        data = [TCUtil dictionary2JsonData:param];
        loginUrl = [loginUrl stringByAppendingString:@"base/v1/auth_users/user_login_token"];
    } else {
        loginUrl = [loginUrl stringByAppendingString:@"base/v1/auth_users/user_login_code"];
        phoneValue= self.phone;
        codeValue = self.code;
        assert(phoneValue.length > 0 && codeValue.length > 0);
        phoneCode = [self.countryCode stringByAppendingString:phoneValue];
        
        NSMutableDictionary *param = [[NSMutableDictionary alloc] init];
        [param setObject:phoneCode forKey:@"phone"];
        [param setObject:codeValue forKey:@"code"];
        [param setObject:self.sessionId forKey:@"sessionId"];
        data = [TCUtil dictionary2JsonData:param];
    }
    
    if(self.sessionId.length == 0 && !autoLogin) {
        fail(V2Localize(@"V2.Live.LoginMock.sendtheverificatcode"));
        return;
    }
    
    NSURL *URL = [NSURL URLWithString:loginUrl];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    
    [request setValue:[NSString stringWithFormat:@"%ld",(long)[data length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:data];
    [request setTimeoutInterval:30];
    NSURLSessionTask *dataTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"SendRequest failed, NSURLSessionDataTask return error code: %ld, des: %@", (long)error.code, error.description);
        } else {
            NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSDictionary *resultDict = [TCUtil jsonData2Dictionary:responseString];
            if( [[resultDict objectForKey:@"errorCode"] isEqual:@0]) {
                NSDictionary* result = [resultDict objectForKey:@"data"];
                if(!self.curUserModel){
                    self.curUserModel = [[LoginResultModel alloc] init];
                }
                if(!self.curUserModel.avatar){
                    self.curUserModel.avatar = [result objectForKey:@"avatar"];
                }
                self.curUserModel.userSig = [result objectForKey:@"userSig"];
                self.curUserModel.phone = [result objectForKey:@"phone"];
                self.curUserModel.userId = [result objectForKey:@"userId"];
                self.curUserModel.token = [result objectForKey:@"token"];
                self.curUserModel.name = [result objectForKey:@"name"];
                //cache data
                NSData* cacheDate =  [TCUtil dictionary2JsonData:result];
                [NSUserDefaults.standardUserDefaults setObject:cacheDate forKey:tokenKey];
                dispatch_main_async_safe(succ);
                return;
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    fail([resultDict objectForKey:@"errorMessage"]);
                    });
                return;
            }
        }
    }];
    [dataTask resume];
}

-(void)setNickName:(NSString*)name success:(CommonSucc)succ failed:(CommonFailed)fail {
    NSString* nameUrl = [loginBaseUrl stringByAppendingString:@"base/v1/auth_users/user_update"];
    NSString* userId;
    NSString* token;
    
    if(self.curUserModel && self.curUserModel.userId) {
        userId = self.curUserModel.userId;
    } else {
        fail(LoginNetworkLocalize(@"LoginNetwork.ProfileManager.registerfailed"));
        return;
    }
    
    if(!self.curUserModel.token) {
        fail(LoginNetworkLocalize(@"LoginNetwork.ProfileManager.registerfailed"));
        return;
    }
    token = self.curUserModel.token;
    
    NSMutableDictionary *param = [[NSMutableDictionary alloc] init];
    [param setObject:userId forKey:@"userId"];
    [param setObject:name forKey:@"name"];
    [param setObject:token forKey:@"token"];
    NSData *data = [TCUtil dictionary2JsonData:param];
    
    NSURL *URL = [NSURL URLWithString:nameUrl];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    
    [request setValue:[NSString stringWithFormat:@"%ld",(long)[data length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:data];
    [request setTimeoutInterval:30];
    NSURLSessionTask *dataTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error != nil) {
            fail(LoginNetworkLocalize(@"LoginNetwork.ProfileManager.registerfailed"));
        } else {
            NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSDictionary *resultDict = [TCUtil jsonData2Dictionary:responseString];
            if ([[resultDict objectForKey:@"errorCode"] isEqual:@0]) {
                dispatch_main_async_safe(succ);
            } else {
                NSLog(@"%@", resultDict);
                if ([[resultDict objectForKey:@"errorCode"] isEqual:@-1008]) {
                    fail([resultDict objectForKey:@"errorMessage"]);
                } else {
                    fail([resultDict objectForKey:@"errorMessage"]);
                }
            }
        }
    }];
    
    [dataTask resume];
}

-(void)resign:(CommonSucc)succ failed:(CommonFailed)fail {
    NSString *url = [loginBaseUrl stringByAppendingString:@"base/v1/auth_users/user_delete"];
    NSString *userId;
    NSString *token;
    
    if (self.curUserModel) {
        if (self.curUserModel.userId) {
            userId = self.curUserModel.userId;
        }
        if (self.curUserModel.token) {
            token = self.curUserModel.token;
        }
    }
    NSMutableDictionary *param = [[NSMutableDictionary alloc] init];
    [param setObject:userId forKey:@"userId"];
    [param setObject:token forKey:@"token"];
    NSData *data = [TCUtil dictionary2JsonData:param];
    
    NSURL *URL = [NSURL URLWithString:url];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    
    [request setValue:[NSString stringWithFormat:@"%ld",(long)[data length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:data];
    [request setTimeoutInterval:30];
    NSURLSessionTask *dataTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error != nil) {
            fail(LoginNetworkLocalize(@"LoginNetwork.ProfileManager.registerfailed"));
        } else {
            NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSDictionary *resultDict = [TCUtil jsonData2Dictionary:responseString];
            if ([[resultDict objectForKey:@"errorCode"] isEqual:@0]) {
                [self removeLoginCache];
                self.curUserModel = nil;
                V2TIMUserFullInfo* userInfo = [[V2TIMUserFullInfo alloc] init];
                userInfo.nickName = @"";
                userInfo.faceURL = @"";
                dispatch_main_async_safe(succ);
                if (V2TIMManager.sharedInstance) {
                    [V2TIMManager.sharedInstance setSelfInfo:userInfo succ:^{
                                            NSLog(@"set profile success");
                                            [V2TIMManager.sharedInstance logout:^{
                                                                        
                                                                    } fail:^(int code, NSString *desc) {
                                                                        
                                                                    }];
                                        } fail:^(int code, NSString *desc) {
                                            NSLog(@"set profile failed");
                                        }];
                }
            } else {
                NSLog(@"%@", resultDict);
                if ([[resultDict objectForKey:@"errorCode"] isEqual:@-1008]) {
                    fail([resultDict objectForKey:@"errorMessage"]);
                } else {
                    fail([resultDict objectForKey:@"errorMessage"]);
                }
            }
        }
    }];
    
    [dataTask resume];
}

-(void)IMLogin:(NSString*)userSig succ:(CommonSucc)succ fail:(CommonFailed)fail {
    [[V2TIMManager sharedInstance] initSDK:SDKAPPID config:nil listener:nil];
    
    if (!self.curUserModel) {
        fail(@"userID wrong");
        return;
    }
    TIMLoginParam* loginParam = [[TIMLoginParam alloc] init];
    loginParam.identifier = self.curUserModel.userId;
    loginParam.userSig = self.curUserModel.userSig;
    [[V2TIMManager sharedInstance] login:self.curUserModel.userId userSig:self.curUserModel.userSig succ:^{
            NSLog(@"login success");
        dispatch_main_async_safe(succ);
        } fail:^(int code, NSString *desc) {
            fail(desc);
            ;
            NSString* errStr = [NSString stringWithFormat:@"login failed, code:%d, error: %@",code, desc];
            NSLog(@"%@", errStr);
        }];
}


- (NSString*) curUserID {
    if (!self.curUserModel) {
        return nil;
    }
    return self.curUserModel.userId;
}


-(void)removeLoginCache {
    NSUserDefaults* de = [NSUserDefaults standardUserDefaults];
    [de setValue:nil forKey:tokenKey];
}

-(NSString*)curUserSig {
    return self.curUserModel ? self.curUserModel.userSig : @"";
}

@end
