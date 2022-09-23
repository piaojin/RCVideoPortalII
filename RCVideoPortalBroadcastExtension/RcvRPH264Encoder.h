//
//  RcvRPH264Encoder.h
//  GlipCore
//
//  Created by Roman Gaiu on 12/14/18.
//  Copyright © 2018 RingCentral. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ReplayKit/ReplayKit.h>

@class RcvRPEncodingSessionCreatePayload;
@class RcvRPEncodingSessionDestroyPayload;
@class RcvRPEncodingSessionBitratePayload;
@class RcvRPEncodingSessionKeyFramePayload;
@class RcvRPEncodingSessionEncodedFramePayload;
@class RcvRPH264Encoder;

@protocol RcvRPH264EncoderDelegate<NSObject>
-(void)encoder:(RcvRPH264Encoder*)encoder didEncodeFrame:(RcvRPEncodingSessionEncodedFramePayload*)frame;
@end;

@interface RcvRPH264Encoder : NSObject
@property (nonatomic, weak) id<RcvRPH264EncoderDelegate> delegate;
-(void)createEncoder:(RcvRPEncodingSessionCreatePayload*)params;
-(void)setBitrate:(RcvRPEncodingSessionBitratePayload*)param;
-(void)destroyEncoder:(RcvRPEncodingSessionDestroyPayload*)param;
-(void)requestKeyFrame:(RcvRPEncodingSessionKeyFramePayload*)param;
-(void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer withType:(RPSampleBufferType)sampleBufferType;
-(void)processPixelBuffer:(CVPixelBufferRef)pixelBuffer withOrientation:(CGImagePropertyOrientation)orientation;
@end

