//
//  RcvCVPixelBufferUtils.h
//  GlipCore
//
//  Created by Roman Gaiu on 6/29/18.
//  Copyright © 2018 RingCentral. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreImage/CoreImage.h>

@interface RcvCVPixelBufferConverter : NSObject

-(CVPixelBufferRef)rotate:(CVPixelBufferRef)pixelBuffer constant:(uint8_t)rotationConstant usePool:(BOOL)usePool;

@end


