//
//  SQSystemCapture.m
//  CPDemo
//
//  Created by Sem on 2020/8/10.
//  Copyright © 2020 SEM. All rights reserved.
//

#import "SQSystemCapture.h"
@interface SQSystemCapture ()<AVCaptureAudioDataOutputSampleBufferDelegate,AVCaptureVideoDataOutputSampleBufferDelegate>

/********************控制相关**********/
//是否进行
@property (nonatomic, assign) BOOL isRunning;

/********************公共*************/
//会话
@property (nonatomic, strong) AVCaptureSession *captureSession;
//代理队列
@property (nonatomic, strong) dispatch_queue_t captureQueue;

/********************音频相关**********/
//音频设备
@property (nonatomic, strong) AVCaptureDeviceInput *audioInputDevice;
//输出数据接收
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioDataOutput;
@property (nonatomic, strong) AVCaptureConnection *audioConnection;

/********************视频相关**********/
//当前使用的视频设备
@property (nonatomic, weak) AVCaptureDeviceInput *videoInputDevice;
//前后摄像头
@property (nonatomic, strong) AVCaptureDeviceInput *frontCamera;
@property (nonatomic, strong) AVCaptureDeviceInput *backCamera;
//输出数据接收
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic, strong) AVCaptureConnection *videoConnection;
//预览层
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *preLayer;
@property (nonatomic, assign) CGSize prelayerSize;

@end
@implementation SQSystemCapture{
    //捕捉类型
    SQSystemCaptrueType capture;
}
-(dispatch_queue_t)captureQueue{
    if(!_captureQueue){
        _captureQueue = dispatch_queue_create("TMCapture Queue", DISPATCH_QUEUE_SERIAL);
    }
    return _captureQueue;
}
#pragma mark-懒加载
- (AVCaptureSession *)captureSession{
    if (!_captureSession) {
        _captureSession = [[AVCaptureSession alloc] init];
    }
    return _captureSession;
}
- (UIView *)preview{
    if (!_preview) {
        _preview = [[UIView alloc] init];
    }
    return _preview;
}

-(instancetype)initWithType:(SQSystemCaptrueType)type{
    self = [super init];
    if(self){
        capture = type;
    }
    return self;
}
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    if(connection == self.audioConnection){
        
         [_delegate captureSampleBuffer:sampleBuffer withType:SQSystemCaptrueTypeAudio];
    }else{
         [_delegate captureSampleBuffer:sampleBuffer withType:SQSystemCaptrueTypeVideo];
    }
}
- (void)prepare{
    [self prepareWithPreviewSize:CGSizeZero];
}
//捕获内容包括视频时调用（预览层大小，添加到view上用来显示）
- (void)prepareWithPreviewSize:(CGSize)size{
    _prelayerSize = size;
    if(capture == SQSystemCaptrueTypeAudio){
        [self setupAudio];
    }else if (capture == SQSystemCaptrueTypeVideo) {
        [self setupVideo];
    }else if (capture == SQSystemCaptrueTypeAll) {
        [self setupAudio];
        [self setupVideo];
    }
}
-(void)setupAudio{
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    self.audioInputDevice = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:NULL];
    self.audioDataOutput = [[AVCaptureAudioDataOutput alloc]init];
    [self.audioDataOutput setSampleBufferDelegate:self  queue:self.captureQueue];
    [self.captureSession beginConfiguration];
     if ([self.captureSession canAddInput:self.audioInputDevice]) {
           [self.captureSession addInput:self.audioInputDevice];
       }
       if([self.captureSession canAddOutput:self.audioDataOutput]){
           [self.captureSession addOutput:self.audioDataOutput];
       }
    [self.captureSession commitConfiguration];
       
       self.audioConnection = [self.audioDataOutput connectionWithMediaType:AVMediaTypeAudio];
}
-(void)setupVideo{
    AVCaptureDeviceDiscoverySession *discoverySession  =[AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionUnspecified];
    NSArray *videoDevices = discoverySession.devices;
    self.frontCamera = [AVCaptureDeviceInput deviceInputWithDevice:videoDevices.lastObject error:nil];
    self.backCamera = [AVCaptureDeviceInput deviceInputWithDevice:videoDevices.firstObject error:nil];
    self.videoInputDevice = self.backCamera;
    
    self.videoDataOutput = [[AVCaptureVideoDataOutput alloc]init];
    [self.videoDataOutput setSampleBufferDelegate:self queue:self.captureQueue];
    [self.videoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
    
    [self.captureSession beginConfiguration];
    if ([self.captureSession canAddInput:self.videoInputDevice]) {
        [self.captureSession addInput:self.videoInputDevice];
    }
    if([self.captureSession canAddOutput:self.videoDataOutput]){
        [self.captureSession addOutput:self.videoDataOutput];
    }
    [self setVideoPreset];
    [self.captureSession commitConfiguration];
    self.videoConnection = [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    [self updateFps:25];
    //设置预览
    [self setupPreviewLayer];
    
}
/**设置预览层**/
- (void)setupPreviewLayer{
    self.preLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    self.preLayer.frame =  CGRectMake(0, 0, self.prelayerSize.width, self.prelayerSize.height);
    //设置满屏
    self.preLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.preview.layer addSublayer:self.preLayer];
}
-(void)updateFps:(NSInteger) fps{
    //获取当前capture设备
    AVCaptureDeviceDiscoverySession *discoverySession  =[AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionUnspecified];
    NSArray *videoDevices = discoverySession.devices;
    
    //遍历所有设备（前后摄像头）
    for (AVCaptureDevice *vDevice in videoDevices) {
        //获取当前支持的最大fps
        float maxRate = [(AVFrameRateRange *)[vDevice.activeFormat.videoSupportedFrameRateRanges objectAtIndex:0] maxFrameRate];
        //如果想要设置的fps小于或等于做大fps，就进行修改
        if (maxRate >= fps) {
            //实际修改fps的代码
            if ([vDevice lockForConfiguration:NULL]) {
                vDevice.activeVideoMinFrameDuration = CMTimeMake(10, (int)(fps * 10));
                vDevice.activeVideoMaxFrameDuration = vDevice.activeVideoMinFrameDuration;
                [vDevice unlockForConfiguration];
            }
        }
    }
}
/**设置分辨率**/
- (void)setVideoPreset{
    if ([self.captureSession canSetSessionPreset:AVCaptureSessionPreset1920x1080])  {
        self.captureSession.sessionPreset = AVCaptureSessionPreset1920x1080;
        _witdh = 1080; _height = 1920;
    }else if ([self.captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
        self.captureSession.sessionPreset = AVCaptureSessionPreset1280x720;
        _witdh = 720; _height = 1280;
    }else{
        self.captureSession.sessionPreset = AVCaptureSessionPreset640x480;
        _witdh = 480; _height = 640;
    }
    
}

/**开始*/
- (void)start{
    if(![self.captureSession isRunning]){
         [self.captureSession startRunning];
    }
   
}
/**结束*/
- (void)stop{
    if([self.captureSession isRunning]){
        [self.captureSession stopRunning];
    }
}
/**切换摄像头*/
- (void)changeCamera{
    [self switchCamera];
}
-(void)switchCamera{
    [self.captureSession beginConfiguration];
    [self.captureSession removeInput:self.videoInputDevice];
    if ([self.videoInputDevice isEqual: self.frontCamera]) {
        self.videoInputDevice = self.backCamera;
    }else{
        self.videoInputDevice = self.frontCamera;
    }
    [self.captureSession addInput:self.videoInputDevice];
    [self.captureSession commitConfiguration];
    
}
- (void)dealloc{
    NSLog(@"capture销毁。。。。");
    [self destroyCaptureSession];
}
-(void) destroyCaptureSession{
     if (self.captureSession) {
         if (capture == SQSystemCaptrueTypeAudio) {
               [self.captureSession removeInput:self.audioInputDevice];
               [self.captureSession removeOutput:self.audioDataOutput];
         }else if (capture == SQSystemCaptrueTypeVideo) {
               [self.captureSession removeInput:self.videoInputDevice];
               [self.captureSession removeOutput:self.videoDataOutput];
         }else if (capture == SQSystemCaptrueTypeAll) {
               [self.captureSession removeInput:self.audioInputDevice];
               [self.captureSession removeOutput:self.audioDataOutput];
               [self.captureSession removeInput:self.videoInputDevice];
               [self.captureSession removeOutput:self.videoDataOutput];
           }
       }
       self.captureSession = nil;
}

+ (int)checkMicrophoneAuthor{
    int result = 0;
    //麦克风
    AVAudioSessionRecordPermission permissionStatus = [[AVAudioSession sharedInstance] recordPermission];
    switch (permissionStatus) {
        case AVAudioSessionRecordPermissionUndetermined:
            //    请求授权
            [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
            }];
            result = 0;
            break;
        case AVAudioSessionRecordPermissionDenied://拒绝
            result = -1;
            break;
        case AVAudioSessionRecordPermissionGranted://允许
            result = 1;
            break;
        default:
            break;
    }
    return result;
    
    
}
/**
 *  摄像头授权
 *  0 ：未授权 1:已授权 -1：拒绝
 */
+ (int)checkCameraAuthor{
    int result = 0;
    AVAuthorizationStatus videoStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    switch (videoStatus) {
        case AVAuthorizationStatusNotDetermined://第一次
            //    请求授权
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                
            }];
            break;
        case AVAuthorizationStatusAuthorized://已授权
            result = 1;
            break;
        default:
            result = -1;
            break;
    }
    return result;
    
}

-(int)test{
    int result = 0;
    AVAuthorizationStatus videoStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    switch (videoStatus) {
        case AVAuthorizationStatusNotDetermined://第一次
            break;
        case AVAuthorizationStatusAuthorized://已授权
            result = 1;
            break;
        default:
            result = -1;
            break;
    }
    return result;
}

@end
