//
//  SQAudioEncoder.h
//  CPDemo
//
//  Created by Sem on 2020/8/13.
//  Copyright © 2020 SEM. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "SQAVConfig.h"
NS_ASSUME_NONNULL_BEGIN

@protocol SQAudioEncoderDelegate<NSObject>
-(void)audioEncodeCallBack:(NSData *)aacData;
@end
@interface SQAudioEncoder : NSObject
/**编码器配置*/
@property (nonatomic, strong) SQAudioConfig *config;
@property (nonatomic, weak) id<SQAudioEncoderDelegate> delegate;

/**初始化传入编码器配置*/
- (instancetype)initWithConfig:(SQAudioConfig*)config;

/**编码*/
- (void)encodeAudioSamepleBuffer: (CMSampleBufferRef)sampleBuffer;
@end

NS_ASSUME_NONNULL_END
