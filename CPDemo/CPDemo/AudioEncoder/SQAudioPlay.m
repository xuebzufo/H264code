//
//  SQAudioPlay.m
//  CPDemo
//
//  Created by Sem on 2020/8/14.
//  Copyright © 2020 SEM. All rights reserved.
//

#import "SQAudioPlay.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "SQAVConfig.h"
#import "SQAudioDataQueue.h"
#define MIN_SIZE_PER_FRAME 2048 //每帧最小数据长度
static const int kNumberBuffers_play = 3;
typedef struct AQPlayerSatae{
    AudioStreamBasicDescription   mDataFormat;                    // 2
    AudioQueueRef                 mQueue;                         // 3
    AudioQueueBufferRef           mBuffers[kNumberBuffers_play];       // 4
    AudioStreamPacketDescription  *mPacketDescs;                  // 9
}AQPlayerState;
@interface SQAudioPlay ()
@property (nonatomic, assign) AQPlayerState aqps;
@property (nonatomic, strong) SQAudioConfig *config;
@property (nonatomic, assign) BOOL isPlaying;
@end

@implementation SQAudioPlay
- (instancetype)initWithConfig:(SQAudioConfig *)config{
    if(self = [super init]){
        _config = config;
        AudioStreamBasicDescription dataFormat = {0};
        dataFormat.mSampleRate = (Float64)_config.sampleRate;
        dataFormat.mChannelsPerFrame = (UInt32)_config.channelCount; //输出声道数
        dataFormat.mFormatID = kAudioFormatLinearPCM;
        dataFormat.mFormatFlags = (kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked);
        dataFormat.mFramesPerPacket =1;
        dataFormat.mBitsPerChannel =16;
        dataFormat.mBytesPerFrame = dataFormat.mBitsPerChannel / 8 *dataFormat.mChannelsPerFrame;
        dataFormat.mBytesPerPacket = dataFormat.mBytesPerFrame * dataFormat.mFramesPerPacket;   
        dataFormat.mReserved =  0;
        AQPlayerState state = {0};
        state.mDataFormat = dataFormat;
        _aqps = state;
        [self setupSeesion];
        OSStatus status = AudioQueueNewOutput(&_aqps.mDataFormat, TMAudioQueueOutputCallback, NULL, NULL, NULL, 0, &_aqps.mQueue);
        if (status != noErr) {
            NSError *error = [[NSError alloc] initWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
            NSLog(@"Error: AudioQueue create error = %@", [error description]);
            return self;
        }
        
        [self setupVoice:1];
        _isPlaying = false;
    }
    return self;
}
static void TMAudioQueueOutputCallback(void * inUserData, AudioQueueRef inAQ, AudioQueueBufferRef inBuffer) {
   
    AudioQueueFreeBuffer(inAQ, inBuffer);
}
-(void)setupSeesion{
    NSError *error = nil;
    [[AVAudioSession sharedInstance]setActive:YES error:&error];
    if (error) {
        NSLog(@"Error: audioQueue palyer AVAudioSession error, error: %@", error);
    }
    [[AVAudioSession sharedInstance]setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    if (error) {
           NSLog(@"Error: audioQueue palyer AVAudioSession error, error: %@", error);
       }
}
/**播放pcm*/
- (void)playPCMData:(NSData *)data{
    AudioQueueBufferRef inBuffer;
    AudioQueueAllocateBuffer(_aqps.mQueue, MIN_SIZE_PER_FRAME, &inBuffer);
    memcpy(inBuffer->mAudioData, data.bytes, data.length);
    inBuffer->mAudioDataByteSize =  (UInt32)data.length;
    OSStatus status = AudioQueueEnqueueBuffer(_aqps.mQueue, inBuffer, 0, NULL);
    if (status != noErr) {
        NSLog(@"Error: audio queue palyer  enqueue error: %d",(int)status);
    }
    
    //开始播放或录制音频
    /*
     参数1:要开始的音频队列
     参数2:音频队列应开始的时间。
     要指定相对于关联音频设备时间线的开始时间，请使用audioTimestamp结构的msampletime字段。使用NULL表示音频队列应尽快启动
     */
    AudioQueueStart(_aqps.mQueue, NULL);
}
/** 设置音量增量 0.0 - 1.0 */
- (void)setupVoice:(Float32)gain{
    Float32 gain0 =gain;
    if(gain < 0){
        gain0 = 0 ;
    }else if (gain0 > 1){
        gain0 = 1;
    }
    AudioQueueSetParameter(_aqps.mQueue, kAudioQueueParam_Volume, gain0);
}
/**销毁 */
- (void)dispose{
    AudioQueueStop(_aqps.mQueue, true);
    AudioQueueDispose(_aqps.mQueue, true);
}
@end
