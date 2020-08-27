//
//  SQAudioPlay.h
//  CPDemo
//
//  Created by Sem on 2020/8/14.
//  Copyright © 2020 SEM. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class SQAudioConfig;
@interface SQAudioPlay : NSObject
- (instancetype)initWithConfig:(SQAudioConfig *)config;
/**播放pcm*/
- (void)playPCMData:(NSData *)data;
/** 设置音量增量 0.0 - 1.0 */
- (void)setupVoice:(Float32)gain;
/**销毁 */
- (void)dispose;

@end

NS_ASSUME_NONNULL_END
