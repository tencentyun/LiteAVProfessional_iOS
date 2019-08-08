//
//  QAPMPerformanceProfile.h
//  QAPM
//
//  Created by Cass on 2018/5/18.
//  Copyright © 2018年 cass. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 QAPM SDK 版本号
 */
#define QAPM_SDK_VERSION @"2.2.6"

/*! @brief 日志级别
 *  当前日志全部打印为 QAPMLogLevel_Info
 */
typedef NS_ENUM(NSInteger, QAPMLoggerLevel) {
    ///外发版本log
    QAPMLogLevel_Event,
    ///灰度和内部版本log
    QAPMLogLevel_Info,
    ///内部版本log
    QAPMLogLevel_Debug,
};

/** 用于输出SDK调试log的回调 */
typedef void(*QAPM_Log_Callback)(QAPMLoggerLevel level, const char* log);

typedef NS_ENUM(NSUInteger, QAPMMoniterType)
{
    /// 不开启任何功能
    QAPMMoniterNone                     = 1 << 0,
    /// 区间性能采样，上报耗时与内存增量
    QAPMMoniterResource                 = 1 << 1,
    /// 滑动场景下的掉帧检测
    QAPMMoniterTypeTracking             = 1 << 2,
    /// 打开所有场景的掉帧检测([Blue] 打开所有场景的掉帧堆栈（除滑动外其它场景上报时的关键字为"others") 该接口开启后会以CADisplayLink的刷新间隔（16.6ms）不断抓取主线程堆栈，可根据需要选择是否打开在退后台的时候由于线程优先级降低，会使检测时间产生极大误差，强烈建议退后台的时候调用disableMonitorOtherStage关闭监控，在进前台时可以恢复监控！！！！)
    QAPMMoniterTypeAllStageTracking     = 1 << 3,
    /// 开始一次内存泄漏检测。目前只可检测真机运行时的内存泄漏，模拟器暂不支持。(不能与OOM一起使用，否则会检测不准确)
    QAPMMoniterTypeMemoryLeak           = 1 << 4,
    /// VC泄漏(yellow)
    QAPMMoniterTypeYellow               = 1 << 5,
    /// SigKill组件(当开启时，不能使用QQLeak内存泄漏检测，否则QQLeak检测不准确) (性能损耗 8%CPU , 内存15M左右。建议灰度全部开启，外网抽样开启)
    QAPMMoniterTypeSigKill              = 1 << 6,
};

typedef NS_ENUM(NSUInteger, QAPMPropertyKey)
{
    /// appKey
    QAPMPropertyKeyAppKey = 0,
    /// 用户id, 传String类型
    QAPMPropertyKeyUserId,
    /// 版本号, 传String类型
    QAPMPropertyKeyAppVersion,
    /// 上报域名, 传String类型
    QAPMPropertyKeyHost,
    
    /// [Yellow] 检测VC阈值（秒）
    QAPMPropertyKeyYellowLeakInterval,
    /// [Yellow] 设置白名单
    QAPMPropertyKeyYellowMarkedAsWhiteObj,
    /// [Yellow]  描述：针对白名单VC，可自定义检测时机，非白名单VC无需实现。注意：该方法在VC退出后调用，注意不要在dealloc方法中调用改方法，因为VC内存泄漏时无法执行dealloc
    QAPMPropertyKeyYellowObserveVC,
    
    /// [OOM] 单次大块内存检测功能是否开启。
    QAPMPropertyKeyOOMSingleChunkMallocEnable,
    /// [OOM] 单次大块内存检测阈值(bytes), 阀值设置较大时，性能开销几乎影响不计，手Q在灰度和CI全量开启该开关，阀值设置为50M
    QAPMPropertyKeyOOMSingleChunkMallocThreshholdInBytes,
    /// [OOM] 堆内存堆栈监控阈值 threshholdInBytes（bytes）
    QAPMPropertyKeyOOMMallocStackThreshholdInByte,
    /// [OOM] 是否开启堆内存堆栈监控，如果开启，请先设置 QAPMPropertyKeyOOMMallocStackThreshholdInByte。
    QAPMPropertyKeyOOMMallocStackDetectorEnable,
    /// [OOM] VM内存堆栈监控阈值 threshholdInBytes（bytes）
    QAPMPropertyKeyOOMVMStackThreshholdInByte,
    /// [OOM] VM内存堆栈监控是否开启, 如果开启，请先设置QAPMPropertyKeyOOMVMStackThreshholdInByte。因为startVMStackMonitor:方法用到了私有API __syscall_logger会带来app store审核不通过的风险，此方法默认只在DEBUG模式下生效，如果需要在RELEASE模式下也可用，请打开USE_VM_LOGGER_FORCEDLY宏，但是切记在提交appstore前将此宏关闭，否则可能会审核不通过。
    QAPMPropertyKeyOOMVMStackDetectorEnable,
    
    /// [Blue] 打开系统方法堆栈记录开关
    QAPMPropertyKeyBlueOpenSystemStackTrace,
    /// [Blue] StackMonitorWithThreshold (秒)
    QAPMPropertyKeyBlueStackMonitorWithThreshold,
    /// [Blue] 滑动场景区分，如果不需要则设置为0 滑动结束时调用，设置为0时只有“Normal_Scroll"的数据，当设置为其他值时，掉帧数据里面会多一个类型为"UserDefineScollType_x"的数据
    QAPMPropertyKeyBlueScrollType,
    
    /// 客户端设置采样率（范围0 - 1),百分之一为0.01，如果不设置则为后台控制采样率（后台默认0.01）。例如百分之一，每次启动App初始化SDK会随机进行开启功能。
    QAPMPropertyKeyUserSampleRation,
    
};

@interface QAPMPerformanceProfile : NSObject

/*
 @brief 配置各组件功能参数，参数功能请参照QAPMPropertyKey定义
 */
+ (void)setProperty:(id)value forKey:(QAPMPropertyKey)propertyKey;

/*
 @brief 开始监控
 @param scene: 监控场景，一般为VCClass
 @param mode: 监控类别
 */
+ (BOOL)beginScene:(NSString *)sceneName withMode:(QAPMMoniterType)mode;

/*
 @brief 开始监控
 @param scene: 监控场景，一般为VCClass
 @param identifier: 标识符
 @param mode: 监控类别
 */
+ (BOOL)beginScene:(NSString *)sceneName identifier:(NSString *)identifier withMode:(QAPMMoniterType)mode;

/*
 @brief 停止场景监控
 @param sceneName ： 监控场景，与开始的Class对应
 @param mode: 模式
 */
+ (BOOL)endScene:(NSString *)sceneName withMode:(QAPMMoniterType)mode;

/*
 @brief 停止场景监控
 @param sceneName: 监控场景，与开始的Class对应
 @param identifier: 标识符
 @param mode: 监控模式
 */
+ (BOOL)endScene:(NSString *)sceneName identifier:(NSString *)identifier withMode:(QAPMMoniterType)mode;

/*! @brief 注册SDK内部日志回调，用于输出SDK内部日志
 *
 * @param logger 外部的日志打印方法
 */
+ (void)registerLogCallback:(QAPM_Log_Callback)logger;

/*! @brief 请在Crash组件捕获到crash后调用该方法
 *
 */
+ (void)appDidCrashed;

/*! @brief 设置系统的私有API __syscall_logger，因为__syscall_logger是系统私有API，该功能不要在appstore版本打开
 *
 */
+ (void)setSigKillVMLogger:(void**)logger;

@end
