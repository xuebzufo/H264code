//
//  SQAVConfig.h
//  CPDemo
//
//  Created by Sem on 2020/8/10.
//  Copyright © 2020 SEM. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SQAudioConfig  : NSObject
@property(nonatomic,assign)NSInteger bitrate;
@property(nonatomic,assign)NSInteger channelCount;
/**采样率*/
@property (nonatomic, assign) NSInteger sampleRate;//(默认44100)
/**采样点量化*/
@property (nonatomic, assign) NSInteger sampleSize;//(16)
 +(instancetype)defaultConifg;
@end
@interface SQVideoConfig : NSObject
@property (nonatomic, assign) NSInteger width;//可选，系统支持的分辨率，采集分辨率的宽
@property (nonatomic, assign) NSInteger height;//可选，系统支持的分辨率，采集分辨率的高
@property (nonatomic, assign) NSInteger bitrate;//自由设置
@property (nonatomic, assign) NSInteger fps;//自由设置 25
+ (instancetype)defaultConifg;
@end
NS_ASSUME_NONNULL_END
