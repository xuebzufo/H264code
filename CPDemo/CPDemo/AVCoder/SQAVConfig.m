//
//  SQAVConfig.m
//  CPDemo
//
//  Created by Sem on 2020/8/10.
//  Copyright © 2020 SEM. All rights reserved.
//

#import "SQAVConfig.h"

@implementation SQAudioConfig
+ (instancetype)defaultConifg {
    return  [[SQAudioConfig alloc] init];
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.bitrate = 96000;
        self.channelCount = 1;
        self.sampleSize = 16;
        self.sampleRate = 44100;
    }
    return self;
}
@end
@implementation SQVideoConfig
{
    void (*task)(void);
}
+ (instancetype)defaultConifg {
    return [[SQVideoConfig alloc] init];
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.width = 480;
        self.height = 640;
        self.bitrate = 640*1000;
        self.fps = 25;
       
    }
    return self;
}
void run(){
    NSLog(@"run");
}

@end
