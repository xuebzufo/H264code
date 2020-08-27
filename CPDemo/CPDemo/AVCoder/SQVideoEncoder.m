//
//  SQVideoEncoder.m
//  CPDemo
//
//  Created by Sem on 2020/8/10.
//  Copyright © 2020 SEM. All rights reserved.
//

#import "SQVideoEncoder.h"
#import <VideoToolbox/VideoToolbox.h>

@interface SQVideoEncoder ()
//编码队列
@property (nonatomic, strong) dispatch_queue_t encodeQueue;
//回调队列
@property (nonatomic, strong) dispatch_queue_t callbackQueue;
/**编码会话*/
@property (nonatomic) VTCompressionSessionRef encodeSesion;

@end
@implementation SQVideoEncoder{
    long frameID;   //帧的递增序标识
    BOOL hasSpsPps;//判断是否已经获取到pps和sps
}
- (instancetype)initWithConfig:(SQVideoConfig*)config{
    self = [super init];
    if(self){
        _config = config;
        _encodeQueue = dispatch_queue_create("h264 hard encode queue", DISPATCH_QUEUE_SERIAL);
        _callbackQueue = dispatch_queue_create("h264 hard encode callback queue", DISPATCH_QUEUE_SERIAL);
        
        //创建编码会话
        /*
            参数1:allocator 分配器，使用null 就是用默认的
            参数2: width 视频帧的像素宽度
            参数3: height 视频帧的像素高度
            参数4: codecType 编解码器类型 这里使用 H264
            参数5：encoderSpecification 特殊的视频编码器 null就是VideoToolbox自己选择一种编码器。
            参数6:sourceImageBufferAttributes 源像素缓冲区如果不希望VideoToolbox为您创建一个，请传递NULL
            参数7:compressedDataAllocator用于压缩数据的分配器。传递NULL以使用默认分配器
            参数8： outputCallback要用压缩帧调用的回调
            参数9:outputCallbackRefCon 客户端为输出回调定义的引用值 回调是c函数不是oc方法，所以没有默认的self参数
            参数10:compressionSessionOut 要创建的会话闯入地址值。
         */
        OSStatus status  = VTCompressionSessionCreate(NULL, (int32_t)config.width, (int32_t)config.height, kCMVideoCodecType_H264, NULL, NULL, NULL, VideoEncodeCallback, (__bridge void *_Nullable)self, &_encodeSesion);
        if(status!=noErr){
            NSLog(@"VTCompressionSession create failed. status=%d", (int)status);
            return self;
        }
        //指示是否建议视频编码器实时执行压缩
        status  =  VTSessionSetProperty(_encodeSesion, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
        NSLog(@"VTSessionSetProperty: set RealTime return: %d", (int)status);
        //指定编码比特流的配置文件和级别。直播一般使用baseline，可减少由于b帧带来的延时
        status = VTSessionSetProperty(_encodeSesion, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_Baseline_AutoLevel);
        NSLog(@"VTSessionSetProperty: set profile return: %d", (int)status);
        //设置码率均值(比特率可以高于此。默认比特率为零，表示视频编码器。应该确定压缩数据的大小。注意，比特率设置只在定时时有效）
        CFNumberRef bit = (__bridge CFNumberRef)@(_config.bitrate);
        status = VTSessionSetProperty(_encodeSesion, kVTCompressionPropertyKey_AverageBitRate, bit);
        NSLog(@"VTSessionSetProperty: set AverageBitRate return: %d", (int)status);
        //码率限制(只在定时时起作用)*待确认
        CFArrayRef limits = (__bridge CFArrayRef)@[@(_config.bitrate / 4), @(_config.bitrate * 4)];
        status = VTSessionSetProperty(_encodeSesion, kVTCompressionPropertyKey_DataRateLimits,limits);
        NSLog(@"VTSessionSetProperty: set DataRateLimits return: %d", (int)status);
        //设置关键帧间隔(GOPSize)GOP太大图像会模糊
        CFNumberRef maxKeyFrameInterval = (__bridge CFNumberRef)@(_config.fps * 2);
        status = VTSessionSetProperty(_encodeSesion, kVTCompressionPropertyKey_MaxKeyFrameInterval, maxKeyFrameInterval);
        NSLog(@"VTSessionSetProperty: set MaxKeyFrameInterval return: %d", (int)status);
        //设置fps(预期)
        CFNumberRef expectedFrameRate = (__bridge CFNumberRef)@(_config.fps);
        status = VTSessionSetProperty(_encodeSesion, kVTCompressionPropertyKey_ExpectedFrameRate, expectedFrameRate);
        NSLog(@"VTSessionSetProperty: set ExpectedFrameRate return: %d", (int)status);
        //准备编码
        status = VTCompressionSessionPrepareToEncodeFrames(_encodeSesion);
        NSLog(@"VTSessionSetProperty: set PrepareToEncodeFrames return: %d", (int)status);
    }
    return self;
}
// startCode 长度 4
const Byte startCode[] = "\x00\x00\x00\x01";
void VideoEncodeCallback(
void * CM_NULLABLE outputCallbackRefCon,
void * CM_NULLABLE sourceFrameRefCon,
OSStatus status,
VTEncodeInfoFlags infoFlags,
CM_NULLABLE CMSampleBufferRef sampleBuffer ){
    if(status != noErr){
        NSLog(@"VideoEncodeCallback: encode error, status = %d", (int)status);
        return;
    }
    if(!CMSampleBufferDataIsReady(sampleBuffer)){
        NSLog(@"VideoEncodeCallback: data is not ready");
        return;
    }
    SQVideoEncoder *encoder = (__bridge SQVideoEncoder *)(outputCallbackRefCon);
    BOOL keyFrame =NO;
    CFArrayRef attachArray = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true);
    keyFrame = !CFDictionaryContainsKey(CFArrayGetValueAtIndex(attachArray, 0), kCMSampleAttachmentKey_NotSync);//(注意取反符号)
    if(keyFrame && !encoder->hasSpsPps){
        size_t spsSize, spsCount;
        size_t ppsSize, ppsCount;
        const uint8_t *spsData, *ppsData;
        CMFormatDescriptionRef formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer);
        OSStatus status1 = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(formatDesc, 0, &spsData, &spsSize, &spsCount, 0);
        OSStatus status2 = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(formatDesc, 1, &ppsData, &ppsSize, &ppsCount, 0);
        //判断sps/pps获取成功
               if (status1 == noErr & status2 == noErr) {
                   
                   NSLog(@"VideoEncodeCallback： get sps, pps success");
                   encoder->hasSpsPps = true;
                   //sps data
                   NSMutableData *sps = [NSMutableData dataWithCapacity:4 + spsSize];
                   [sps appendBytes:startCode length:4];
                   [sps appendBytes:spsData length:spsSize];
                   //pps data
                   NSMutableData *pps = [NSMutableData dataWithCapacity:4 + ppsSize];
                   [pps appendBytes:startCode length:4];
                   [pps appendBytes:ppsData length:ppsSize];
                   
                   dispatch_async(encoder.callbackQueue, ^{
                       //回调方法传递sps/pps
                       [encoder.delegate videoEncodeCallbacksps:sps pps:pps];
                   });
                   
               } else {
                   NSLog(@"VideoEncodeCallback： get sps/pps failed spsStatus=%d, ppsStatus=%d", (int)status1, (int)status2);
               }
    }
    //获取NALU数据
    size_t lengthAtOffset, totalLength;
    char *dataPoint;
    CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    OSStatus error = CMBlockBufferGetDataPointer(blockBuffer, 0, &lengthAtOffset, &totalLength, &dataPoint);
    if (error != kCMBlockBufferNoErr) {
        NSLog(@"VideoEncodeCallback: get datapoint failed, status = %d", (int)error);
        return;
    }
    size_t offet = 0;
    const int lengthInfoSize =4 ;
    while (offet < totalLength - lengthInfoSize) {
        uint32_t naluLength = 0;
        memcpy(&naluLength, dataPoint+offet, lengthInfoSize);
        naluLength = CFSwapInt32BigToHost(naluLength);
        NSMutableData *data = [NSMutableData dataWithCapacity:4 + naluLength];
        [data appendBytes:startCode length:4];
        [data appendBytes:dataPoint+offet+lengthInfoSize length:naluLength];
        dispatch_async(encoder.callbackQueue, ^{
            [encoder.delegate videoEncodeCallback:data];
        });
        offet +=naluLength +lengthInfoSize;
    }
}
/**编码*/
-(void)encodeVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    CFRetain(sampleBuffer);
    dispatch_async(_encodeQueue, ^{
        CVImageBufferRef imageBuffer = (CVImageBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
        self->frameID++;
        CMTime timeStamp = CMTimeMake(self->frameID, 1000);
        //持续时间
        CMTime duration = kCMTimeInvalid;
        VTEncodeInfoFlags flags;
        OSStatus status = VTCompressionSessionEncodeFrame(self.encodeSesion, imageBuffer, timeStamp, duration, NULL, NULL, &flags);
        if (status != noErr) {
            NSLog(@"VTCompression: encode failed: status=%d",(int)status);
        }
        CFRelease(sampleBuffer);
    });
}
- (void)dealloc
{
    if(_encodeSesion){
        VTCompressionSessionCompleteFrames(_encodeSesion, kCMTimeInvalid);
        VTCompressionSessionInvalidate(_encodeSesion);
        CFRelease(_encodeSesion);
        _encodeSesion = NULL;
    }
}
@end
