//
//  RcvRPMessageTransport.h
//  GlipCore
//
//  Created by Roman Gaiu on 12/4/18.
//  Copyright © 2018 RingCentral. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSInteger {
    RcvMessageTransportResultSuccess = kCFMessagePortSuccess,
    RcvMessageTransportResultSendTimeout = kCFMessagePortSendTimeout,
    RcvMessageTransportResultReceiveTimeout = kCFMessagePortReceiveTimeout,
    RcvMessageTransportResultPortIsInvalid = kCFMessagePortIsInvalid,
    RcvMessageTransportResultTransportError = kCFMessagePortTransportError,
    RcvMessageTransportResultBecameInvalidError = kCFMessagePortBecameInvalidError,
    RcvMessageTransportResultPortIsNotConnected
} RcvMessageTransportResult;

@protocol RcvRPMessageServerDelegate <NSObject>
-(NSData *)rcvRPMessageServerDidReceiveMessageWithId:(SInt32)messageId payload:(NSData*)data;
@end

@interface RcvRPMessageServer: NSObject
@property (nonatomic, weak) id<RcvRPMessageServerDelegate> delegate;
@property (nonatomic, copy) NSString *portName;
@property (nonatomic, strong) dispatch_queue_t queue;

-(BOOL)startup;
-(void)teardown;
@end

@interface RcvRPMessageClient: NSObject
@property (nonatomic, copy) NSString *portName;
@property (nonatomic, assign) CFTimeInterval sendTimeout;
@property (nonatomic, assign) CFTimeInterval recvTimeout;

-(BOOL)connect;
-(void)disconnect;
-(RcvMessageTransportResult)sendMessageWithId:(SInt32)messageId payload:(NSData*)request response:(NSData**)response;
-(RcvMessageTransportResult)sendMessageWithId:(SInt32)messageId payload:(NSData*)request;
@end
