//
//  RcvPRBroadcastMessage.m
//  GlipCore
//
//  Created by Roman Gaiu on 6/27/18.
//  Copyright © 2018 RingCentral. All rights reserved.
//

#import "RcvRPBroadcastMessage.h"


NSString *const kRcvRPBroadcastServicePortUserDefaultsKey = @"RcvRPBroadcastServicePort";

NSTimeInterval const RcvRPHeartBeatInterval = 1.0;

NSString *RcvRPMainPortName(NSString *container) {
    return [NSString stringWithFormat:@"%@.rcv.main", container];
}

NSString *RcvRPClientPortName(NSString *container) {
    return [NSString stringWithFormat:@"%@.rcv.%@", container, [[NSUUID UUID] UUIDString]];
}

#define DECODE_INT(FIELD) self.FIELD = [aDecoder decodeIntegerForKey:@#FIELD]
#define ENCODE_INT(FIELD) [aCoder encodeInteger:self.FIELD forKey:@#FIELD]

#define DECODE_BOOL(FIELD) self.FIELD = [aDecoder decodeBoolForKey:@#FIELD]
#define ENCODE_BOOL(FIELD) [aCoder encodeBool:self.FIELD forKey:@#FIELD]

#define DECODE_INT64(FIELD) self.FIELD = [aDecoder decodeInt64ForKey:@#FIELD]
#define ENCODE_INT64(FIELD) [aCoder encodeInt64:self.FIELD forKey:@#FIELD]

#define DECODE_OBJECT(FIELD,CLASS) self.FIELD = [aDecoder decodeObjectOfClass:CLASS.class forKey:@#FIELD]
#define ENCODE_OBJECT(FIELD) [aCoder encodeObject:self.FIELD forKey:@#FIELD]


@implementation RcvRPEncodingSessionCreatePayload

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        DECODE_INT(version);
        DECODE_INT(width);
        DECODE_INT(height);
        DECODE_INT(bitrate);
        DECODE_BOOL(rotation);
        return self;
    }
    return nil;
}

- (void)encodeWithCoder:(nonnull NSCoder *)aCoder {
    ENCODE_INT(version);
    ENCODE_INT(width);
    ENCODE_INT(height);
    ENCODE_INT(bitrate);
    ENCODE_BOOL(rotation);
}

-(NSString *)description {
    return [NSString stringWithFormat:@"RcvRPEncodingSessionCreatePayload: version:%li width:%li height:%li bitrate:%li", (long)_version, (long)_width, (long)_height, (long)_bitrate];
}

+ (BOOL)supportsSecureCoding {
    return YES;
}
@end

@implementation RcvRPEncodingSessionDestroyPayload

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        DECODE_INT(version);
        return self;
    }
    return nil;
}

- (void)encodeWithCoder:(nonnull NSCoder *)aCoder {
    ENCODE_INT(version);
}

+ (BOOL)supportsSecureCoding {
    return YES;
}
@end

@implementation RcvRPEncodingSessionKeyFramePayload

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        DECODE_INT(version);
        return self;
    }
    return nil;
}

- (void)encodeWithCoder:(nonnull NSCoder *)aCoder {
    ENCODE_INT(version);
}

+ (BOOL)supportsSecureCoding {
    return YES;
}
@end

@implementation RcvRPEncodingSessionBitratePayload

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        DECODE_INT(version);
        DECODE_INT(bitrate);
        return self;
    }
    return nil;
}

- (void)encodeWithCoder:(nonnull NSCoder *)aCoder {
    ENCODE_INT(version);
    ENCODE_INT(bitrate);
}

-(NSString *)description {
    return [NSString stringWithFormat:@"RcvRPEncodingSessionBitratePayload: version:%li bitrate:%li", (long)_version, (long)_bitrate];
}

+ (BOOL)supportsSecureCoding {
    return YES;
}
@end


@implementation RcvRPEncodingSessionEncodedFramePayload

-(instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        DECODE_INT(version);
        DECODE_INT(encodedWidth);
        DECODE_INT(encodedHeight);
        DECODE_BOOL(keyFrame);
        DECODE_INT64(captureTimeMs);
        DECODE_OBJECT(buffer,NSData);
        DECODE_OBJECT(fragmentationOffset, NSArray);
        DECODE_OBJECT(fragmentationLength,NSArray);
        DECODE_INT(orientation);
        return self;
    }
    return nil;
}

- (void)encodeWithCoder:(nonnull NSCoder *)aCoder {
    ENCODE_INT(version);
    ENCODE_INT(encodedWidth);
    ENCODE_INT(encodedHeight);
    ENCODE_BOOL(keyFrame);
    ENCODE_INT64(captureTimeMs);
    ENCODE_OBJECT(buffer);
    ENCODE_OBJECT(fragmentationOffset);
    ENCODE_OBJECT(fragmentationLength);
    ENCODE_INT(orientation);
}

+ (BOOL)supportsSecureCoding {
    return YES;
}
@end
