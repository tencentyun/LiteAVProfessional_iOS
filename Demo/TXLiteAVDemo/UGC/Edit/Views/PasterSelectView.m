//
//  PasterSelectView.m
//  TXLiteAVDemo
//
//  Created by xiang zhang on 2017/10/31.
//  Copyright © 2017年 Tencent. All rights reserved.
//

#import "PasterSelectView.h"
#import "UIView+Additions.h"

#define PASTER_SPACE  20

@implementation PasterQipaoInfo
@end

@implementation PasterAnimateInfo
@end

@implementation PasterStaticInfo
@end

@interface PasterSelectView () <UIScrollViewDelegate>
@end

@implementation PasterSelectView
{
    UIScrollView * _selectView;
    NSArray *      _pasterList;
    NSString *     _bundlePath;
    PasterType     _pasterType;
    dispatch_queue_t _pasterPreloadQueue;
    NSMutableDictionary<NSNumber*, PasterAnimateInfo*> *_animatedPasterArrayCache;
}

- (instancetype) initWithFrame:(CGRect)frame
                    pasterType:(PasterType)pasterType
                     boundPath:(NSString *)boundPath
{
    self = [super initWithFrame:frame];
    if (self) {
        _pasterPreloadQueue = dispatch_queue_create("paste_pre_load", DISPATCH_QUEUE_CONCURRENT);
        _animatedPasterArrayCache = [[NSMutableDictionary alloc] init];
        
        _pasterType =pasterType;
        _bundlePath = boundPath;
        
        _selectView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.width, self.height)];
        _selectView.backgroundColor = [UIColor grayColor];
        _selectView.delegate = self;
        [self addSubview:_selectView];
        
        NSData *jsonData = [NSData dataWithContentsOfFile:[_bundlePath stringByAppendingPathComponent:@"config.json"]];
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:nil];
        _pasterList = dic[@"pasterList"];

        _selectView.contentSize = CGSizeMake((PASTER_SPACE + self.height) * _pasterList.count, self.height);
        
        NSMutableIndexSet *indices = [[NSMutableIndexSet alloc] init];
        for (int i = 0; i < _pasterList.count; i ++) {
            NSString *qipaoIconPath = [boundPath stringByAppendingPathComponent:_pasterList[i][@"icon"]];
            UIImage *qipaoIconImage = [UIImage imageWithContentsOfFile:qipaoIconPath];
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
            [btn setFrame:CGRectMake(PASTER_SPACE + i  * (self.height + PASTER_SPACE),0, self.height, self.height)];
            [btn setImage:qipaoIconImage forState:UIControlStateNormal];
            [btn addTarget:self action:@selector(selectBubble:) forControlEvents:UIControlEventTouchUpInside];
            btn.tag = i;
            if (CGRectGetMinX(btn.frame) <= _selectView.width) {
                [indices addIndex:i];
            }
            [_selectView addSubview:btn];
        }
        [self preloadImages:indices];
    }
    return self;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self preloadImageWhenScrollStop];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self preloadImageWhenScrollStop];
}

- (void)preloadImageWhenScrollStop {
    NSMutableIndexSet *toPreloadIndices = [[NSMutableIndexSet alloc] init];
    NSMutableIndexSet *visibleIndices = [[NSMutableIndexSet alloc] init];
    for (UIButton *btn in _selectView.subviews) {
        if (![btn isKindOfClass:[UIButton class]]) {
            continue;
        }
        if (CGRectIntersectsRect(_selectView.bounds, btn.frame)) {
            if (_animatedPasterArrayCache[@(btn.tag)] == nil) {
                [toPreloadIndices addIndex:btn.tag];
            }
            [visibleIndices addIndex:btn.tag];
        }
    }
    NSMutableArray *invisibleKeys =  [[_animatedPasterArrayCache allKeys] mutableCopy];
    [visibleIndices enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        [invisibleKeys removeObject:@(idx)];
    }];
    [_animatedPasterArrayCache removeObjectsForKeys:invisibleKeys];
    [self preloadImages:toPreloadIndices];
}

- (void)preloadImages:(NSIndexSet *)indices {
    dispatch_async(_pasterPreloadQueue, ^{
        [indices enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
            NSDictionary *item = _pasterList[idx];
            NSString *name = item[@"name"];
            NSString *pasterPath = [_bundlePath stringByAppendingPathComponent:name];
            NSData *configData = [NSData dataWithContentsOfFile:[pasterPath stringByAppendingPathComponent:@"config.json"]];
            NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:configData options:NSJSONReadingAllowFragments error:nil];
            NSArray *imagePathList = dic[@"frameArry"];
            NSMutableArray *imageList = [NSMutableArray array];
            for (NSDictionary *dic in imagePathList) {
                NSString *imageName = dic[@"picture"];
                UIImage *image = [UIImage imageWithContentsOfFile:[pasterPath stringByAppendingPathComponent:imageName]];
                [imageList addObject:image];
            }
            
            PasterAnimateInfo *info = [PasterAnimateInfo new];
            info.imageList = imageList;
            info.path = pasterPath;
            info.width = [dic[@"width"] floatValue];
            info.height = [dic[@"height"] floatValue];
            info.duration = [dic[@"period"] floatValue] / 1000.0;
            NSString *qipaoIconPath = [_bundlePath stringByAppendingPathComponent:item[@"icon"]];
            info.iconImage = [UIImage imageWithContentsOfFile:qipaoIconPath];
            _animatedPasterArrayCache[@(idx)] = info;
        }];
    });
}

- (void)selectBubble:(UIButton *)btn
{
    switch (_pasterType) {
        case PasterType_Qipao:
        {
            NSString *qipaoPath = [_bundlePath stringByAppendingPathComponent:_pasterList[btn.tag][@"name"]];
            NSString *jsonString = [NSString stringWithContentsOfFile:[qipaoPath stringByAppendingPathComponent:@"config.json"] encoding:NSUTF8StringEncoding error:nil];
            NSDictionary *dic = [self dictionaryWithJsonString:jsonString];
            
            PasterQipaoInfo *info = [PasterQipaoInfo new];
            info.image = [UIImage imageNamed:[qipaoPath stringByAppendingPathComponent:dic[@"name"]]];
            info.width = [dic[@"width"] floatValue];
            info.height = [dic[@"height"] floatValue];
            info.textTop = [dic[@"textTop"] floatValue];
            info.textLeft = [dic[@"textLeft"] floatValue];
            info.textRight = [dic[@"textRight"] floatValue];
            info.textBottom = [dic[@"textBottom"] floatValue];
            info.iconImage = btn.imageView.image;
            [self.delegate onPasterQipaoSelect:info];
        }
            break;
            
        case PasterType_Animate:
        {
            __block PasterAnimateInfo *info = nil;
            dispatch_barrier_sync(_pasterPreloadQueue, ^{
                info = _animatedPasterArrayCache[@(btn.tag)];
            });
            if (info == nil) {
                [self preloadImages:[NSIndexSet indexSetWithIndex:btn.tag]];
                dispatch_barrier_sync(_pasterPreloadQueue, ^{
                    info = _animatedPasterArrayCache[@(btn.tag)];
                });
            }
            [self.delegate onPasterAnimateSelect:info];
        }
            break;
            
        case PasterType_static:
        {
            NSString *pasterPath = [_bundlePath stringByAppendingPathComponent:_pasterList[btn.tag][@"name"]];
            NSString *jsonString = [NSString stringWithContentsOfFile:[pasterPath stringByAppendingPathComponent:@"config.json"] encoding:NSUTF8StringEncoding error:nil];
            NSDictionary *dic = [self dictionaryWithJsonString:jsonString];
     
            PasterStaticInfo *info = [[PasterStaticInfo alloc] init];;
            info.image = [UIImage imageNamed:[pasterPath stringByAppendingPathComponent:dic[@"name"]]];
            info.width = [dic[@"width"] floatValue];
            info.height = [dic[@"height"] floatValue];
            info.iconImage = btn.imageView.image;
            [self.delegate onPasterStaticSelect:info];
        }
            break;
            
        default:
            break;
    }
}

- (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString {
    if (jsonString == nil) {
        return nil;
    }
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                        options:NSJSONReadingMutableContainers
                                                          error:&err];
    if(err) {
        NSLog(@"json解析失败：%@",err);
        return nil;
    }
    return dic;
}
@end
