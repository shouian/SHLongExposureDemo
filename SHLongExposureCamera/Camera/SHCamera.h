//
//  SHCamera.h
//  SHLongExposureCamera
//
//  Created by shouian on 13/8/23.
//  Copyright (c) 2013年 shouian. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^CameraResult) (UIImage *image);
typedef void (^CameraBegin) (void);

@interface SHCamera : NSObject

@property (nonatomic)           CGFloat sensitivity;
@property (nonatomic)           CGFloat ev;
@property (nonatomic)           float   exposureTime;
@property (nonatomic)           BOOL    isCameraBack;
@property (nonatomic, readonly) UIView *imgView;

+ (id)sharedInstance;

- (void)showViewInCamera;
- (void)stopViewInCamera;
- (void)setUpPreviewView:(UIView *)imgView;
- (void)takeSnap:(CameraBegin)begin withCompletetion:(CameraResult)result;

@end
