//
//  SQLayer.h
//  CPDemo
//
//  Created by Sem on 2020/8/12.
//  Copyright © 2020 SEM. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#include <QuartzCore/QuartzCore.h>
#include <CoreVideo/CoreVideo.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface SQLayer : CAEAGLLayer
@property CVPixelBufferRef pixelBuffer;
-(id)initWithFrame:(CGRect)frame;
-(void)resetRenderBuffer;
@end

NS_ASSUME_NONNULL_END
