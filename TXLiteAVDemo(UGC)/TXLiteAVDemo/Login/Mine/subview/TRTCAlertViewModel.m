//
//  TRTCAlertControl.m
//  TXLiteAVDemo_Enterprise
//
//  Created by peterwtma on 2021/8/5.
//  Copyright © 2021 Tencent. All rights reserved.
//

#import "TRTCAlertViewModel.h"
#import "ProfileManager.h"



@implementation AvatarModel
- (instancetype)initWithUrl:(NSString*)url {
    self = [super init];
    if (self) {
        self.url = url;
    }
    return self;
}
@end


@implementation TRTCAlertViewModel

- (void)setUserAvatar: (NSString*)avatarUrl {
    if (ProfileManager.shared.curUserModel) {
        ProfileManager.shared.curUserModel.avatar = avatarUrl;
    }
}

- (void)synchronizUserInfo {
    [ProfileManager.shared synchronizUserInfo];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        
        self.avatarListDataSource = @[
            [[AvatarModel alloc] initWithUrl:@"https://liteav.sdk.qcloud.com/app/res/picture/voiceroom/avatar/user_avatar1.png"],
            [[AvatarModel alloc] initWithUrl:@"https://liteav.sdk.qcloud.com/app/res/picture/voiceroom/avatar/user_avatar10.png"],
            [[AvatarModel alloc] initWithUrl:@"https://liteav.sdk.qcloud.com/app/res/picture/voiceroom/avatar/user_avatar11.png"],
            [[AvatarModel alloc] initWithUrl: @"https://liteav.sdk.qcloud.com/app/res/picture/voiceroom/avatar/user_avatar12.png"],
            [[AvatarModel alloc] initWithUrl:@"https://liteav.sdk.qcloud.com/app/res/picture/voiceroom/avatar/user_avatar13.png"],
            [[AvatarModel alloc] initWithUrl:@"https://liteav.sdk.qcloud.com/app/res/picture/voiceroom/avatar/user_avatar14.png"],
            [[AvatarModel alloc] initWithUrl:@"https://liteav.sdk.qcloud.com/app/res/picture/voiceroom/avatar/user_avatar15.png"],
            [[AvatarModel alloc] initWithUrl:@"https://liteav.sdk.qcloud.com/app/res/picture/voiceroom/avatar/user_avatar16.png"],
            [[AvatarModel alloc] initWithUrl:@"https://liteav.sdk.qcloud.com/app/res/picture/voiceroom/avatar/user_avatar17.png"],
            [[AvatarModel alloc] initWithUrl:@"https://liteav.sdk.qcloud.com/app/res/picture/voiceroom/avatar/user_avatar18.png"],
            [[AvatarModel alloc] initWithUrl:@"https://liteav.sdk.qcloud.com/app/res/picture/voiceroom/avatar/user_avatar19.png"],
            [[AvatarModel alloc] initWithUrl:@"https://liteav.sdk.qcloud.com/app/res/picture/voiceroom/avatar/user_avatar20.png"],
            [[AvatarModel alloc] initWithUrl:@"https://liteav.sdk.qcloud.com/app/res/picture/voiceroom/avatar/user_avatar21.png"],
            [[AvatarModel alloc] initWithUrl:@"https://liteav.sdk.qcloud.com/app/res/picture/voiceroom/avatar/user_avatar22.png"],
            [[AvatarModel alloc] initWithUrl:@"https://liteav.sdk.qcloud.com/app/res/picture/voiceroom/avatar/user_avatar23.png"],
            [[AvatarModel alloc] initWithUrl:@"https://liteav.sdk.qcloud.com/app/res/picture/voiceroom/avatar/user_avatar24.png"],
            [[AvatarModel alloc] initWithUrl:@"https://liteav.sdk.qcloud.com/app/res/picture/voiceroom/avatar/user_avatar3.png"],
            [[AvatarModel alloc] initWithUrl:@"https://liteav.sdk.qcloud.com/app/res/picture/voiceroom/avatar/user_avatar4.png"],
            [[AvatarModel alloc] initWithUrl:@"https://liteav.sdk.qcloud.com/app/res/picture/voiceroom/avatar/user_avatar5.png"],
            [[AvatarModel alloc] initWithUrl:@"https://liteav.sdk.qcloud.com/app/res/picture/voiceroom/avatar/user_avatar6.png"],
            
            [[AvatarModel alloc] initWithUrl:@"https://liteav.sdk.qcloud.com/app/res/picture/voiceroom/avatar/user_avatar7.png"],
            
            [[AvatarModel alloc] initWithUrl:@"https://liteav.sdk.qcloud.com/app/res/picture/voiceroom/avatar/user_avatar8.png"],
            
            [[AvatarModel alloc] initWithUrl:@"https://liteav.sdk.qcloud.com/app/res/picture/voiceroom/avatar/user_avatar9.png"]
        ];
    }
    return self;
}
@end
