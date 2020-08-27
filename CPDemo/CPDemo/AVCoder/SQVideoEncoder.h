//
//  SQVideoEncoder.h
//  CPDemo
//
//  Created by Sem on 2020/8/10.
//  Copyright © 2020 SEM. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "SQAVConfig.h"
NS_ASSUME_NONNULL_BEGIN
/**h264编码回调代理*/
@protocol SQVideoEncoderDelegate <NSObject>
//Video-H264数据编码完成回调
- (void)videoEncodeCallback:(NSData *)h264Data;
//Video-SPS&PPS数据编码回调
- (void)videoEncodeCallbacksps:(NSData *)sps pps:(NSData *)pps;
@end
@interface SQVideoEncoder : NSObject
@property(nonatomic,strong)SQVideoConfig *config;
@property(nonatomic,weak)id<SQVideoEncoderDelegate>delegate;

- (instancetype)initWithConfig:(SQVideoConfig*)config;
/**编码*/
-(void)encodeVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer;
@end

NS_ASSUME_NONNULL_END
