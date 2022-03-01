#import "LrcParser.h"

@interface LrcParser ()

@end

@implementation LrcParser

-(instancetype) init{
    self = [super init];
    if(self != nil){
        self.timerArray = [[NSMutableArray alloc] init];
        self.wordArray = [[NSMutableArray alloc] init];
    }
    return  self;
}

-(void)parseLrc:(NSString*)lrcFileName {
    NSString* filePath = [[NSBundle mainBundle] pathForResource:lrcFileName ofType:@"lrc"];
    NSString* lrcContents = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    
    if(![lrcContents isEqual:nil]){
        NSArray *sepArray = [lrcContents componentsSeparatedByString:@"["];
        NSArray *lineArray = [[NSArray alloc] init];
        for(int i = 0 ; i < sepArray.count ; i++){
            if([sepArray[i] length] > 0){
                lineArray = [sepArray[i] componentsSeparatedByString:@"]"];
                if(![lineArray[0] isEqualToString:@"\n"]){
                    [self.timerArray addObject:lineArray[0]];
                    [self.wordArray addObject:lineArray.count > 1 ? lineArray[1] : @""];
                }
            }
        }
    }
}

@end
