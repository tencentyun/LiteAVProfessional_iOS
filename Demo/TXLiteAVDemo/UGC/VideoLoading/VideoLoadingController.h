//
//  VideoLoadingController.h
//  TCLVBIMDemo
//
//  Created by annidyfeng on 2017/4/17.
//  Copyright © 2017年 tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

typedef NS_ENUM(NSInteger,AssetType){
    AssetType_Video,
    AssetType_Image,
};

typedef NS_ENUM(NSInteger,ComposeMode){
    ComposeMode_Edit,
    ComposeMode_Join,
    ComposeMode_Video_Upload,
    ComposeMode_Image_Upload,
};

@interface VideoLoadingController : UIViewController
@property ComposeMode composeMode;
- (void)exportAssetList:(NSArray *)assets assetType:(AssetType)assetType;
@end

@interface PHAsset (My)
- (NSString *)orignalFilename;
@end

typedef enum {
    LBVideoOrientationUp,               //Device starts recording in Portrait
    LBVideoOrientationDown,             //Device starts recording in Portrait upside down
    LBVideoOrientationLeft,             //Device Landscape Left  (home button on the left side)
    LBVideoOrientationRight,            //Device Landscape Right (home button on the Right side)
    LBVideoOrientationNotFound = 99     //An Error occurred or AVAsset doesn't contains video track
} LBVideoOrientation;

@interface AVAsset (My)

/**
 Returns a LBVideoOrientation that is the orientation
 of the iPhone / iPad whent starst recording
 
 @return A LBVideoOrientation that is the orientation of the video
 */
@property (nonatomic, readonly) LBVideoOrientation videoOrientation;

@end
