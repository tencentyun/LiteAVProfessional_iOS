#import <Foundation/Foundation.h>

@interface TRTCCustomerCrypt : NSObject

@property(nonatomic, copy) NSString *encryptKey;

+ (instancetype)new __attribute__((unavailable("Use +sharedInstance instead")));
- (instancetype)init __attribute__((unavailable("Use +sharedInstance instead")));

+ (instancetype)sharedInstance;

- (void *)getEncodedDataProcessingListener;

@end
