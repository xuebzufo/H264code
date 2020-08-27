//
//  SQAudioEncoder.m
//  CPDemo
//
//  Created by Sem on 2020/8/13.
//  Copyright © 2020 SEM. All rights reserved.
//

#import "SQAudioEncoder.h"
#import "SQAVConfig.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
@interface SQAudioEncoder()

@property (nonatomic, strong) dispatch_queue_t encoderQueue;
@property (nonatomic, strong) dispatch_queue_t callbackQueue;

//对音频转换器对象
@property (nonatomic, unsafe_unretained) AudioConverterRef audioConverter;
//PCM缓存区
@property (nonatomic) char *pcmBuffer;
//PCM缓存区大小
@property (nonatomic) size_t pcmBufferSize;

@end
@implementation SQAudioEncoder
- (instancetype)initWithConfig:(SQAudioConfig*)config{
    self = [super init];
    if(self){
        //音频编码队列
        _encoderQueue = dispatch_queue_create("aac hard encoder queue", DISPATCH_QUEUE_SERIAL);
        //音频回调队列
        _callbackQueue = dispatch_queue_create("aac hard encoder callback queue", DISPATCH_QUEUE_SERIAL);
        //音频转换器
        _audioConverter = NULL;
        _pcmBufferSize = 0;
        _pcmBuffer = NULL;
        _config = config;
        if (config == nil) {
            _config = [[SQAudioConfig alloc] init];
        }
    }
    return self;
}
//配置音频编码参数
-(void)setupEncoderWithSampleBuffer: (CMSampleBufferRef)sampleBuffer{
    AudioStreamBasicDescription inputAduioDes =* CMAudioFormatDescriptionGetStreamBasicDescription(CMSampleBufferGetFormatDescription(sampleBuffer));
    //设置输出参数
    AudioStreamBasicDescription outputAudioDes ={0};
    outputAudioDes.mSampleRate = (Float64)_config.sampleRate;   //采样率
    outputAudioDes.mFormatID = kAudioFormatMPEG4AAC;                //输出格式
    outputAudioDes.mFormatFlags = kMPEG4Object_AAC_LC;              // 如果设为0 代表无损编码
    outputAudioDes.mBytesPerPacket = 0;                             //压缩的时候设置0
    outputAudioDes.mFramesPerPacket = 1024;                         //每一个packet帧数 AAC-1024；
    outputAudioDes.mBytesPerFrame = 0;                              //压缩的时候设置0
    outputAudioDes.mChannelsPerFrame = (uint32_t)_config.channelCount; //输出声道数
    outputAudioDes.mBitsPerChannel = 0;                             //数据帧中每个通道的采样位数。压缩的时候设置0
    outputAudioDes.mReserved =  0;                                  //对其方式 0(8字节对齐)
    //填充输出相关信息
    UInt32 outDesSize = sizeof(outputAudioDes);
    AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, NULL, &outDesSize, &outputAudioDes);
    //获取编码器的描述信息(只能传入software)
    AudioClassDescription *audioClassDesc = [self getAudioCalssDescriptionWithType:outputAudioDes.mFormatID fromManufacture:kAppleSoftwareAudioCodecManufacturer];
    /** 创建converter
        参数1：输入音频格式描述
        参数2：输出音频格式描述
        参数3：class desc的数量
        参数4：class desc
        参数5：创建的解码器
    */
    OSStatus status = AudioConverterNewSpecific(&inputAduioDes, &outputAudioDes, 1, audioClassDesc, &_audioConverter);
    if (status != noErr) {
        NSLog(@"Error！：硬编码AAC创建失败, status= %d", (int)status);
        return;
    }
    // 设置编解码质量
    /*
     kAudioConverterQuality_Max                              = 0x7F,
     kAudioConverterQuality_High                             = 0x60,
     kAudioConverterQuality_Medium                           = 0x40,
     kAudioConverterQuality_Low                              = 0x20,
     kAudioConverterQuality_Min                              = 0
     */
     UInt32 temp = kAudioConverterQuality_High;
     //编解码器的呈现质量
    AudioConverterSetProperty(_audioConverter, kAudioConverterCodecQuality, sizeof(temp), &temp);
    //设置比特率
    uint32_t audioBitrate = (uint32_t)self.config.bitrate;
    uint32_t audioBitrateSize = sizeof(audioBitrate);
    status = AudioConverterSetProperty(_audioConverter, kAudioConverterEncodeBitRate, audioBitrateSize, &audioBitrate);
    if (status != noErr) {
        NSLog(@"Error！：硬编码AAC 设置比特率失败");
    }
}
/**
 获取编码器类型描述
 参数1：类型
 */
- (AudioClassDescription *)getAudioCalssDescriptionWithType: (AudioFormatID)type fromManufacture: (uint32_t)manufacture {
    static AudioClassDescription desc;
      UInt32 encoderSpecific = type;
      
      //获取满足AAC编码器的总大小
      UInt32 size;
      /**
       参数1：编码器类型
       参数2：类型描述大小
       参数3：类型描述
       参数4：大小
       */
      OSStatus status = AudioFormatGetPropertyInfo(kAudioFormatProperty_Encoders, sizeof(encoderSpecific), &encoderSpecific, &size);
    if(status != noErr){
        NSLog(@"Error！：硬编码AAC get info 失败, status= %d", (int)status);
        return nil;
    }
    //计算aac编码器的个数
    unsigned int count = size / sizeof(AudioClassDescription);
    //创建一个包含count个编码器的数组
    AudioClassDescription description[count];
    //将满足aac编码的编码器的信息写入数组
    status = AudioFormatGetProperty(kAudioFormatProperty_Encoders, sizeof(encoderSpecific), &encoderSpecific, &size, &description);
   for (unsigned int i = 0; i < count; i++) {
        if (type == description[i].mSubType && manufacture == description[i].mManufacturer) {
            desc = description[i];
            return &desc;
        }
    }
    return nil;
}
/**编码*/
- (void)encodeAudioSamepleBuffer: (CMSampleBufferRef)sampleBuffer{
    CFRetain(sampleBuffer);
    if(!_audioConverter){
         [self setupEncoderWithSampleBuffer:sampleBuffer];
    }
    __weak typeof(self) weakSelf=self;
    dispatch_async(_encoderQueue, ^{
        //3.获取CMBlockBuffer, 这里面保存了PCM数据
        CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
        CFRetain(blockBuffer);
         OSStatus status = CMBlockBufferGetDataPointer(blockBuffer, 0, NULL, &_pcmBufferSize, &_pcmBuffer);
        //5.判断status状态
        NSError *error = nil;
        if (status != kCMBlockBufferNoErr) {
            error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
            NSLog(@"Error: ACC encode get data point error: %@",error);
            return;
        }
        uint8_t *pcmBuffer = malloc(weakSelf.pcmBufferSize);
        memset(pcmBuffer, 0, weakSelf.pcmBufferSize);
        //3.输出buffer
        /*
         typedef struct AudioBufferList {
         UInt32 mNumberBuffers;
         AudioBuffer mBuffers[1];
         } AudioBufferList;
         
         struct AudioBuffer
         {
         UInt32              mNumberChannels;
         UInt32              mDataByteSize;
         void* __nullable    mData;
         };
         typedef struct AudioBuffer  AudioBuffer;
         */
        //将pcmBuffer数据填充到outAudioBufferList 对象中
        AudioBufferList outAudioBufferList = {0};
        outAudioBufferList.mNumberBuffers = 1;
        outAudioBufferList.mBuffers[0].mNumberChannels = (uint32_t)_config.channelCount;
        outAudioBufferList.mBuffers[0].mDataByteSize = (UInt32)_pcmBufferSize;
        outAudioBufferList.mBuffers[0].mData = pcmBuffer;
        //输出包大小为1
        UInt32 outputDataPacketSize = 1;
        //配置填充函数，获取输出数据
        //转换由输入回调函数提供的数据
        /*
         参数1: inAudioConverter 音频转换器
         参数2: inInputDataProc 回调函数.提供要转换的音频数据的回调函数。当转换器准备好接受新的输入数据时，会重复调用此回调.
         参数3: inInputDataProcUserData
         参数4: inInputDataProcUserData,self
         参数5: ioOutputDataPacketSize,输出缓冲区的大小
         参数6: outOutputData,需要转换的音频数据
         参数7: outPacketDescription,输出包信息
         */
        status = AudioConverterFillComplexBuffer(_audioConverter, aacEncodeInputDataProc, (__bridge void * _Nullable)(self), &outputDataPacketSize, &outAudioBufferList, NULL);
        
        if (status == noErr) {
            //获取数据
            NSData *rawAAC = [NSData dataWithBytes: outAudioBufferList.mBuffers[0].mData length:outAudioBufferList.mBuffers[0].mDataByteSize];
            //释放pcmBuffer
            free(pcmBuffer);
            //添加ADTS头，想要获取裸流时，请忽略添加ADTS头，写入文件时，必须添加
            //            NSData *adtsHeader = [self adtsDataForPacketLength:rawAAC.length];
            //            NSMutableData *fullData = [NSMutableData dataWithCapacity:adtsHeader.length + rawAAC.length];;
            //            [fullData appendData:adtsHeader];
            //            [fullData appendData:rawAAC];
            //将数据传递到回调队列中
            dispatch_async(weakSelf.callbackQueue, ^{
                [_delegate audioEncodeCallBack:rawAAC];
            });
        } else {
            error = [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil];
        }
        
        CFRelease(blockBuffer);
        CFRelease(sampleBuffer);
        if (error) {
            NSLog(@"error: AAC编码失败 %@",error);
        }
    });
}
static OSStatus aacEncodeInputDataProc(AudioConverterRef inAudioConverter, UInt32 *ioNumberDataPackets, AudioBufferList *ioData, AudioStreamPacketDescription **outDataPacketDescription, void *inUserData) {
    //获取self
    SQAudioEncoder *aacEncoder = (__bridge SQAudioEncoder *)(inUserData);
    //判断pcmBuffsize大小
    if (!aacEncoder.pcmBufferSize) {
        *ioNumberDataPackets = 0;
        return  - 1;
    }
    //填充
    ioData->mBuffers[0].mData = aacEncoder.pcmBuffer;
    ioData->mBuffers[0].mDataByteSize = (uint32_t)aacEncoder.pcmBufferSize;
    ioData->mBuffers[0].mNumberChannels = (uint32_t)aacEncoder.config.channelCount;
    
    //填充完毕,则清空数据
    aacEncoder.pcmBufferSize = 0;
    *ioNumberDataPackets = 1;
    return noErr;
}

- (void)dealloc {
    if (_audioConverter) {
        AudioConverterDispose(_audioConverter);
        _audioConverter = NULL;
    }
    
}
@end
