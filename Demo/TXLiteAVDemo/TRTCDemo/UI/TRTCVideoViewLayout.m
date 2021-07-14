/*
 * Module:   TRTCVideoViewLayout
 * 
 * Function: 用于计算每个视频画面的位置排布和大小尺寸
 *
 */

#import "TRTCVideoViewLayout.h"
#import "TRTCVideoView.h"

const static float VSPACE = 10.f;
const static float HSPACE = 20.f;
const static float MARGIN = 10.f;

@interface TRTCVideoViewLayout ()

@end

@implementation TRTCVideoViewLayout

- (void)setType:(TCLayoutType)type {
    _type = type;
    [self relayout:self.subViews];
}

+ (void)layout:(NSArray<UIView *> *)players atMainView:(UIView*)view {
    if (players == nil) {
        return;
    }

    for (UIView * player in players) {
        [view addSubview:player];
    }
    
    if (players.count == 1) {
        players[0].frame = (CGRect){.origin = CGPointZero, .size = view.frame.size};
        return;
    }
    
    if (players.count == 0) {
        return;
    }
    
    [UIView beginAnimations:@"TRTCLayoutEngine" context:nil];
    [UIView setAnimationDuration:0.25];
    players[0].frame = (CGRect){.origin = CGPointZero, .size = view.frame.size};
    for (int i = 1; i < players.count; i++) {
        if (i > 9) {
            players[i].frame = CGRectZero;
        } else {
            players[i].frame = [TRTCVideoViewLayout gird:9 at:9 - i mainView:view];
        }
    }
    
    [UIView commitAnimations];
}

// 将view等分为total块，处理好边距
#define FitH(rect) rect.size.height = (rect.size.width)/9.0*17
+ (CGRect)gird:(int)total at:(int)at mainView:(UIView*)view
{
    CGRect atRect = CGRectZero;
    CGFloat H = view.frame.size.height;
    CGFloat W = view.frame.size.width;
    // 等分主view，2、4、9...
    // 6宫格不能处理
    if (total <= 2) {
        atRect.size.width = (W - HSPACE - 2 * MARGIN) / 2;
        FitH(atRect);
        atRect.origin.y = (H-atRect.size.height)/2;
        if (at == 0) {
            atRect.origin.x = MARGIN;
        } else {
            atRect.origin.x = W-MARGIN-atRect.size.width;
        }
        return atRect;
    } else if (total <= 4) {
        atRect.size.width = (W - HSPACE - 2 * MARGIN) / 2;
        FitH(atRect);
        if (at / 2 == 0) {
            atRect.origin.y = (H - VSPACE)/2-atRect.size.height;
        } else {
            atRect.origin.y = (H + VSPACE)/2;
        }
        
        if (at % 2 == 0) {
            atRect.origin.x = MARGIN;
        } else {
            atRect.origin.x = W-MARGIN-atRect.size.width;
        }
        return atRect;
    } else if (total <= 6) {
        atRect.size.width = (W - 2 * HSPACE - 2 * MARGIN) / 3;
        FitH(atRect);
        if (at / 3 == 0) {
            atRect.origin.y = H/2 - atRect.size.height - VSPACE;
        } else {
            atRect.origin.y = H/2 + VSPACE;
        }
        
        if (at % 3 == 0) {
            atRect.origin.x = MARGIN;
        } else if (at % 3 == 1) {
            atRect.origin.x = W/2 - atRect.size.width/2;
        } else {
            atRect.origin.x = W - atRect.size.width - MARGIN;
        }
        return atRect;
    } else {
        if (at >= 9) {
            return CGRectZero;
        }
        
        atRect.size.width = (W - 2 * HSPACE - 2 * MARGIN) / 3;
        FitH(atRect);
        if (at / 3 == 0) {
            atRect.origin.y = H/2 - atRect.size.height/2 - VSPACE - atRect.size.height;
        } else if (at / 3 == 1) {
            atRect.origin.y = H/2 - atRect.size.height/2;
        } else {
            atRect.origin.y = H/2 + atRect.size.height/2 + VSPACE;
        }
        
        if (at % 3 == 0) {
            atRect.origin.x = MARGIN;
        } else if (at % 3 == 1) {
            atRect.origin.x = W/2 - atRect.size.width/2;
        } else {
            atRect.origin.x = W - atRect.size.width - MARGIN;
        }
        return atRect;
    }
    return atRect;
}

@end
