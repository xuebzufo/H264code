//
//  SQAudioDecode.h
//  CPDemo
//
//  Created by Sem on 2020/8/13.
//  Copyright © 2020 SEM. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
@class SQAudioConfig;

NS_ASSUME_NONNULL_BEGIN
/**AAC解码回调代理*/
@protocol SQAudioDecoderDelegate <NSObject>
- (void)audioDecodeCallback:(NSData *)pcmData;
@end
@interface SQAudioDecode : NSObject
@property (nonatomic, strong) SQAudioConfig *config;
@property (nonatomic, weak) id<SQAudioDecoderDelegate> delegate;

//初始化 传入解码配置
- (instancetype)initWithConfig:(SQAudioConfig *)config;

/**解码aac*/
- (void)decodeAudioAACData: (NSData *)aacData;
@end

NS_ASSUME_NONNULL_END
