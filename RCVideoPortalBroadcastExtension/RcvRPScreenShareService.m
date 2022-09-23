//
//  RcvRPScreenShareService.m
//  GlipCore
//
//  Created by Roman Gaiu on 12/3/18.
//  Copyright © 2018 RingCentral. All rights reserved.
//

#import "RcvRPScreenShareService.h"
#import "RcvRPBroadcastMessage.h"
#import "RcvRPMessageTransport.h"
#import "RcvRPH264Encoder.h"
#import <os/lock.h>
#import <os/log.h>

#define USE_OSLOG

#ifdef USE_OSLOG
static os_log_t getLogger() {
    static dispatch_once_t onceToken;
    static os_log_t result;
    dispatch_once(&onceToken, ^{
        result = os_log_create("com.rcv.broadcast.service", "media");
    });
    return result;
}
#define RCVRPWLOG(...) os_log_error(getLogger(), __VA_ARGS__)
#define RCVRPILOG(...) os_log_info(getLogger(), __VA_ARGS__)
#define RCVRPDLOG(...) void(0)
#else
#define RCVRPWLOG(...) NSLog(@ __VA_ARGS__)
#define RCVRPILOG(...) NSLog(@ __VA_ARGS__)
#define RCVRPDLOG(...) void(0)
#endif

#define CHECK_PAYLOAD(PAYLOAD,MSGID,TOKEN) do { if (PAYLOAD == nil) { \
    RCVRPWLOG("RCVRP recv no payload for msg:%li", (long)MSGID); \
    NSAssert(NO, TOKEN); \
}} while (0)

static const NSUInteger kPrintEncodedFrameStatInterval = 45;

const NSInteger RCVRPRecordingErrorCommunication = -6000;
const NSInteger RCVRPRecordingErrorMeetingOrSharingEnded = -6001;

const NSInteger RCVRPRecordingErrorSharingHasBeenCancelled = -6002;
const NSInteger RCVRPRecordingErrorSharingHasBeenInterrupted = -6003;
const NSInteger RCVRPRecordingErrorSharingHasBeenFailed = -6004;
const NSInteger RCVRPRecordingErrorMeetingHasBeenEnded = -6005;
const NSInteger RCVRPRecordingErrorLostConnectionToHostApp = -6006;

@interface RcvScreenShareService() <RcvRPMessageServerDelegate, RcvRPH264EncoderDelegate> {
    NSUInteger _encodedFrameCounter;
    NSUInteger _encodedFrameSizeSum;
    dispatch_block_t _lostConnectionHandler;
}
@property (atomic, strong) RcvRPMessageServer *server;
@property (atomic, strong) RcvRPMessageClient *client;
@property (atomic, strong) RcvRPH264Encoder *encoder;
-(void)handleHeartBeat:(BOOL)firstTime;
@end

@implementation RcvScreenShareService

-(instancetype)init {
    if (self = [super init]) {
        self.encoder = [[RcvRPH264Encoder alloc] init];
        self.encoder.delegate = self;
    }
    return self;
}

-(void)dealloc {
    [self reset];
}

-(void)reset {
    [self.server teardown];
    self.server = nil;
    [self.client disconnect];
    self.client = nil;
}

- (BOOL)broadcastStartedWithSetupInfo:(NSDictionary<NSString *,NSObject *> * _Nullable)setupInfo {
    if (self.client) {
        RCVRPWLOG("RCVRP client already created");
        return NO;
    }
    [self reset];
    
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:self.appGroup];
    NSString *portName = [defaults stringForKey:kRcvRPBroadcastServicePortUserDefaultsKey];
    if ([portName length] == 0) {
        RCVRPWLOG("RCVRP main port is unknown");
        return NO;
    }
    
    RcvRPMessageClient *client = [[RcvRPMessageClient alloc] init];
    client.portName = portName;
    if (![client connect]) {
        [self reset];
        RCVRPWLOG("RCVRP client can't connect");
        return NO;
    }
    
    RcvRPMessageServer *server = [[RcvRPMessageServer alloc] init];
    server.portName = RcvRPClientPortName(self.appGroup);
    server.delegate = self;
    if (![server startup]) {
        [self reset];
        RCVRPWLOG("RCVRP server can't startup");
        return NO;
    }

    RcvMessageTransportResult result = RcvMessageTransportResultSuccess;
    result = [client sendMessageWithId:RcvRPBroadcastPortMessageIdCaptureSessionStarted
                               payload:[server.portName dataUsingEncoding:NSUTF8StringEncoding]
                              response:nil];
    
    if (result != RcvMessageTransportResultSuccess) {
        [self reset];
        RCVRPWLOG("RCVRP service can't establish connection %ld", (long)result);
        return NO;
    }
    
    self.client = client;
    self.server = server;
    [self handleHeartBeat: true];
    return YES;
}

- (void)broadcastPaused {
    if (self.client == nil) {
        RCVRPWLOG("RCVRP broadcastPaused with no client");
        return;
    }
    SInt32 msgid = RcvRPBroadcastPortMessageIdCaptureSessionPaused;
    RcvMessageTransportResult result = [self.client sendMessageWithId:msgid payload:nil response:nil];
    if (result != RcvMessageTransportResultSuccess) {
        RCVRPWLOG("RCVRP broadcastPaused can't notify host");
        [self finishBroadcastWithCode:RCVRPRecordingErrorCommunication];
    }
}

- (void)broadcastResumed {
    if (self.client == nil) {
        RCVRPWLOG("RCVRP broadcastResumed with no client");
        return;
    }
    SInt32 msgid = RcvRPBroadcastPortMessageIdCaptureSessionResumed;
    RcvMessageTransportResult result = [self.client sendMessageWithId:msgid payload:nil response:nil];
    if (result != RcvMessageTransportResultSuccess) {
        RCVRPWLOG("RCVRP broadcastResumed can't notify host");
        [self finishBroadcastWithCode:RCVRPRecordingErrorCommunication];
    }
}

- (void)broadcastFinished {
    if (self.client == nil) {
        RCVRPWLOG("RCVRP broadcastFinished with no client");
        return;
    }
    SInt32 msgid = RcvRPBroadcastPortMessageIdCaptureSessionFinished;
    RcvMessageTransportResult result = [self.client sendMessageWithId:msgid payload:nil response:nil];
    if (result != RcvMessageTransportResultSuccess) {
        RCVRPWLOG("RCVRP broadcastFinished can't notify host");
        [self finishBroadcastWithCode:RCVRPRecordingErrorCommunication];
    }
}

- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer withType:(RPSampleBufferType)sampleBufferType {
    [self.encoder processSampleBuffer:sampleBuffer withType:sampleBufferType];
}

- (void)processPixelBuffer:(CVPixelBufferRef)pixelBuffer withOrientation:(CGImagePropertyOrientation)orientation {
    [self.encoder processPixelBuffer:pixelBuffer withOrientation:orientation];
}

-(NSData *)rcvRPMessageServerDidReceiveMessageWithId:(SInt32)messageId payload:(NSData*)data {
    NSSet<Class> *objectClasses =
        [NSSet setWithArray:@[ RcvRPEncodingSessionCreatePayload.class, RcvRPEncodingSessionDestroyPayload.class, RcvRPEncodingSessionKeyFramePayload.class, RcvRPEncodingSessionBitratePayload.class]];
    id payload = [NSKeyedUnarchiver unarchivedObjectOfClasses:objectClasses fromData:data error:nil];
    RCVRPWLOG("RCVRP rcvRPMessageServerDidReceiveMessageWithId %d", (int)messageId);

    switch (messageId) {
        case RcvRPBroadcastPortMessageIdRequestToFinishCaptureSession:
            [self finishBroadcastWithCode:RCVRPRecordingErrorMeetingOrSharingEnded];
            break;
        
        case RcvRPBroadcastPortMessageIdSharingHasBeenCancelled:
            [self finishBroadcastWithCode:RCVRPRecordingErrorSharingHasBeenCancelled];
            break;
            
        case RcvRPBroadcastPortMessageIdSharingHasBeenInterrupted:
            [self finishBroadcastWithCode:RCVRPRecordingErrorSharingHasBeenInterrupted];
            break;
            
        case RcvRPBroadcastPortMessageIdSharingHasBeenFailed:
            [self finishBroadcastWithCode:RCVRPRecordingErrorSharingHasBeenFailed];
            break;
            
        case RcvRPBroadcastPortMessageIdMeetingHasBeenEnded:
            [self finishBroadcastWithCode:RCVRPRecordingErrorMeetingHasBeenEnded];
            break;
            
        case RcvRPBroadcastPortMessageIdSharingHeartBeat:
            [self handleHeartBeat: false];
            break;

        case RcvRPBroadcastPortMessageIdEncodingSessionCreate:
            CHECK_PAYLOAD(payload, messageId, @"1252a5dd-8e22-4c9f-b17a-ada1b05e61d0");
            [self.encoder createEncoder:payload];
            break;
            
        case RcvRPBroadcastPortMessageIdEncodingSessionDestroy:
            CHECK_PAYLOAD(payload, messageId, @"52cd28be-ca65-4541-a626-fef78ca210b1");
            [self.encoder destroyEncoder:payload];
            break;
            
        case RcvRPBroadcastPortMessageIdEncodingSessionKeyFrame:
            CHECK_PAYLOAD(payload, messageId, @"9b46d46a-c29a-4c3d-8337-8330e49a75a2");
            [self.encoder requestKeyFrame:payload];
            break;

        case RcvRPBroadcastPortMessageIdEncodingSessionBitrate:
            CHECK_PAYLOAD(payload, messageId, @"5041fe55-b7e8-46d9-a5d0-9cf61fca9fd3");
            [self.encoder setBitrate:payload];
            break;

        default:
            break;
    }
    return nil;
}

#pragma mark - Utils

- (void)finishBroadcastWithCode:(NSInteger)errorCode {
    RCVRPILOG("RCVRP finish with code:%li", (long)errorCode);
    [self.encoder destroyEncoder:nil];
    [self.server teardown];
    self.server = nil;
    
    NSError *error = [NSError errorWithDomain:RPRecordingErrorDomain
                                         code:errorCode
                                     userInfo:@{NSLocalizedFailureReasonErrorKey: @""}];
    [self.delegate rcvScreenShareServiceFinishBroadcastWithError:error];
}

-(void)encoder:(RcvRPH264Encoder *)encoder didEncodeFrame:(RcvRPEncodingSessionEncodedFramePayload *)frame {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:frame requiringSecureCoding:YES error:nil];
    if (data == nil || data.length == 0) {
        RCVRPWLOG("RCVRP didEncodeFrame with no payload");
        return;
    }
    _encodedFrameCounter += 1;
    _encodedFrameSizeSum += data.length;
    if (_encodedFrameCounter >= kPrintEncodedFrameStatInterval) {
        RCVRPILOG("RCVRP encoded data %lu", (unsigned long)_encodedFrameSizeSum);
        _encodedFrameCounter = 0;
        _encodedFrameSizeSum = 0;
    }
    if (data.length > 4096*10) {
        RCVRPILOG("RCVRP encoded data exceeds max inline bytes %lu", (unsigned long)data.length);
    }
    [self.client sendMessageWithId:RcvRPBroadcastPortMessageIdEncodingSessionEncodedFrame payload:data response:nil];
}

#pragma mark - Heartbeating

-(void)handleHeartBeat:(BOOL)firstTime {
    RCVRPWLOG("RCVRP handleHeartBeat %d", firstTime);

    if (_lostConnectionHandler) {
        dispatch_block_cancel(_lostConnectionHandler);
        _lostConnectionHandler = nil;
    }
    
    __weak typeof(self)weakSelf = self;
    _lostConnectionHandler = dispatch_block_create(DISPATCH_BLOCK_INHERIT_QOS_CLASS, ^{
        RCVRPWLOG("RCVRP finishBroadcastWithCode:RCVRPRecordingErrorLostConnectionToHostApp");
        [weakSelf finishBroadcastWithCode:RCVRPRecordingErrorLostConnectionToHostApp];
    });
    RCVRPWLOG("RCVRP handleHeartBeat_1");
    NSTimeInterval interval = (firstTime ? 20.0 : 5.0) * RcvRPHeartBeatInterval;
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(interval * NSEC_PER_SEC));
    dispatch_after(time, dispatch_get_main_queue(), _lostConnectionHandler);
}

@end
