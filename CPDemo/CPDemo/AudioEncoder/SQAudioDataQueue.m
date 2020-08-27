//
//  SQAudioDataQueue.m
//  CPDemo
//
//  Created by Sem on 2020/8/14.
//  Copyright © 2020 SEM. All rights reserved.
//

#import "SQAudioDataQueue.h"

@interface SQAudioDataQueue ()
@property (nonatomic, strong) NSMutableArray *bufferArray;
@end


@implementation SQAudioDataQueue
@synthesize count;
static SQAudioDataQueue *_instance = nil;
+(instancetype) shareInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc]init];
    });
    return _instance;
}
-(instancetype)init{
    if(self = [super init]){
        _bufferArray = [NSMutableArray array];
        count = 0;
    }
    return  self;
}
-(void)addData:(id)obj{
    @synchronized (_bufferArray) {
        [_bufferArray addObject:obj];
        count = (int)_bufferArray.count;
    }
}
- (id)getData{
    @synchronized (_bufferArray) {
        id obj =nil;
        if(count){
            obj = [_bufferArray firstObject];
            [_bufferArray removeObject:obj];
            count = (int)_bufferArray.count;
        }
        return obj;
    }
}
@end
