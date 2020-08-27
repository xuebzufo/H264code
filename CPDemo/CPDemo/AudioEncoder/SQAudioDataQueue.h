//
//  SQAudioDataQueue.h
//  CPDemo
//
//  Created by Sem on 2020/8/14.
//  Copyright © 2020 SEM. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SQAudioDataQueue : NSObject
@property(nonatomic,readonly)int count;
+(instancetype)shareInstance;
-(void)addData:(id)obj;
- (id)getData;
@end

NS_ASSUME_NONNULL_END
