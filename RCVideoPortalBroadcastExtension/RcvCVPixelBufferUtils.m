//
//  RcvCVPixelBufferUtils.m
//  GlipCore
//
//  Created by Roman Gaiu on 6/29/18.
//  Copyright © 2018 RingCentral. All rights reserved.
//

#import "RcvCVPixelBufferUtils.h"
#import <Accelerate/Accelerate.h>

#define FORMAT_TYPE kCVPixelFormatType_420YpCbCr8BiPlanarFullRange

#define rcv_defer_block_name_with_prefix(prefix, suffix) prefix ## suffix
#define rcv_defer_block_name(suffix) rcv_defer_block_name_with_prefix(rcv_defer_, suffix)
#define rcv_defer __strong void(^rcv_defer_block_name(__LINE__))(void) __attribute__((cleanup(rcv_defer_cleanup_block), unused)) = ^
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-function"
static void rcv_defer_cleanup_block(__strong void(^*block)(void)) {
    (*block)();
}
#pragma clang diagnostic pop

@interface RcvCVRotationPipeline : NSObject
-(instancetype)initWithFormatType:(OSType)formatType width:(size_t)width height:(size_t)height constant:(uint8_t)constant;
@property (nonatomic, readonly) OSType formatType;
@property (nonatomic, readonly) size_t width;
@property (nonatomic, readonly) size_t height;
@property (nonatomic, readonly) size_t outWidth;
@property (nonatomic, readonly) size_t outHeight;
@property (nonatomic, readonly) uint8_t constant;

@property (nonatomic, readonly) const vImage_YpCbCrPixelRange *pixelRange;
@property (nonatomic, readonly) CFDictionaryRef pixelAttributes;
@property (nonatomic, readonly, nullable) CVPixelBufferPoolRef pixelBufferPool;
@end


@interface RcvCVPixelBufferConverter()
@property (nonatomic, strong) RcvCVRotationPipeline *rotation;
@end

@implementation RcvCVPixelBufferConverter

+(NSDictionary *)pixelAttributes
{
    return  @{
              (id)kCVPixelBufferIOSurfacePropertiesKey: @{},
              (id)kCVPixelBufferOpenGLESCompatibilityKey: @(YES),
              (id)kCVPixelBufferPixelFormatTypeKey: @(FORMAT_TYPE)
              };
}

+(NSDictionary *)pixelAttributesWith:(NSInteger)width height:(NSInteger)height
{
    return  @{
              (id)kCVPixelBufferIOSurfacePropertiesKey: @{},
              (id)kCVPixelBufferOpenGLESCompatibilityKey: @(YES),
              (id)kCVPixelBufferPixelFormatTypeKey: @(FORMAT_TYPE),
              (id)kCVPixelBufferWidthKey : @(width),
              (id)kCVPixelBufferHeightKey : @(height)
              };
}

-(CVPixelBufferRef)rotate:(CVPixelBufferRef)pixelBuffer
                 constant:(uint8_t)rotationConstant
                  usePool:(BOOL)usePool {
    if (pixelBuffer == NULL) {
        return NULL;
    }
    
    OSType formatType = CVPixelBufferGetPixelFormatType(pixelBuffer);
    if (formatType != kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
        && formatType != kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) {
        return NULL;
    }
    size_t width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0);
    size_t height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0);

    RcvCVRotationPipeline *rotation = self.rotation;
    
    if (rotation == nil
        || rotation.formatType != formatType
        || rotation.width != width
        || rotation.height != height
        || rotation.constant != rotationConstant) {
        rotation = [[RcvCVRotationPipeline alloc] initWithFormatType:formatType
                                                               width:width
                                                              height:height
                                                            constant:rotationConstant];
    }
    
    vImage_Error vImgResult = kvImageNoError;
    CVReturn cvResult = kCVReturnSuccess;
    cvResult = CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
    if (cvResult != kCVReturnSuccess) {
        return NULL;
    }
    rcv_defer {
        CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
    };

    CVPixelBufferRef result;
    if (usePool) {
        cvResult = CVPixelBufferPoolCreatePixelBuffer(NULL, rotation.pixelBufferPool, &result);
    } else {
        cvResult = CVPixelBufferCreate(NULL, rotation.outWidth, rotation.outHeight, rotation.formatType, rotation.pixelAttributes, &result);
    }
    if (cvResult != kCVReturnSuccess) {
        return NULL;
    }
    if (rotation.outWidth != CVPixelBufferGetWidth(result)
        || rotation.outHeight != CVPixelBufferGetHeight(result)) {
        CVPixelBufferRelease(result);
        return NULL;
    }
    if (CVPixelBufferLockBaseAddress(result, 0) != kCVReturnSuccess) {
        return NULL;
    }
    
    rcv_defer {
        CVPixelBufferUnlockBaseAddress(result, 0);
    };

    vImage_Buffer originalYBuffer = {
        CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0),
        CVPixelBufferGetHeightOfPlane(pixelBuffer, 0),
        CVPixelBufferGetWidthOfPlane(pixelBuffer, 0),
        CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0) };
    vImage_Buffer originalUVBuffer = {
        CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1),
        CVPixelBufferGetHeightOfPlane(pixelBuffer, 1),
        CVPixelBufferGetWidthOfPlane(pixelBuffer, 1),
        CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1) };

    vImage_Buffer targetYBuffer = {
        CVPixelBufferGetBaseAddressOfPlane(result, 0),
        CVPixelBufferGetHeightOfPlane(result, 0),
        CVPixelBufferGetWidthOfPlane(result, 0),
        CVPixelBufferGetBytesPerRowOfPlane(result, 0) };
    vImage_Buffer targetUVBuffer = {
        CVPixelBufferGetBaseAddressOfPlane(result, 1),
        CVPixelBufferGetHeightOfPlane(result, 1),
        CVPixelBufferGetWidthOfPlane(result, 1),
        CVPixelBufferGetBytesPerRowOfPlane(result, 1) };

    // 0, 1, 2, 3 is equal to 0, 90, 180, 270 degrees rotation
    vImgResult = vImageRotate90_Planar8(&originalYBuffer, &targetYBuffer, rotationConstant, 0, kvImageNoFlags);
    if (vImgResult != kvImageNoError) { return NULL; }
    vImgResult = vImageRotate90_Planar16U(&originalUVBuffer, &targetUVBuffer, rotationConstant, 0, kvImageNoFlags);
    if (vImgResult != kvImageNoError) { return NULL; }
    self.rotation = rotation;
    return result;
}

@end


@implementation RcvCVRotationPipeline {
    vImage_YpCbCrPixelRange _YpCbCrPixelRange;
    NSDictionary *_attributes;
    CVPixelBufferPoolRef _pixelBufferPool;
}

-(instancetype)initWithFormatType:(OSType)formatType width:(size_t)width height:(size_t)height constant:(uint8_t)constant {
    if (self = [super init]) {
        _formatType = formatType;
        _width = width;
        _height = height;
        _constant = constant;
        // 0, 1, 2, 3 is equal to 0, 90, 180, 270 degrees rotation
        BOOL rotatePerpendicular = (constant == 1) || (constant == 3);
        _outWidth = rotatePerpendicular ? height : width;
        _outHeight = rotatePerpendicular ? width : height;
    }
    return self;
}

-(void)dealloc {
    if (_pixelBufferPool) {
        CVPixelBufferPoolRelease(_pixelBufferPool);
    }
}

-(const vImage_YpCbCrPixelRange *)pixelRange {
    if (_formatType == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange) {
        _YpCbCrPixelRange = (vImage_YpCbCrPixelRange){ 16, 128, 235, 240, 235, 16, 240, 16 };
    } else if (_formatType == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) {
        _YpCbCrPixelRange = (vImage_YpCbCrPixelRange){ 0, 128, 255, 255, 255, 1, 255, 0 };
    } else {
        _YpCbCrPixelRange = (vImage_YpCbCrPixelRange){ 0, 0, 0, 0, 0, 0, 0, 0 };
    }
    return &_YpCbCrPixelRange;
}

-(CFDictionaryRef)pixelAttributes {
    if (_attributes == nil) {
        _attributes = @{
                        (id)kCVPixelBufferIOSurfacePropertiesKey: @{},
                        (id)kCVPixelBufferOpenGLESCompatibilityKey: @(YES),
                        (id)kCVPixelBufferPixelFormatTypeKey: @(_formatType)
                        };
    }
    return (__bridge CFDictionaryRef)(_attributes);
}

- (CVPixelBufferPoolRef)pixelBufferPool {
    if (_pixelBufferPool == NULL) {
        _pixelBufferPool = [self createPixelBufferPoolWithWidth:_width height:_height pixelFormat:_formatType minBufferCount:10];
    }
    return _pixelBufferPool;
}

- (CVPixelBufferPoolRef)createPixelBufferPoolWithWidth:(size_t)width height:(size_t)height pixelFormat:(FourCharCode)pixelFormat minBufferCount:(int32_t) minBufferCount {
    CVPixelBufferPoolRef outputPool = NULL;

    NSDictionary *sourcePixelBufferOptions = @{
        (id)kCVPixelBufferPixelFormatTypeKey : @(pixelFormat),
        (id)kCVPixelBufferWidthKey : @(_outWidth),
        (id)kCVPixelBufferHeightKey : @(_outHeight),
        (id)kCVPixelBufferIOSurfacePropertiesKey : @{}
    };

    NSDictionary *pixelBufferPoolOptions = @{ (id)kCVPixelBufferPoolMinimumBufferCountKey : @(minBufferCount) };
    CVPixelBufferPoolCreate(kCFAllocatorDefault, (__bridge CFDictionaryRef)pixelBufferPoolOptions, (__bridge CFDictionaryRef)sourcePixelBufferOptions, &outputPool);
    return outputPool;
}

@end

