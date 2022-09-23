//
//  RcvPRBroadcastMessage.h
//  GlipCore
//
//  Created by Roman Gaiu on 6/27/18.
//  Copyright © 2018 RingCentral. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(SInt32, RcvRPBroadcastPortMessageId) {
    RcvRPBroadcastPortMessageIdPixelBufferData = 0,
    RcvRPBroadcastPortMessageIdPixelBufferMeta,
    RcvRPBroadcastPortMessageIdCaptureSessionStarted,
    RcvRPBroadcastPortMessageIdCaptureSessionPaused,
    RcvRPBroadcastPortMessageIdCaptureSessionResumed,
    RcvRPBroadcastPortMessageIdCaptureSessionFinished,
    RcvRPBroadcastPortMessageIdRequestToFinishCaptureSession,
    RcvRPBroadcastPortMessageIdSharingHasBeenCancelled,
    RcvRPBroadcastPortMessageIdSharingHasBeenInterrupted,
    RcvRPBroadcastPortMessageIdSharingHasBeenFailed,
    RcvRPBroadcastPortMessageIdSharingHeartBeat,
    RcvRPBroadcastPortMessageIdMeetingHasBeenEnded,
    
    RcvRPBroadcastPortMessageIdEncodingSessionCreate,
    RcvRPBroadcastPortMessageIdEncodingSessionDestroy,
    RcvRPBroadcastPortMessageIdEncodingSessionKeyFrame,
    RcvRPBroadcastPortMessageIdEncodingSessionBitrate,
    RcvRPBroadcastPortMessageIdEncodingSessionEncodedFrame,
    
    RcvRPBroadcastPortMessageIdMax
};

typedef NS_ENUM(NSInteger, RcvRPBroadcastMessageResponseCode) {
    RcvRPBroadcastMessageResponseCodeOk = 0,
    RcvRPBroadcastMessageResponseCodeClosed = 1
};

extern NSString *const kRcvRPBroadcastServicePortUserDefaultsKey;

extern NSTimeInterval const RcvRPHeartBeatInterval;

#if defined __cplusplus
extern "C" {
#endif
NSString *RcvRPMainPortName(NSString *container);
NSString *RcvRPClientPortName(NSString *container);
#if defined __cplusplus
};
#endif

@interface RcvRPEncodingSessionCreatePayload: NSObject<NSSecureCoding>
@property(nonatomic, assign) NSInteger version;
@property(nonatomic, assign) NSInteger width;
@property(nonatomic, assign) NSInteger height;
@property(nonatomic, assign) NSInteger bitrate;
@property(nonatomic, assign) BOOL rotation;
@end

@interface RcvRPEncodingSessionDestroyPayload: NSObject<NSSecureCoding>
@property(nonatomic, assign) NSInteger version;
@end

@interface RcvRPEncodingSessionKeyFramePayload: NSObject<NSSecureCoding>
@property(nonatomic, assign) NSInteger version;
@end

@interface RcvRPEncodingSessionBitratePayload: NSObject<NSSecureCoding>
@property(nonatomic, assign) NSInteger version;
@property(nonatomic, assign) NSInteger bitrate;
@end

@interface RcvRPEncodingSessionEncodedFramePayload: NSObject<NSSecureCoding>
@property(nonatomic, assign) NSInteger version;
@property(nonatomic, assign) NSInteger encodedWidth;
@property(nonatomic, assign) NSInteger encodedHeight;
@property(nonatomic, assign) BOOL keyFrame;
@property(nonatomic, assign) int64_t captureTimeMs;
@property(nonatomic, strong) NSData *buffer;
@property(nonatomic, strong) NSArray<NSNumber *> *fragmentationOffset;
@property(nonatomic, strong) NSArray<NSNumber *> *fragmentationLength;
@property(nonatomic, assign) NSInteger orientation;
@end

