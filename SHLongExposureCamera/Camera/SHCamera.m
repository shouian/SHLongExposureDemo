//
//  SHCamera.m
//  SHLongExposureCamera
//
//  Created by shouian on 13/8/23.
//  Copyright (c) 2013年 shouian. All rights reserved.
//

#import "SHCamera.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreImage/CoreImage.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>
#import <QuartzCore/QuartzCore.h>
#import <Accelerate/Accelerate.h>
#import <MediaPlayer/MediaPlayer.h>

@interface SHCamera() <AVCaptureVideoDataOutputSampleBufferDelegate>
{
    // Device Session
    AVCaptureSession *session;
    AVCaptureDevice  *cameraDevice;
    
    CIContext        *imageContext;
    CIVector         *alphaVector;
    CGFloat          alpha;
    
    // Mixing Filter
    CIFilter *blendFilter;
    CIFilter *mixFilter;
    CIFilter *alphaFilterInput;
    CIFilter *outCompositing;
    CIFilter *contrastFilter;
    CIFilter *gammaFilter;
    CIFilter *fStopFilter;
    
    // Image Session
    NSMutableArray  *imageArray;
    CIImage         *tmpSnapImage;
    
    // Control Setting
    BOOL startToTakePhotos;
    int  imageCounterCount;
    
    // Result Block to pass result
    CameraResult resultBlock;
    
}

- (id)initWithCamera;
- (void)setUpFilter;
- (void)setUpCamera;
- (AVCaptureVideoPreviewLayer *) previewInView: (UIView *) view;
- (void)timerSnap:(NSTimer *)timer;

@end

@implementation SHCamera

@synthesize sensitivity  = _sensitivity;
@synthesize ev           = _ev;
@synthesize exposureTime = _exposureTime;
@synthesize isCameraBack = _isCameraBack;
@synthesize imgView      = _imgView;

#pragma mark - Initialize

+ (id)sharedInstance
{
    static SHCamera *camrea = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        camrea = [[SHCamera alloc] initWithCamera];
    });
    return camrea;
}

- (id)initWithCamera
{
    self = [super init];
    if (self) {
        // Basic parameters
        imageContext = [CIContext contextWithOptions:nil];
        imageArray   = [NSMutableArray array];
        
        // Parameter to record
        startToTakePhotos = NO;
        
        // Default parameters
        _sensitivity    = 1.0f;
        _exposureTime   = 0.5f;
        _ev             = 2.0f;
        _isCameraBack   = YES;
        
        [self setUpFilter];
        [self setUpCamera];
        
    }
    return self;
}

- (void)setUpFilter
{
    blendFilter         = [CIFilter filterWithName:@"CILightenBlendMode"];
    mixFilter           = [CIFilter filterWithName:@"CIMaximumCompositing"];
    alphaFilterInput    = [CIFilter filterWithName:@"CIColorMatrix"];
    
    contrastFilter      = [CIFilter filterWithName:@"CIColorControls"];
    [contrastFilter setDefaults];
    
    fStopFilter         = [CIFilter filterWithName:@"CIExposureAdjust"];
    [fStopFilter setDefaults];
    
    gammaFilter         = [CIFilter filterWithName:@"CIGammaAdjust"];
    [gammaFilter setValue:[NSNumber numberWithFloat:1.0f] forKey:@"inputPower"];
    
    alphaVector         = [CIVector vectorWithX:0 Y:0 Z:0 W:1.0f];
}

- (void)setUpCamera
{
    // In ARC. we do not have to handle its release problem
    session = [[AVCaptureSession alloc] init];
    // Set resolution
    session.sessionPreset = AVCaptureSessionPresetMedium;
    
    [session beginConfiguration]; // Begin to setup session
    
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    if (_isCameraBack) {
        // Set up back camera
        for (AVCaptureDevice *device in devices) {
            if (device.position == AVCaptureDevicePositionBack) {
                cameraDevice = device;
                break;
            }
        }
    } else {
        for (AVCaptureDevice *device in devices) {
            // Setup front camera
            if (device.position == AVCaptureDevicePositionFront) {
                cameraDevice = device;
                break;
            }
        }
    }
    
    // Add Input device
    NSError *error;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:cameraDevice error:&error];
    [session addInput:input];
    
    // Add output device
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    [output setAlwaysDiscardsLateVideoFrames:YES];
    [output setSampleBufferDelegate:self queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)];
    output.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    
    [session addOutput:output];
    [session commitConfiguration];
}

- (void)showViewInCamera
{
    // Start to show image
    [session startRunning];
}

- (void)stopViewInCamera
{
    // Stop configuring image
    [session stopRunning];
}

- (void)setUpPreviewView:(UIView *)imgView
{
    if (!session) {
        NSLog(@"There is no session");
        return;
    }
    
    _imgView = imgView;
    
    AVCaptureVideoPreviewLayer *previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:session];
    previewLayer.frame = CGRectMake(0, 0, _imgView.frame.size.width, _imgView.frame.size.height);
    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    // Show preview layer on this image view
    [_imgView.layer addSublayer:previewLayer];
    
    // Set the orientation layout subview
    [self layoutPreviewInView];
    
}

- (AVCaptureVideoPreviewLayer *) previewInView: (UIView *) view
{
    for (CALayer *layer in view.layer.sublayers)
        if ([layer isKindOfClass:[AVCaptureVideoPreviewLayer class]])
            return (AVCaptureVideoPreviewLayer *)layer;
    
    return nil;
}

- (void) layoutPreviewInView
{
    AVCaptureVideoPreviewLayer *layer = [self previewInView:_imgView];
    if (!layer) return;
    
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    CATransform3D transform = CATransform3DIdentity;
    if (orientation == UIDeviceOrientationPortrait) ;
    else if (orientation == UIDeviceOrientationLandscapeLeft)
        transform = CATransform3DMakeRotation(-M_PI_2, 0.0f, 0.0f, 1.0f);
    else if (orientation == UIDeviceOrientationLandscapeRight)
        transform = CATransform3DMakeRotation(M_PI_2, 0.0f, 0.0f, 1.0f);
    else if (orientation == UIDeviceOrientationPortraitUpsideDown)
        transform = CATransform3DMakeRotation(M_PI, 0.0f, 0.0f, 1.0f);
    
    layer.transform = transform;
    layer.frame = CGRectMake(0, 0, _imgView.frame.size.width, _imgView.frame.size.height);
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    @autoreleasepool {
        
        CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
        CIImage *image = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer options:(__bridge_transfer NSDictionary *)attachments];
        
        image = [image imageByApplyingTransform:CGAffineTransformMakeRotation(-M_PI_2)];
        CGPoint origin = [image extent].origin;
        image = [image imageByApplyingTransform:CGAffineTransformMakeTranslation(-origin.x, -origin.y)];
        
        // Start to record image
        if (startToTakePhotos == YES) {
            // Add image to image array
            [imageArray addObject:image];
        }
        
    }
}

#pragma mark - Action Method
- (void)takeSnap:(CameraBegin)begin withCompletetion:(CameraResult)result
{
    resultBlock = [result copy];
    
    startToTakePhotos = YES;
    
    // Execute the beginning block
    begin();
    
    // Set up timer to record
    [NSTimer scheduledTimerWithTimeInterval:_exposureTime target:self selector:@selector(timerSnap:) userInfo:nil repeats:NO];

}

-(void)timerSnap:(NSTimer *)timer
{
    startToTakePhotos = NO;
    
    [timer invalidate];
    timer = nil;
    
    // The first image
    CIImage *firstSnapImage = [imageArray objectAtIndex:0];
    
    // BlockImage
    CIImage *backImage = firstSnapImage;
    CIImage *inputImage = [[CIImage alloc] init];
    
    CGImageRef tmpRef   = [imageContext createCGImage:backImage fromRect:backImage.extent];
    UIImage *imageBack  = [[UIImage alloc] initWithCGImage:tmpRef];
    UIImage *imageInput = [[UIImage alloc] init];
    
    for (int i = 0; i < imageArray.count; i++) {
        // Add Autorealse pool to release imageref
        @autoreleasepool {
            // Get the CIImage in each of item for imageArray
            inputImage = [imageArray objectAtIndex:i];
            
            // Transfer CIImage to CIImageRef
            CGImageRef inputImageRef = [imageContext createCGImage:inputImage fromRect:inputImage.extent];
            // Transfer CIImage to UIImage
            imageInput = [UIImage imageWithCGImage:inputImageRef];
            // Set up the two CIImage
            backImage   = [[CIImage alloc] initWithImage:imageBack];
            inputImage  = [[CIImage alloc] initWithImage:imageInput];
            
            // Actually, the value for sensitivity is just the alpha or opacity value
            // Set up the CIImage filter chain
            // 1. Alpha opacity filter
            alpha = _sensitivity;
            alphaVector = [CIVector vectorWithX:0 Y:0 Z:0 W:alpha];
            [alphaFilterInput setValue:alphaVector forKey:@"inputAVector"];
            [alphaFilterInput setValue:inputImage forKey:@"inputImage"];
            inputImage = alphaFilterInput.outputImage;
            
            // 2. Enhance Contrast
            [contrastFilter setValue:inputImage forKey:@"inputImage"];
            [contrastFilter setValue:[NSNumber numberWithFloat:1.1f] forKey:@"inputContrast"];
            [contrastFilter setValue:[NSNumber numberWithFloat:0.05f] forKey:@"inputBrightness"];
            inputImage = contrastFilter.outputImage;
            
            // 3. Add Gamma
            [gammaFilter setValue:inputImage forKey:@"inputImage"];
            inputImage = gammaFilter.outputImage;
            
            // 4. Blend backimage and inputimage
            [blendFilter setValue:backImage forKey:@"inputBackgroundImage"];
            [blendFilter setValue:inputImage forKey:@"inputImage"];
            backImage = blendFilter.outputImage;
            
            // 5. Release all image
            CGImageRef backRef = [imageContext createCGImage:backImage fromRect:backImage.extent];
            imageBack =  [UIImage imageWithCGImage:backRef];
            
            CGImageRelease(inputImageRef);
            CGImageRelease(backRef);
            imageInput = nil;
            inputImage = nil;
            
        }
    }
    
    // Bloom Effect
    [fStopFilter setValue:[NSNumber numberWithFloat:_ev] forKey:@"inputEV"];
    [fStopFilter setValue:backImage forKey:@"inputImage"];
    backImage = fStopFilter.outputImage;
    
    // Compositing the firstImage with the blurred image
    [mixFilter setValue:firstSnapImage forKey:@"inputBackgroundImage"];
    [mixFilter setValue:backImage forKey:@"inputImage"];
    backImage = mixFilter.outputImage;
    
    // Finally, Generate the UIImage
    CGImageRef cgImageOutPut = [imageContext createCGImage:backImage fromRect:backImage.extent];
    UIImage *resultImage = [UIImage imageWithCGImage:cgImageOutPut];
    
    resultBlock(resultImage);
    
    // Reset the image array
    imageArray = [NSMutableArray array];
    
    // Release the rest image resource
    imageBack = nil;
    backImage = nil;
    firstSnapImage = nil;
    resultImage = nil;
    
    CGImageRelease(cgImageOutPut);
    CGImageRelease(tmpRef);
    
}

@end
