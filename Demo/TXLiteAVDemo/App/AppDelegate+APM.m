//
//  AppDelegate+APM.m
//  TXLiteAVDemo_Enterprise
//
//  Created by sherlock on 2018/7/4.
//  Copyright © 2018 Tencent. All rights reserved.
//

#import "AppDelegate+APM.h"
#import <objc/runtime.h>
#import <QAPM/QAPM.h>

@implementation AppDelegate (APM)

void loggerFunc(QAPMLoggerLevel level, const char* log) {
    NSLog(@"log level: %d, log info:%s", level, log);
}

+(void)load{
    Method fromMethed = class_getInstanceMethod([self class], @selector(application:didFinishLaunchingWithOptions:));
    Method toMethed = class_getInstanceMethod([self class], @selector(swizzingApplication:didFinishLaunchingWithOptions:));
    if(!class_addMethod([UIViewController class], @selector(viewDidDisappear:), method_getImplementation(toMethed), method_getTypeEncoding(toMethed))){
        method_exchangeImplementations(fromMethed, toMethed);
    }
}

- (BOOL)swizzingApplication:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions{
    //启动QAPM组件, QAPM组件为腾讯提供的用于检测内存泄漏的开放组件, 如果您不需要该组件, 可自行移除
    /********************************  设置QAPM日志回调 ****************/
    [QAPMPerformanceProfile registerLogCallback: loggerFunc];
    
    /********************************  配置QAPM ****************/
    /// 外发版本请注释掉下面这行代码。测试阶段，不进行用户抽样，所有用户都允许使用功能与上报。默认开启，并且用户采样率百分之一。
    
    [QAPMPerformanceProfile setProperty:@(1) forKey:QAPMPropertyKeyUserSampleRation];
    /// 产品版本号
    [QAPMPerformanceProfile setProperty:[self getBuildVersion] forKey: QAPMPropertyKeyAppVersion];
    /// 需要申请AppKey
    [QAPMPerformanceProfile setProperty:@"dbdf5d96-181" forKey: QAPMPropertyKeyAppKey];
    /// 最后设置userId
    [QAPMPerformanceProfile setProperty:@"lockerzhang" forKey: QAPMPropertyKeyUserId];
    
    /********************************  配置Yellow(VC泄漏) ****************/
    /// 启用Yellow
    //[QAPMPerformanceProfile beginScene:nil withMode:QAPMMoniterTypeYellow];
    
    return [self swizzingApplication:application didFinishLaunchingWithOptions:launchOptions];
    
}

-(NSString *)getBuildVersion{
    NSString *buildVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *bundleVersion = [[[NSBundle mainBundle]infoDictionary]objectForKey:@"CFBundleVersion"];
    
    if (buildVersion && bundleVersion) {
        if (buildVersion.length > 3) {
            buildVersion = [buildVersion substringWithRange:NSMakeRange(0, 4)];
        }
        NSString *version = [buildVersion stringByAppendingString:bundleVersion];
        //        NSLog(@"version:%@",version);
        return version;
    }
    return @"unknowVersion";
}
@end
