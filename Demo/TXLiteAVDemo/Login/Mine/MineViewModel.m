//
//  MineViewModel.m
//  TXLiteAVDemo_Enterprise
//
//  Created by peterwtma on 2021/7/20.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "MineViewModel.h"
#import "AppLocalized.h"

@implementation MinTableViewCellModel

+ (instancetype)cellInfoWithTitle:(NSString*)title
                cellInfoWithImage:(UIImage*)image
             cellInfoWithListType:(CellInfoType)type {
    MinTableViewCellModel* model = [[MinTableViewCellModel alloc] init];
    if (model) {
        model.title = title;
        model.image = image;
        model.type = type;
    }
    return model;
}
@end


@implementation MineViewModel
- (instancetype)init {
    self = [super init];
    if (self) {
        self.user = ProfileManager.shared.curUserModel;
        NSInteger typeLen = ENUM_MAX;
        self.subCells = [[NSMutableArray alloc] init];
        
        for (NSInteger i = 0; i < typeLen; i++) {
            switch (i) {
                case ENUM_PRIVACY:
                {
                    MinTableViewCellModel *model = [MinTableViewCellModel cellInfoWithTitle:V2Localize(@"Demo.TRTC.Portal.private") cellInfoWithImage:[UIImage imageNamed:@"main_mine_privacy"] cellInfoWithListType: ENUM_PRIVACY];
                    [self.subCells addObject:model];
                    break;
                }
                case ENUM_AGREEMENT:
                {
                    MinTableViewCellModel *model = [MinTableViewCellModel cellInfoWithTitle:V2Localize(@"Demo.TRTC.Portal.Agreement") cellInfoWithImage:[UIImage imageNamed:@"userAgreement"] cellInfoWithListType: ENUM_AGREEMENT];
                    [self.subCells addObject:model];
                    break;
                }
                case ENUM_DISCLAIMER:
                {
                    MinTableViewCellModel *model = [MinTableViewCellModel cellInfoWithTitle:(AppPortalLocalize(@"Demo.TRTC.Portal.disclaimer")) cellInfoWithImage:[UIImage imageNamed:@"main_mine_disclaimer"] cellInfoWithListType: ENUM_DISCLAIMER];
                    [self.subCells addObject:model];
                    break;
                }
                case ENUM_ABOUT:
                {
                    MinTableViewCellModel *model = [MinTableViewCellModel cellInfoWithTitle:(AppPortalLocalize(@"Demo.TRTC.Portal.Mine.about")) cellInfoWithImage:[UIImage imageNamed:@"main_mine_about"] cellInfoWithListType: ENUM_ABOUT];
                    [self.subCells addObject:model];
                    break;
                }
                case ENUM_LOGOUT:
                {
                    MinTableViewCellModel *model = [MinTableViewCellModel  cellInfoWithTitle:(AppPortalLocalize(@"Demo.TRTC.Portal.Home.logout")) cellInfoWithImage:[UIImage imageNamed:@"exit"] cellInfoWithListType: ENUM_LOGOUT];
                    [self.subCells addObject:model];
                    break;
                }
            }
        }
    }
    return self;
}

- (BOOL)validate:(NSString*) userName {
    NSString *reg = @"^[a-zA-Z0-9_\u4e00-\u9fa5]{2,20}$";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", reg];
    return [predicate evaluateWithObject:userName];
}
@end


