//
//  RcvRPH264Encoder.m
//  GlipCore
//
//  Created by Roman Gaiu on 12/14/18.
//  Copyright © 2018 RingCentral. All rights reserved.
//

#import "RcvRPH264Encoder.h"
#import "RcvRPBroadcastMessage.h"
#import "RcvCVPixelBufferUtils.h"
#import <VideoToolbox/VideoToolbox.h>
#import <os/log.h>

#define USE_OSLOG

#ifdef USE_OSLOG
static os_log_t getLogger() {
    static dispatch_once_t onceToken;
    static os_log_t result;
    dispatch_once(&onceToken, ^{
        result = os_log_create("com.rcv.broadcast.encoder", "media");
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

#define RCVRPOSERROR(status) [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil]

static const int64_t kMillisecondsPerSecond = 1000;
static const float kLimitToAverageBitRateFactor = 1.5f;
static const float kFramePerSeconds = 15.0;
static const size_t kAvccHeaderByteSize = sizeof(uint32_t);
static const char kAnnexBHeaderBytes[4] = {0, 0, 0, 1};

static void SetVTSessionPropertyBool(VTSessionRef session, CFStringRef key, bool value) {
    CFBooleanRef cf_bool = value ? kCFBooleanTrue : kCFBooleanFalse;
    OSStatus status = VTSessionSetProperty(session, key, cf_bool);
    if (status != noErr) {
        RCVRPWLOG("RCVRP VTSessionSetProperty failed to set: %@", (__bridge NSString *)key);
    }
}

static void SetVTSessionPropertySInt32(VTSessionRef session, CFStringRef key, int32_t value) {
    CFNumberRef cfNum = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &value);
    OSStatus status = VTSessionSetProperty(session, key, cfNum);
    CFRelease(cfNum);
    if (status != noErr) {
        RCVRPWLOG("RCVRP VTSessionSetProperty failed to set: %@", (__bridge NSString *)key);
    }
}

static void SetVTSessionPropertyStr(VTSessionRef session, CFStringRef key, CFStringRef value) {
    OSStatus status = VTSessionSetProperty(session, key, value);
    if (status != noErr) {
        RCVRPWLOG("RCVRP VTSessionSetProperty failed to set: %@", (__bridge NSString *)key);
    }
}

static CGImagePropertyOrientation SampleBufferOrientation(CMSampleBufferRef sampleBuffer) {
    CGImagePropertyOrientation result = kCGImagePropertyOrientationUp;
    if (@available(iOS 11.0, *)) {
        CFStringRef key = (__bridge CFStringRef)RPVideoSampleOrientationKey;
        CFTypeRef attachment = CMGetAttachment(sampleBuffer, key, NULL);
        NSNumber *orientation = (__bridge NSNumber *)attachment;
        result = (CGImagePropertyOrientation)orientation.unsignedIntegerValue;
    }
    return result;
}

static BOOL isPortrait(int32_t width, int32_t height) {
    return height > width;
}

static uint8_t orientationToMultiplier(CGImagePropertyOrientation orientation) {
    switch (orientation) {
        case kCGImagePropertyOrientationUp:
            return 0;
            
        case kCGImagePropertyOrientationRight:
            return 1;
            
        case kCGImagePropertyOrientationDown:
            return 2;
            
        case kCGImagePropertyOrientationLeft:
            return 3;
            
        default:
            return 0;
    }
}

static BOOL SampleBufferHasKeyFrame(CMSampleBufferRef sampleBuffer) {
    BOOL isKeyframe = NO;
    CFArrayRef attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, 0);
    if (attachments != nullptr && CFArrayGetCount(attachments)) {
        CFDictionaryRef attachment = (CFDictionaryRef)CFArrayGetValueAtIndex(attachments, 0);
        isKeyframe = !CFDictionaryContainsKey(attachment, kCMSampleAttachmentKey_NotSync);
    }
    return isKeyframe;
}

static BOOL SampleBufferAVCCToAnnexb(CMSampleBufferRef avcc, bool isKeyframe, RcvRPEncodingSessionEncodedFramePayload *payload) {
    NSCAssert(avcc, @"91954d03-e156-43cf-b3f3-2a4ec1e5e567");
    NSMutableData *annexb = [NSMutableData data];
    
    CMVideoFormatDescriptionRef description = CMSampleBufferGetFormatDescription(avcc);
    if (description == nullptr) {
        RCVRPWLOG("Failed to get sample buffer's description.");
        return NO;
    }
    
    int naluHeaderSize = 0;
    size_t paramSetCount = 0;
    OSStatus status = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(description, 0, nullptr, nullptr, &paramSetCount, &naluHeaderSize);
    if (status != noErr) {
        RCVRPWLOG("Failed to get parameter set.");
        return NO;
    }
    
    NSCAssert(naluHeaderSize == kAvccHeaderByteSize, @"bce3520e-00e3-4f76-a5c3-beb173559698");
    NSCAssert(paramSetCount == 2, @"2b13e298-fd56-470d-ab93-5bd36a52d698");
    
    size_t naluOffset = 0;
    NSMutableArray<NSNumber *> *fragmentationOffset = [NSMutableArray array];
    NSMutableArray<NSNumber *> *fragmentationLength = [NSMutableArray array];

    if (isKeyframe) {
        size_t paramSetSize = 0;
        const uint8_t* paramSet = nullptr;
        for (size_t i = 0; i < paramSetCount; ++i) {
            status = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(description, i, &paramSet, &paramSetSize, nullptr, nullptr);
            if (status != noErr) {
                RCVRPWLOG("Failed to get parameter set.");
                return NO;
            }
            [annexb appendBytes:kAnnexBHeaderBytes length:sizeof(kAnnexBHeaderBytes)];
            [annexb appendBytes:reinterpret_cast<const char*>(paramSet) length:paramSetSize];
            [fragmentationOffset addObject:@(naluOffset + sizeof(kAnnexBHeaderBytes))];
            [fragmentationLength addObject:@(paramSetSize)];
            naluOffset += sizeof(kAnnexBHeaderBytes) + paramSetSize;
        }
    }

    CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(avcc);
    if (blockBuffer == nullptr) {
        RCVRPWLOG("Failed to get sample buffer's block buffer.");
        return NO;
    }
    CMBlockBufferRef contiguousBuffer = nullptr;
    if (!CMBlockBufferIsRangeContiguous(blockBuffer, 0, 0)) {
        status = CMBlockBufferCreateContiguous(nullptr, blockBuffer, nullptr, nullptr, 0, 0, 0, &contiguousBuffer);
        if (status != noErr) {
            RCVRPWLOG("Failed to flatten non-contiguous block buffer: %i", (int)status);
            return NO;
        }
    } else {
        contiguousBuffer = blockBuffer;
        CFRetain(contiguousBuffer);
        blockBuffer = nullptr;
    }
    
    char* dataPtr = nullptr;
    size_t block_buffer_size = CMBlockBufferGetDataLength(contiguousBuffer);
    status = CMBlockBufferGetDataPointer(contiguousBuffer, 0, nullptr, nullptr, &dataPtr);
    if (status != noErr) {
        RCVRPWLOG("Failed to get block buffer data.");
        CFRelease(contiguousBuffer);
        return false;
    }
    size_t bytesRemaining = block_buffer_size;
    while (bytesRemaining > 0) {
        NSCAssert(bytesRemaining >= (size_t)naluHeaderSize, @"b4c6ff5b-bb2f-481e-8514-65e7194cbdf8");
        uint32_t* uint32DataPtr = reinterpret_cast<uint32_t*>(dataPtr);
        uint32_t packetSize = CFSwapInt32BigToHost(*uint32DataPtr);
        [annexb appendBytes:kAnnexBHeaderBytes length:sizeof(kAnnexBHeaderBytes)];
        [annexb appendBytes:dataPtr + naluHeaderSize length:packetSize];
        [fragmentationOffset addObject:@(naluOffset + sizeof(kAnnexBHeaderBytes))];
        [fragmentationLength addObject:@(packetSize)];
        naluOffset += sizeof(kAnnexBHeaderBytes) + packetSize;
        
        size_t bytesWritten = packetSize + sizeof(kAnnexBHeaderBytes);
        bytesRemaining -= bytesWritten;
        dataPtr += bytesWritten;
    }
    NSCAssert(bytesRemaining == 0, @"0fd4d7fa-0de6-4f5a-80dd-42286ef81d82");
    NSCAssert(fragmentationLength.count == fragmentationOffset.count, @"559b1fcb-436f-49eb-86d7-bbb253b6fc94");

    payload.fragmentationOffset = fragmentationOffset;
    payload.fragmentationLength = fragmentationLength;
    CFRelease(contiguousBuffer);
    payload.buffer = annexb;
    return YES;
}



struct RcvRPEncoderParams {
    RcvRPH264Encoder *encoder;
    int32_t width;
    int32_t height;
    CGImagePropertyOrientation orientation;
    int64_t renderTimeMs;
    NSInteger version;
};

@interface BufferHolder: NSObject {
    CVPixelBufferRef _buffer;
    CGImagePropertyOrientation _orientation;
    CVPixelBufferRef _rotated;
}
@property (nonatomic, readonly) CVPixelBufferRef buffer;
@property (nonatomic, readonly) CGImagePropertyOrientation orientation;
-(instancetype)initWithBuffer:(CVPixelBufferRef)buffer orientation:(CGImagePropertyOrientation)orientation;
-(void)setRotatedBuffer:(CVPixelBufferRef)buffer;
-(CVPixelBufferRef)rotatedBuffer;
@end

@implementation BufferHolder
- (instancetype)initWithBuffer:(CVPixelBufferRef)buffer orientation:(CGImagePropertyOrientation)orientation {
    if (self = [super init]) {
        _buffer = buffer;
        _orientation = orientation;
        if (_buffer) {
            CFRetain(_buffer);
        }
    }
    return self;
}

-(void)dealloc {
    if (_buffer) {
        CFRelease(_buffer);
    }
    if (_rotated) {
        CFRelease(_rotated);
    }
}

-(void)setRotatedBuffer:(CVPixelBufferRef)buffer {
    if (_rotated) {
        CFRelease(_rotated);
    }
    _rotated = buffer;
    if (_rotated) {
        CFRetain(_rotated);
    }
}

-(CVPixelBufferRef)rotatedBuffer {
    return _rotated;
}
@end



@interface RcvRPH264Encoder() {
    VTCompressionSessionRef _compressionSession;
    NSInteger _version;
    uint32_t _targetBitrateBps;
    uint32_t _encoderBitrateBps;
    int32_t _width;
    int32_t _height;
    BOOL _rotation;
    CFStringRef _profile;
    BOOL _keyFrame;
    dispatch_queue_t _queue;
    dispatch_source_t _timer;
    RcvCVPixelBufferConverter *_converter;
    OSType _pixelFormatType;
    NSDictionary *_nsSourceAttributes;
    NSDictionary *_nsFramePropertiesForKeyFrame;
}
-(void)destroyCompressionSession;
-(void)setEncoderBitrateBps:(uint32_t)bitrateBps;
-(void)resetCompressionSession;
-(void)configureCompressionSession;
-(void)frameWasEncoded:(OSStatus)status
                 flags:(VTEncodeInfoFlags)infoFlags
          sampleBuffer:(CMSampleBufferRef)sampleBuffer
     codecSpecificInfo:(id)codecSpecificInfo
                 width:(int32_t)width
                height:(int32_t)height
          renderTimeMs:(int64_t)renderTimeMs
           orientation:(CGImagePropertyOrientation)orientation
               version:(NSInteger)version;
-(void)onFire;
@property (atomic, strong) BufferHolder *buffer;
@property (nonatomic, readonly) RcvCVPixelBufferConverter *converter;
@property (nonatomic, readonly) CFDictionaryRef sourceAttributes;
@property (nonatomic, readonly) CFDictionaryRef framePropertiesForKeyFrame;
@end

void compressionOutputCallback(void *encoder,
                               void *params,
                               OSStatus status,
                               VTEncodeInfoFlags infoFlags,
                               CMSampleBufferRef sampleBuffer) {
    if (params == NULL) {
        return;
    }
    RcvRPEncoderParams *encodeParams = (RcvRPEncoderParams *)params;
    [encodeParams->encoder frameWasEncoded:status
                                     flags:infoFlags
                              sampleBuffer:sampleBuffer
                         codecSpecificInfo:nil
                                     width:encodeParams->width
                                    height:encodeParams->height
                              renderTimeMs:encodeParams->renderTimeMs
                               orientation:encodeParams->orientation
                                   version:encodeParams->version];
    delete encodeParams;
}


@implementation RcvRPH264Encoder

-(instancetype)init {
    if (self = [super init]) {
        _queue = dispatch_queue_create("com.rc.encoding", DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(_queue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
        
        RcvRPH264Encoder * __weak welf = self;
        _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _queue);
        dispatch_source_set_timer(_timer, DISPATCH_TIME_NOW, (1.0 / kFramePerSeconds) * NSEC_PER_SEC, 0.2 * NSEC_PER_SEC);
        dispatch_source_set_event_handler(_timer, ^{
            [welf onFire];
        });
        dispatch_resume(_timer);
        _pixelFormatType = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
    }
    return self;
}

-(void)dealloc {
    [self destroyCompressionSession];
    if (_timer) {
        dispatch_source_cancel(_timer);
        _timer = nil;
    }
}

-(void)createEncoder:(RcvRPEncodingSessionCreatePayload*)params {
    dispatch_async(_queue, ^{
        [self createEncoderInternal:params];
    });
}

-(void)createEncoderInternal:(RcvRPEncodingSessionCreatePayload*)params {
    dispatch_assert_queue_debug(_queue);
    if (params.version <= _version) {
        RCVRPWLOG("RCVRP createEncoder: skip due to version: %li, actual: %li", (long)params.version, (long)_version);
        return;
    }
    RCVRPILOG("RCVRP createEncoder: w:%lu, h:%lu, bitrate:%lu", (long)params.width, (long)params.height, (long)params.bitrate);
    _version = params.version;
    BOOL hadValue = _width > 0 && _height > 0;
    BOOL wasPortrait = isPortrait(_width, _height);
    _width = (int32_t)params.width;
    _height = (int32_t)params.height;
    if (hadValue && isPortrait(_width, _height) != wasPortrait) {
        std::swap(_width, _height);
    }
    _targetBitrateBps = (uint32_t)params.bitrate;
    _profile = kVTProfileLevel_H264_Baseline_3_1;
    _rotation = params.rotation;
    [self resetCompressionSession];
}

-(void)setBitrate:(RcvRPEncodingSessionBitratePayload*)params {
    dispatch_async(_queue, ^{
        [self setBitrateInternal:params];
    });
}

-(void)setBitrateInternal:(RcvRPEncodingSessionBitratePayload*)params {
    dispatch_assert_queue_debug(_queue);
    if (params.version != _version) {
        RCVRPWLOG("RCVRP setBitrate: skip due to version: %li, actual: %li", (long)params.version, (long)_version);
        return;
    }
    [self setEncoderBitrateBps:(uint32_t)params.bitrate];
}

-(void)destroyEncoder:(RcvRPEncodingSessionDestroyPayload*)param {
    dispatch_async(_queue, ^{
        [self destroyEncoderInternal:param];
    });
}

-(void)destroyEncoderInternal:(RcvRPEncodingSessionDestroyPayload*)params {
    dispatch_assert_queue_debug(_queue);
    if (params.version < _version) {
        RCVRPWLOG("RCVRP destroyEncoder: skip due to version: %li, actual: %li", (long)params.version, (long)_version);
        //return;
    }
    RCVRPILOG("RCVRP destroyEncoder");
    [self destroyCompressionSession];
}

-(void)requestKeyFrame:(RcvRPEncodingSessionKeyFramePayload*)param {
    dispatch_async(_queue, ^{
        [self requestKeyFrameInternal:param];
    });
}

-(void)requestKeyFrameInternal:(RcvRPEncodingSessionKeyFramePayload*)params {
    dispatch_assert_queue_debug(_queue);
    if (params.version != _version) {
        RCVRPWLOG("RCVRP requestKeyFrame: skip due to version: %li, actual: %li", (long)params.version, (long)_version);
        return;
    }
    RCVRPILOG("RCVRP requestKeyFrame");
    _keyFrame = YES;
}

-(void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer withType:(RPSampleBufferType)sampleBufferType {
    if (sampleBuffer == NULL) {
        return;
    }
    
    switch (sampleBufferType) {
        case RPSampleBufferTypeVideo:
            if (CMSampleBufferGetNumSamples(sampleBuffer) != 1) {
                return;
            }
            if (!CMSampleBufferIsValid(sampleBuffer)) {
                return;
            }
            if (!CMSampleBufferDataIsReady(sampleBuffer)) {
                return;
            }
            if (CMSampleBufferGetImageBuffer(sampleBuffer) == NULL) {
                return;
            }
            break;

        default:
            return;
    }
    [self processPixelBuffer:CMSampleBufferGetImageBuffer(sampleBuffer)
             withOrientation:SampleBufferOrientation(sampleBuffer)];
}

-(void)processPixelBuffer:(CVPixelBufferRef)pixelBuffer withOrientation:(CGImagePropertyOrientation)orientation {
    self.buffer = [[BufferHolder alloc] initWithBuffer:pixelBuffer orientation:orientation];
}

#pragma mark -
-(void)destroyCompressionSession {
    if (_compressionSession) {
        VTCompressionSessionInvalidate(_compressionSession);
        CFRelease(_compressionSession);
        _compressionSession = NULL;
    }
}

-(void)setEncoderBitrateBps:(uint32_t)bitrateBps {
    if (_compressionSession == NULL) {
        RCVRPWLOG("RCVRP setEncoderBitrateBps: compression is nil");
        return;
    }

    if (_encoderBitrateBps == bitrateBps) {
        RCVRPWLOG("RCVRP setEncoderBitrateBps: skip");
        return;
    }
    RCVRPILOG("RCVRP setEncoderBitrateBps: %li", (long)bitrateBps);
    
    SetVTSessionPropertySInt32(_compressionSession, kVTCompressionPropertyKey_AverageBitRate, bitrateBps);
    
    int64_t dataLimitBytesPerSecondValue = static_cast<int64_t>(bitrateBps * kLimitToAverageBitRateFactor / 8);
    CFNumberRef bytesPerSecond = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt64Type, &dataLimitBytesPerSecondValue);
    int64_t oneSecondValue = 1;
    CFNumberRef oneSecond = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt64Type, &oneSecondValue);
    const void *nums[2] = {bytesPerSecond, oneSecond};
    CFArrayRef dataRateLimits = CFArrayCreate(nullptr, nums, 2, &kCFTypeArrayCallBacks);
    OSStatus status = VTSessionSetProperty(_compressionSession, kVTCompressionPropertyKey_DataRateLimits, dataRateLimits);
    if (bytesPerSecond != NULL) {
        CFRelease(bytesPerSecond);
    }
    if (oneSecond != NULL) {
        CFRelease(oneSecond);
    }
    if (dataRateLimits) {
        CFRelease(dataRateLimits);
    }
    if (status != noErr) {
        RCVRPWLOG("RCVRP Failed to set data rate limit with code: %@", RCVRPOSERROR(status));
    }
    _encoderBitrateBps = bitrateBps;
}

-(void)resetCompressionSession {
    [self destroyCompressionSession];
    OSStatus status =
    VTCompressionSessionCreate(nullptr,  // use default allocator
                               _width,
                               _height,
                               kCMVideoCodecType_H264,
                               nullptr,  // use hardware accelerated encoder if available
                               self.sourceAttributes,
                               nullptr,  // use default compressed data allocator
                               compressionOutputCallback,
                               nullptr,
                               &_compressionSession);
    if (status != noErr) {
        RCVRPWLOG("Failed to create compression session: %@", RCVRPOSERROR(status));
    }
    [self configureCompressionSession];
}

-(void)configureCompressionSession {
    if (_compressionSession == NULL) {
        RCVRPWLOG("RCVRP configureCompressionSession session is nil");
        return;
    }
    _keyFrame = NO;
    _encoderBitrateBps = 0; /// Force setEncoderBitrateBps
    SetVTSessionPropertyBool(_compressionSession, kVTCompressionPropertyKey_RealTime, true);
    SetVTSessionPropertyStr(_compressionSession, kVTCompressionPropertyKey_ProfileLevel, _profile);
    SetVTSessionPropertyBool(_compressionSession, kVTCompressionPropertyKey_AllowFrameReordering, false);
    [self setEncoderBitrateBps:_targetBitrateBps];
    SetVTSessionPropertySInt32(_compressionSession, kVTCompressionPropertyKey_MaxKeyFrameInterval, 7200);
    SetVTSessionPropertySInt32(_compressionSession, kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration, 240);
}

-(void)framePayloadProduced:(RcvRPEncodingSessionEncodedFramePayload *)payload {
    dispatch_assert_queue_debug(_queue);
    if (payload.version != _version) {
        return;
    }
    [self.delegate encoder:self didEncodeFrame:payload];
}

-(void)frameWasEncoded:(OSStatus)status
                 flags:(VTEncodeInfoFlags)infoFlags
          sampleBuffer:(CMSampleBufferRef)sampleBuffer
     codecSpecificInfo:(id)codecSpecificInfo
                 width:(int32_t)width
                height:(int32_t)height
          renderTimeMs:(int64_t)renderTimeMs
           orientation:(CGImagePropertyOrientation)orientation
               version:(NSInteger)version {
    
    if (status != noErr) {
        RCVRPWLOG("H264 encode failed with code: %i", (int)status);
        return;
    }
    if (infoFlags & kVTEncodeInfo_FrameDropped) {
        RCVRPWLOG("H264 encode dropped frame.");
        return;
    }
    BOOL isKeyframe = SampleBufferHasKeyFrame(sampleBuffer);
    RcvRPEncodingSessionEncodedFramePayload *payload = [RcvRPEncodingSessionEncodedFramePayload new];
    payload.version = version;
    payload.keyFrame = isKeyframe;
    
    if (!SampleBufferAVCCToAnnexb(sampleBuffer, isKeyframe, payload)) {
        return;
    }
    payload.encodedWidth = width;
    payload.encodedHeight = height;
    payload.captureTimeMs = renderTimeMs;
    payload.orientation = (NSInteger)orientation;
    
    dispatch_async(_queue, ^{
        [self framePayloadProduced:payload];
    });
}

-(BOOL)pixelBufferCanBeEncodedWithCurrentSession:(CVPixelBufferRef)pixelBuffer orientation:(CGImagePropertyOrientation)orientation {
    size_t w = CVPixelBufferGetWidth(pixelBuffer);
    size_t h = CVPixelBufferGetHeight(pixelBuffer);
    size_t m = orientationToMultiplier(orientation);
    size_t rotatedW = m % 2 ? h : w;
    size_t rotatedH = m % 2 ? w : h;
    return isPortrait((int32_t)rotatedW, (int32_t)rotatedH) == isPortrait(_width, _height);
}

-(CVPixelBufferRef)rotatePixelBufferIfNeeded:(CVPixelBufferRef)pixelBuffer orientation:(CGImagePropertyOrientation)orientation {
    return [self.converter rotate:pixelBuffer
                         constant:orientationToMultiplier(orientation)
                          usePool:YES];
}

-(void)onFire {
    dispatch_assert_queue_debug(_queue);
    
    BufferHolder *bufferHolder = self.buffer;
    CVPixelBufferRef pixelBuffer = bufferHolder.buffer;
    CGImagePropertyOrientation orientation = bufferHolder.orientation;
    if (pixelBuffer == NULL) {
        return;
    }
    if (_compressionSession == NULL) {
        return;
    }
    
    OSType pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer);
    if (_pixelFormatType != pixelFormat) {
        _pixelFormatType = pixelFormat;
        _nsSourceAttributes = nil;
        [self resetCompressionSession];
        return;
    }
    
    CFDictionaryRef frameProperties = NULL;
    if (_keyFrame) {
        frameProperties = self.framePropertiesForKeyFrame;
        _keyFrame = NO;
    }
    
    if (_rotation) {
        // Do nothing
    } else {
        if (![self pixelBufferCanBeEncodedWithCurrentSession:pixelBuffer orientation:orientation]) {
            std::swap(_width, _height);
            RCVRPDLOG("RCVRP Swap target frame orientation:%i x %i", _width, _height);
            [self resetCompressionSession];
        }
        
        if (orientation != kCGImagePropertyOrientationUp) {
            if (bufferHolder.rotatedBuffer) {
                pixelBuffer = bufferHolder.rotatedBuffer;
            } else {
                CVPixelBufferRef rotatedPixelBuffer = [self rotatePixelBufferIfNeeded:pixelBuffer orientation:orientation];
                if (rotatedPixelBuffer == NULL) {
                    RCVRPWLOG("RCVRP Rotation Failed");
                    return;
                }
                bufferHolder.rotatedBuffer = rotatedPixelBuffer;
                CFRelease(rotatedPixelBuffer);
                pixelBuffer = rotatedPixelBuffer;
            }
            orientation = kCGImagePropertyOrientationUp;
        }
    }
    
    RcvRPEncoderParams *encodeParams = new RcvRPEncoderParams();
    encodeParams->encoder = self;
    encodeParams->width = _width;
    encodeParams->height = _height;
    encodeParams->orientation = orientation;
    encodeParams->renderTimeMs = CACurrentMediaTime() * kMillisecondsPerSecond;
    encodeParams->version = _version;
    
    OSStatus status = VTCompressionSessionEncodeFrame(_compressionSession,
                                                      pixelBuffer,
                                                      CMTimeMake(encodeParams->renderTimeMs, 1000),
                                                      kCMTimeInvalid,
                                                      frameProperties,
                                                      encodeParams,
                                                      NULL);

    if (status != noErr) {
        RCVRPWLOG("Failed to encode frame with code: %i", (int)status);
        return;
    }
}

-(RcvCVPixelBufferConverter *)converter {
    if (_converter == nil) {
        _converter = [[RcvCVPixelBufferConverter alloc] init];
    }
    return _converter;
}

-(CFDictionaryRef)sourceAttributes {
    if (_nsSourceAttributes == nil) {
        _nsSourceAttributes = @{
                        (id)kCVPixelBufferIOSurfacePropertiesKey: @{},
                        (id)kCVPixelBufferOpenGLESCompatibilityKey: @(YES),
                        (id)kCVPixelBufferPixelFormatTypeKey: @(_pixelFormatType)
                        };
    }
    return (__bridge CFDictionaryRef)(_nsSourceAttributes);
}

-(CFDictionaryRef)framePropertiesForKeyFrame {
    if (_nsFramePropertiesForKeyFrame == nil) {
        _nsFramePropertiesForKeyFrame = @{
                                          (id)kVTEncodeFrameOptionKey_ForceKeyFrame: @(YES)
                                          };
    }
    return (__bridge CFDictionaryRef)(_nsFramePropertiesForKeyFrame);
}

@end
