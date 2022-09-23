//
//  RcvRPMessageTransport.m
//  GlipCore
//
//  Created by Roman Gaiu on 12/4/18.
//  Copyright © 2018 RingCentral. All rights reserved.
//

#import "RcvRPMessageTransport.h"
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

CFDataRef RcvRPMessageServerCallback(CFMessagePortRef port, SInt32 msgid, CFDataRef data, void *info) {
    if (info == NULL) {
        return NULL;
    }
    
    if (!CFMessagePortIsValid(port)) {
        return NULL;
    }
    
    __unsafe_unretained RcvRPMessageServer *target = (__bridge RcvRPMessageServer *)(info);
    
    @autoreleasepool {
        NSData *payload = [NSData dataWithBytes:CFDataGetBytePtr(data) length:CFDataGetLength(data)];
        NSData *result = [target.delegate rcvRPMessageServerDidReceiveMessageWithId:msgid
                                                                            payload:payload];
        return result ? CFBridgingRetain(result) : NULL;
    }
}

@interface RcvRPMessageServer() {
    CFMessagePortRef _port;
}
@end

@interface RcvRPMessageClient() {
    CFMessagePortRef _port;
}
@end

@implementation RcvRPMessageServer

-(void)dealloc {
    [self teardown];
}

-(BOOL)startup {
    RCVRPWLOG("RCVRP RcvRPMessageServer startup");
    if (_port != NULL) {
        return NO;
    }
    RCVRPWLOG("RCVRP RcvRPMessageServer startup 1");

    CFMessagePortContext ctx = {
        .version = 0,
        .info = (__bridge void *)(self),
        .retain = NULL,
        .release = NULL,
        .copyDescription = NULL
    };
    
    CFMessagePortRef port = CFMessagePortCreateLocal(kCFAllocatorDefault, (CFStringRef)self.portName, &RcvRPMessageServerCallback, &ctx, NULL);
    
    if (port == NULL) {//Probably port name doesn't match any of application group
        return NO;
    }
    RCVRPWLOG("RCVRP RcvRPMessageServer startup 2");
    dispatch_queue_t queue = self.queue;
    if (queue == NULL) {
        queue = dispatch_get_main_queue();
    }

    CFMessagePortSetDispatchQueue(port, queue);
    _port = port;
    return YES;
}

-(void)teardown {
    if (_port != NULL) {
        CFMessagePortInvalidate(_port);
        CFRelease(_port);
        _port = NULL;
    }
}

@end

@implementation RcvRPMessageClient

-(instancetype)init {
    if (self = [super init]) {
        self.sendTimeout = 0.5;
        self.recvTimeout = 0.5;
    }
    return self;
}

-(void)dealloc {
    if (_port != NULL) {
        CFMessagePortInvalidate(_port);
        _port = NULL;
    }
}

-(BOOL)connect {
    if (_port != NULL) {
        return NO;
    }
    
    _port = CFMessagePortCreateRemote(kCFAllocatorDefault, (__bridge CFStringRef)self.portName);
    return _port;
}

-(void)disconnect {
    if (_port != NULL) {
        CFMessagePortInvalidate(_port);
        CFRelease(_port);
        _port = NULL;
    }
}

-(RcvMessageTransportResult)sendMessageWithId:(SInt32)messageId payload:(NSData*)request response:(NSData**)response {
    if (_port == NULL) {
        return RcvMessageTransportResultPortIsNotConnected;
    }
    
    CFDataRef *cfResponse = NULL;
    SInt32 result = CFMessagePortSendRequest(_port, messageId, (__bridge CFDataRef)request, self.sendTimeout, self.recvTimeout, kCFRunLoopDefaultMode, cfResponse);
    
    if (response && cfResponse) {
        *response = [NSData dataWithBytes:CFDataGetBytePtr(*cfResponse)
                                   length:CFDataGetLength(*cfResponse)];
    }
    
    return result;
}

-(RcvMessageTransportResult)sendMessageWithId:(SInt32)messageId payload:(NSData*)request {
    if (_port == NULL) {
        return RcvMessageTransportResultPortIsNotConnected;
    }

    SInt32 result = CFMessagePortSendRequest(_port, messageId, (__bridge CFDataRef)request, self.sendTimeout, self.recvTimeout, NULL, NULL);
    
    return result;
}

@end

