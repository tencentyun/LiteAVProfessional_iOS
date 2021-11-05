//  Copyright © 2019 Tencent. All rights reserved.

#import <Foundation/Foundation.h>
#import <UGCKit/UGCKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, TCBackMode) {
    TCBackModePop,
    TCBackModeDismiss
};
@protocol UGCKitViewController;

@interface UGCKitWrapper : NSObject
@property (readonly, nonatomic) UGCKitTheme *theme;
- (instancetype)initWithViewController:(UIViewController *)viewController theme:(nullable UGCKitTheme *)theme;
- (void)showRecordViewControllerWithConfig:(UGCKitRecordConfig *)config;
- (void)showEditViewController:(UGCKitResult *)result
                      rotation:(TCEditRotation)rotation
        inNavigationController:(UINavigationController *)nav
                      backMode:(TCBackMode)backMode;
- (void)showVideoUploader:(UGCKitResult *)result
   inNavigationController:(UINavigationController *)navigationController;
- (void)showCombineViewController:(NSArray<AVAsset *> *)assets
           inNavigationController:(UINavigationController *)navigationController;

- (void)showEditEntryControllerWithType:(UGCKitMediaType)type;
- (void)showVideoJoinEntryController;
- (void)showVideoUploadEntryController;
- (void)showRecordEntryController;
@end


NS_ASSUME_NONNULL_END
