//
//  ViewController.m
//  CPDemo
//
//  Created by Sem on 2020/8/10.
//  Copyright © 2020 SEM. All rights reserved.
//

#import "ViewController.h"
#import "SQSystemCapture.h"
#import "SQVideoDecoder.h"
#import "SQVideoEncoder.h"
#import "SQLayer.h"
#import "SQAudioEncoder.h"
#import "SQAudioDecode.h"
#import "SQAudioPlay.h"
#define HBUFC_BUFFER_SIZE 2048  //一次最大读取的字节


//#import "AAPLEAGLLayer.h"
@interface ViewController ()<SQSystemCaptureDelegate,SQVideoDecoderDelegate,SQVideoEncoderDelegate,SQAudioEncoderDelegate,SQAudioDecoderDelegate,NSStreamDelegate>
@property(nonatomic,strong)SQSystemCapture *capture;
@property(nonatomic)NSInputStream*inputStream;
@property (nonatomic, strong) NSFileHandle *handle;
@property (nonatomic, copy) NSString *path;
@property(nonatomic,strong) SQVideoDecoder *videoDecoder;
@property(nonatomic,strong) SQVideoEncoder *videoEncoder;
@property(nonatomic,strong)SQAudioEncoder *audioEncoder;
@property(nonatomic,copy) SQLayer *showLayer;
@property (nonatomic, strong) SQAudioDecode *audioDecoder;
@property (nonatomic, strong) SQAudioPlay *pcmPlayer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self testVideo];
    // Do any additional setup after loading the view.
}

-(void)testVideo{
    _path = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).lastObject stringByAppendingPathComponent:@"h264test.h264"];
    NSFileManager *manager =  [NSFileManager defaultManager];
    if([manager fileExistsAtPath:_path]){
        if ([manager removeItemAtPath:_path error:nil]) {
            NSLog(@"删除成功");
            if ([manager createFileAtPath:_path contents:nil attributes:nil]) {
                NSLog(@"创建文件");
            }
        }
    }else {
        if ([manager createFileAtPath:_path contents:nil attributes:nil]) {
            NSLog(@"创建文件");
        }
    }
    NSLog(@"%@", _path);
    _handle = [NSFileHandle fileHandleForWritingAtPath:_path];
    [SQSystemCapture checkCameraAuthor];
    _capture = [[SQSystemCapture alloc]initWithType:SQSystemCaptrueTypeAll];
    CGSize size = CGSizeMake(self.view.frame.size.width/2, self.view.frame.size.height/2);
    [_capture prepareWithPreviewSize:size];
    _capture.preview.frame = CGRectMake(0, 100, size.width, size.height);
    [self.view addSubview:_capture.preview];
    self.capture.delegate =self;
    SQVideoConfig *config = [SQVideoConfig defaultConifg];
    config.width = _capture.witdh;
    config.height =_capture.height;
    config.bitrate =config.width*config.height*5;
    
    _videoEncoder =[[SQVideoEncoder alloc]initWithConfig:config];
    _videoEncoder.delegate =self;
    _videoDecoder =[[SQVideoDecoder alloc]initWithConfig:config];
    _videoDecoder.delegate=self;
   
    SQAudioConfig *aConfig = [SQAudioConfig defaultConifg];
     _audioEncoder =[[SQAudioEncoder alloc]initWithConfig:aConfig] ;
    _audioEncoder.delegate =self;
    
    _audioDecoder  = [[SQAudioDecode alloc]initWithConfig:[SQAudioConfig defaultConifg]];
    _audioDecoder.delegate =self;
    _showLayer =[[SQLayer alloc]initWithFrame:CGRectMake(size.width, 100, size.width, size.height)];
    [self.view.layer addSublayer:_showLayer];
     _pcmPlayer = [[SQAudioPlay alloc]initWithConfig:[SQAudioConfig defaultConifg]];
    
    
}
-(void)audioEncodeCallBack:(NSData *)aacData{
    [_audioDecoder decodeAudioAACData:aacData];
}
- (void)audioDecodeCallback:(NSData *)pcmData{
    [_handle seekToEndOfFile];
    [_handle writeData:pcmData];
}
-(void)captureSampleBuffer:(CMSampleBufferRef )sampleBuffer withType:(SQSystemCaptrueType)type{
    if(type == SQSystemCaptrueTypeAudio){
        [_audioEncoder encodeAudioSamepleBuffer:sampleBuffer];
    }else{
        [_videoEncoder encodeVideoSampleBuffer:sampleBuffer];
    }
}

//解码后H264数据回调
- (void)videoDecodeCallback:(CVPixelBufferRef)imageBuffer{
    if (imageBuffer) {
        _showLayer.pixelBuffer = imageBuffer;
    }
}
//Video-H264数据编码完成回调
- (void)videoEncodeCallback:(NSData *)h264Data{
    [_videoDecoder decodeNaluData:h264Data];
}
//Video-SPS&PPS数据编码回调
- (void)videoEncodeCallbacksps:(NSData *)sps pps:(NSData *)pps{
    [_videoDecoder decodeNaluData:sps];
    [_videoDecoder decodeNaluData:pps];
}
//开始捕捉
- (IBAction)startCapture:(id)sender {
     [self.capture start];
}

//结束捕捉
- (IBAction)stopCapture:(id)sender {
    [self.capture stop];
    [self playAudio];
}
-(void)playAudio{
    
}
//关闭文件

- (IBAction)closeFile:(id)sender {
     //[_handle closeFile];
     self.inputStream= [[NSInputStream alloc]initWithFileAtPath:_path];

     [self.inputStream setDelegate:self];
    [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop]forMode:NSDefaultRunLoopMode];

    [self.inputStream open];
    
      
}
- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode{
    switch(eventCode) {

    // 有有效读取字节的时候进入这个case,一次性将所有的流进入

    case NSStreamEventHasBytesAvailable:{

        // 将HBUFC_BUFFER_SIZE 大小的字节流放入到缓存数组hbufc_file_buffer中
         uint8_t hbufc_file_buffer[HBUFC_BUFFER_SIZE];
        long bytes = [(NSInputStream*)stream read:hbufc_file_buffer maxLength:1024];

        // 进行循环的读取，注意每次data取的是读取到的字节数 而不是最大字节数即bytes

        while(bytes >0) {

            NSData *data = [NSData dataWithBytes:hbufc_file_buffer length:bytes];

                [_pcmPlayer playPCMData:data];

            bytes = [(NSInputStream*)stream read:hbufc_file_buffer maxLength:1024];

        }

    }

    break;

    // 流读取完毕后，进入这个case 将流关闭，并且从runloop中移除

    case NSStreamEventEndEncountered:{

     

        [stream close];

        [stream removeFromRunLoop:[NSRunLoop currentRunLoop]forMode:NSDefaultRunLoopMode];

        stream =nil;

    }

    break;

    default:

    break;
  }
}
@end
