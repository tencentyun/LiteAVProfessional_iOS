//
//  DevOpsCheckManager.m
//  TXLiteAVDemo_Enterprise
//
//  Created by jack on 2021/11/8.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "DevOpsCheckManager.h"
#import <Masonry/Masonry.h>
#import "AppDelegate.h"
#import "AppLocalized.h"
#import "TXConfigManager.h"

@interface DevOpsUpdateViewController : UIViewController

@property (strong, nonatomic) UIView *contentView;

@property (strong, nonatomic) UILabel *titleLabel;

@property (strong, nonatomic) UILabel *contentLabel;

@property (strong, nonatomic) UIButton *updateBtn;

// 更新内容数据
@property (strong, nonatomic) NSDictionary *updateInfo;

@end

@implementation DevOpsUpdateViewController

/// DevOps更新弹框视图
/// @param updateInfo 更新信息
- (instancetype)initWithUpdateInfo:(NSDictionary *)updateInfo{
    if (self = [super init]) {
        self.modalPresentationStyle = UIModalPresentationCustom;
        self.updateInfo = updateInfo;
    }
    return self;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.55];
    
    [self initUI];
    //生成视图层次布局
    [self constructViewHierarchy];
    //约束布局
    [self addConstraint];
    //绑定事件
    [self bindInteraction];
}

- (void)initUI{
    _contentView = [[UIView alloc] initWithFrame:CGRectZero];
    _contentView.backgroundColor = [UIColor whiteColor];
    _contentView.layer.cornerRadius = 10.0;
    _contentView.layer.masksToBounds = YES;
    
    _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _titleLabel.font = [UIFont systemFontOfSize:14];
    _titleLabel.textColor = UIColor.blackColor;
    _titleLabel.text = TRTCLocalize(@"Demo.TRTC.LiveRoom.prompt");
    
    _contentLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _contentLabel.font = [UIFont systemFontOfSize:18];
    _contentLabel.textColor = UIColor.blackColor;
    _contentLabel.numberOfLines = 0;
    _contentLabel.text = [NSString stringWithFormat:TRTCLocalize(@"Demo.TRTC.Home.devopsupdate"), _updateInfo[@"appVersion"]];
    
    _updateBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_updateBtn setTitle:TRTCLocalize(@"Demo.TRTC.Home.updatenow") forState:UIControlStateNormal];
    [_updateBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [_updateBtn.titleLabel setFont:[UIFont systemFontOfSize:16]];
}

- (void)constructViewHierarchy{
    [self.view addSubview:self.contentView];
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.contentLabel];
    [self.contentView addSubview:self.updateBtn];
}

- (void)addConstraint{
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(30);
        make.trailing.mas_equalTo(-30);
        make.centerY.mas_equalTo(0);
    }];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(15);
        make.centerX.mas_equalTo(0);
    }];
    [self.contentLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(20);
        make.trailing.mas_equalTo(-20);
        make.top.mas_equalTo(_titleLabel.mas_bottom).mas_offset(20);
    }];
    [self.updateBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.mas_equalTo(0);
        make.height.mas_equalTo(50);
        make.top.mas_equalTo(_contentLabel.mas_bottom).mas_offset(20);;
        make.bottom.mas_equalTo(0);
    }];
}

- (void)bindInteraction{
    [_updateBtn addTarget:self action:@selector(updateAction) forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - actions
- (void)updateAction{
    NSURL *serverDownloadURL = [NSURL URLWithString:_updateInfo[@"downloadUrl"]];
    // 获取ipa文件地址
    NSString *ipaFilePath = [serverDownloadURL.path componentsSeparatedByString:@"custom"].lastObject;
    // 地址'/'需要编码处理
    ipaFilePath = [ipaFilePath stringByReplacingOccurrencesOfString:@"/" withString:@"%2F"];
    
    NSString *devOpsDownloadURLString = [[TXConfigManager shareInstance] devOpsDownloadURL];
    // 构造devOps下载地址
    devOpsDownloadURLString = [devOpsDownloadURLString stringByReplacingOccurrencesOfString:@"IPAFilePath" withString:ipaFilePath];
    NSURL *devOpsURL = [NSURL URLWithString:devOpsDownloadURLString];
    [[UIApplication sharedApplication] openURL:devOpsURL options:@{} completionHandler:nil];
}

@end

@interface DevOpsCheckManager ()

@end

static DevOpsCheckManager *shared = nil;
@implementation DevOpsCheckManager


+ (instancetype)shareInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[DevOpsCheckManager alloc] init];
    });
    return shared;
}

+ (void)checkUpdateWithUserId:(NSString *)userId{
    if (!userId || ![userId isKindOfClass:[NSString class]] || userId.length == 0) {
        NSLog(@"====== userId is empty ======");
        return;
    }
    NSString *devOpsAppName = [[TXConfigManager shareInstance] devOpsAppName];
    if (!devOpsAppName || ![devOpsAppName isKindOfClass:[NSString class]] || devOpsAppName.length == 0) {
        NSLog(@"====== 未配置蓝盾AppName: devOpsAppName is empty ======");
        return;
    }
    NSString *devOpsDownloadUrl = [[TXConfigManager shareInstance] devOpsDownloadURL];
    if (!devOpsDownloadUrl || ![devOpsDownloadUrl isKindOfClass:[NSString class]] || devOpsDownloadUrl.length == 0) {
        NSLog(@"====== 未配置蓝盾下载地址: devOpsDownloadUrl is empty ======");
        return;
    }
    [[DevOpsCheckManager shareInstance] checkDevOpsVersionWithUserId:userId devOpsAppName:devOpsAppName];
}

#pragma mark - 检测蓝盾构建版本

/// 检测蓝盾构建版本
/// @param userId 当前用户Id，需要检验
/// @param devOpsAppName 蓝盾构建检测的AppName
- (void)checkDevOpsVersionWithUserId:(NSString *)userId
                       devOpsAppName:(NSString *)devOpsAppName {
    // 请求地址
    NSString *urlString = @"https://app-setting-6g3yro2b392da038-1256993030.ap-shanghai.app.tcloudbase.com/appSetting";
    // AppName
    NSString *appName = devOpsAppName;
    // 本地的 app 版本号
    NSString *appVersion = [TXAppInfo appVersionWithBuild];
    // 操作系统
    NSString *osName = [UIDevice currentDevice].systemName.lowercaseString;
    // 操作系统版本号
    NSString *osVersion = [UIDevice currentDevice].systemVersion;
    // 构造请求地址
    NSString *requestURLString = [urlString stringByAppendingFormat:@"?os=%@&osVersion=%@&appName=%@&appVersion=%@&userId=%@", osName, osVersion, appName, appVersion, userId];
    // 构造请求URL
    NSURL *requestURL = [NSURL URLWithString: requestURLString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL];
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json; charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
    __weak __typeof(self) weakSelf = self;
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSError *err = nil;
        if (!data || data.length == 0) {
            NSLog(@"====== no DevOps update data error: %@======", error);
            return;
        }
        NSDictionary *updateDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&err];
        if (err || !updateDic || ![updateDic isKindOfClass:[NSDictionary class]]) {
            NSLog(@"====== no DevOps update data ======");
            return;
        }
        NSLog(@"====== response DevOps data:%@ ======", updateDic);
        NSString *statusCode = [NSString stringWithFormat:@"%@", updateDic[@"code"]];
        NSDictionary *updateDataInfo = updateDic[@"data"];
        if (statusCode.integerValue != 0 || !updateDataInfo) {
            NSLog(@"====== get DevOps update data error:%@ ======", updateDic);
            return;
        }
        NSString *isNeedUpdate = [NSString stringWithFormat:@"%@", updateDataInfo[@"isNeedUpdate"]];
        if (isNeedUpdate.boolValue && updateDataInfo[@"downloadUrl"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf showDevOpsUpdateAlertControllerWithInfo:updateDataInfo];
            });
        }
    }];
    [task resume];
}

/// DevOps更新视图显示
/// @param updateInfo 更新信息
- (void)showDevOpsUpdateAlertControllerWithInfo:(NSDictionary *)updateInfo {
    
    DevOpsUpdateViewController *updateController = [[DevOpsUpdateViewController alloc] initWithUpdateInfo:updateInfo];
    
    AppDelegate *delegate = (id)[UIApplication sharedApplication].delegate;
    if (delegate && delegate.window && delegate.window.rootViewController) {
        [delegate.window.rootViewController presentViewController:updateController animated:YES completion:nil];
    }
}

@end
