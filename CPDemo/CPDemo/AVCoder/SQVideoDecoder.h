//
//  SQVideoDecoder.h
//  CPDemo
//
//  Created by Sem on 2020/8/10.
//  Copyright © 2020 SEM. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "SQAVConfig.h"
NS_ASSUME_NONNULL_BEGIN
@protocol SQVideoDecoderDelegate <NSObject>
//解码后H264数据回调
- (void)videoDecodeCallback:(CVPixelBufferRef)imageBuffer;


@end
@interface SQVideoDecoder : NSObject
@property (nonatomic, strong) SQVideoConfig *config;
@property (nonatomic, weak) id<SQVideoDecoderDelegate> delegate;
/**初始化解码器**/
- (instancetype)initWithConfig:(SQVideoConfig*)config;
-(void)decodeNaluData:(NSData *)frame;
@end

NS_ASSUME_NONNULL_END
