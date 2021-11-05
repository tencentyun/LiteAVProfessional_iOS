//
//  MineViewModel.h
//  TXLiteAVDemo
//
//  Created by peterwtma on 2021/7/20.
//  Copyright © 2021 Tencent. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "ProfileManager.h"

typedef NS_ENUM(NSInteger, CellInfoType) {
    ENUM_PRIVACY = 0,
    ENUM_AGREEMENT,
    ENUM_DISCLAIMER,
    ENUM_ABOUT,
    ENUM_LOGOUT,
    ENUM_MAX,
};

NS_ASSUME_NONNULL_BEGIN

@interface MinTableViewCellModel : NSObject
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, assign) NSInteger type;

+ (instancetype)cellInfoWithTitle:(NSString*)title
                cellInfoWithImage:(UIImage*)image
             cellInfoWithListType:(CellInfoType)type;
@end

@interface MineViewModel : NSObject
@property (nonatomic, strong) LoginResultModel *user;
@property (nonatomic, strong) NSMutableArray<MinTableViewCellModel *> *subCells;
@property (nonatomic, strong) NSString *title;
- (BOOL)validate:(NSString*) userName;
@end

NS_ASSUME_NONNULL_END



