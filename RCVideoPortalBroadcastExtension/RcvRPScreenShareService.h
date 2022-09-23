//
//  RcvRPScreenShareService.h
//  GlipCore
//
//  Created by Roman Gaiu on 12/3/18.
//  Copyright © 2018 RingCentral. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ReplayKit/ReplayKit.h>


extern const NSInteger RCVRPRecordingErrorCommunication;
extern const NSInteger RCVRPRecordingErrorMeetingOrSharingEnded;
extern const NSInteger RCVRPRecordingErrorSharingHasBeenCancelled;
extern const NSInteger RCVRPRecordingErrorSharingHasBeenInterrupted;
extern const NSInteger RCVRPRecordingErrorSharingHasBeenFailed;
extern const NSInteger RCVRPRecordingErrorMeetingHasBeenEnded;
extern const NSInteger RCVRPRecordingErrorLostConnectionToHostApp;


@protocol RcvScreenShareServiceDelegate<NSObject>
-(void)rcvScreenShareServiceFinishBroadcastWithError:(NSError* _Nonnull)error;
@end

NS_ASSUME_NONNULL_BEGIN

@interface RcvScreenShareService : NSObject
@property (nonatomic, copy) NSString *appGroup;
@property (nonatomic, weak) id<RcvScreenShareServiceDelegate> delegate;
@property (nonatomic, readonly) BOOL isActive;

- (BOOL)broadcastStartedWithSetupInfo:(NSDictionary<NSString *,NSObject *> * _Nullable)setupInfo;
- (void)broadcastPaused;
- (void)broadcastResumed;
- (void)broadcastFinished;
- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer withType:(RPSampleBufferType)sampleBufferType;
- (void)processPixelBuffer:(CVPixelBufferRef)pixelBuffer withOrientation:(CGImagePropertyOrientation)orientation;
@end

NS_ASSUME_NONNULL_END
