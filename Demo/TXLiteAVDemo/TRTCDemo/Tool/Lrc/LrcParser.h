#import <Foundation/Foundation.h>

@interface LrcParser : NSObject

//时间
@property (nonatomic,strong) NSMutableArray *timerArray;
//歌词
@property (nonatomic,strong) NSMutableArray *wordArray;


//解析歌词
-(void) parseLrc:(NSString*)lrcFileName;
@end
