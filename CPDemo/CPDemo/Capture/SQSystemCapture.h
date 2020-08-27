//
//  SQSystemCapture.h
//  CPDemo
//
//  Created by Sem on 2020/8/10.
//  Copyright © 2020 SEM. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(int,SQSystemCaptrueType){
    SQSystemCaptrueTypeVideo = 0,
    SQSystemCaptrueTypeAudio,
    SQSystemCaptrueTypeAll
};
@protocol SQSystemCaptureDelegate <NSObject>
@optional
-(void)captureSampleBuffer:(CMSampleBufferRef )sampleBuffer withType:(SQSystemCaptrueType)type;


@end
@interface SQSystemCapture : NSObject
@property (nonatomic,strong)UIView * preview;
@property (nonatomic,weak)id<SQSystemCaptureDelegate> delegate;
/**捕获视频的宽*/
@property (nonatomic, assign, readonly) NSUInteger witdh;
/**捕获视频的高*/
@property (nonatomic, assign, readonly) NSUInteger height;
-(instancetype)initWithType:(SQSystemCaptrueType)type;
-(instancetype)init UNAVAILABLE_ATTRIBUTE;
/** 准备工作(只捕获音频时调用)*/
- (void)prepare;
//捕获内容包括视频时调用（预览层大小，添加到view上用来显示）
- (void)prepareWithPreviewSize:(CGSize)size;

/**开始*/
- (void)start;
/**结束*/
- (void)stop;
/**切换摄像头*/
- (void)changeCamera;


//授权检测
+ (int)checkMicrophoneAuthor;
+ (int)checkCameraAuthor;


@end

NS_ASSUME_NONNULL_END
