//
//  TXLiteAVDemo-Bridging-Header.h
//  TXLiteAVDemo_TRTC_Scene
//
//  Created by abyyxwang on 2020/4/15.
//  Copyright © 2020 Tencent. All rights reserved.
//

/* TXLiteAVDemo_Bridging_Header_h */

// localized string usage
#import "AppLocalized.h"

#ifdef ENABLE_INTERNATIONAL
#import "TXLiveBase.h"
#endif

#ifdef ENABLE_TRTC

//#import "TCAnchorViewController.h"
//#import "TCAudienceViewController.h"
//#import "TRTCMeeting.h"
// VocieRoom
//#import "TRTCVoiceRoomDef.h"
//#import "TRTCVoiceRoom.h"
// ChatSalon
//#import "TRTCChatSalon.h"
//#import "TRTCChatSalonDef.h"

//#import "TRTCLiveRoom.h"
//#import "TRTCCalling.h"
#endif

#import <MJRefresh/MJRefresh.h>
#import <SDWebImage/SDWebImage.h>

#import "AppDelegate.h"

#if !defined(UGC) && !defined(PLAYER)
#import <ImSDK/ImSDK.h>

#import "GenerateTestUserSig.h"
#endif

#ifdef ENTERPRISE
@import TXLiteAVSDK_Enterprise;
#endif

#ifdef PROFESSIONAL
@import TXLiteAVSDK_Professional;
#endif

#ifdef SMART
@import TXLiteAVSDK_Smart;
#endif

#ifdef PLAYER
@import TXLiteAVSDK_Player;
#endif

#ifdef UGC
@import TXLiteAVSDK_UGC;
#endif

#if defined(TRTC)
@import TXLiteAVSDK_TRTC;
#endif

#ifdef LIVE
@import TXLiteAVSDK_Live;
#endif
