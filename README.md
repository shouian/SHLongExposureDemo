
SHCamera
===========

This is a opensource used to make your iPhone Act like a DSLR.
SHCamera is just a singleton existing in your application lifecycle. 

[![](https://raw.github.com/shouian/SHLongExposureDemo/master/Screens/IMG_2274.JPG)](https://raw.github.com/shouian/SHLongExposureDemo/master/Screens/IMG_2274.JPG)
[![](https://raw.github.com/shouian/SHLongExposureDemo/master/Screens/IMG_3048.JPG)](https://raw.github.com/shouian/SHLongExposureDemo/master/Screens/IMG_3048.JPG)
[![](https://raw.github.com/shouian/SHLongExposureDemo/master/Screens/IMG_3853.PNG)](https://raw.github.com/shouian/SHLongExposureDemo/master/Screens/IMG_3853.PNG)
[![](https://raw.github.com/shouian/SHLongExposureDemo/master/Screens/IMG_3854.PNG)](https://raw.github.com/shouian/SHLongExposureDemo/master/Screens/IMG_3854.PNG)

## How To Initialize? (Basic Requirement)

It is just easy to use

Before start up to use, you have to import the following framework in your app project

``` objective-c
#import <AVFoundation/AVFoundation.h>
#import <CoreImage/CoreImage.h>
#import <Accelerate/Accelerate.h>
#import <MediaPlayer/MediaPlayer.h> 
```
And in your view controller or view you want to use this object, just import it with
``` objective-c
#import "SHCamera.h"
```
Now we are going to start 
``` objective-c
// Set up preview in view and of course, you can set up its property to control its behavior
// This code can be put in anywhere
SHCamera *camera = [SHCamera sharedInstance];

// This will ask camera to start run session
[camera showViewInCamera];

// Setup the preview View
UIView *imgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - TOOLBAR_HEIGHT)];
imgView.tag = IMGVIEW_TAG;
[self.view addSubview:imgView];

// Layout its subview
- (void)viewDidLayoutSubviews
{
    UIView *imgView = [self.view viewWithTag:IMGVIEW_TAG];
    [[SHCamera sharedInstance] setUpPreviewView:imgView];
}
```

## How to take a photo ?

Use the method takeSnap: withCompletetion:^(UIImage *image) and you can easily to take a photo with a long exposure

``` objective-c
[[SHCamera sharedInstance] takeSnap:^{
            
            // Things you want to do in the beginning of taking photos
            // Such show up a alertview or inidcator view
            
        } withCompletetion:^(UIImage *image) {
        
            // Things you want to do when finishing of taking photos
            // Such saving photos to your camera roll

        }];
```

## Property

Property used to control sensitivity, when the value gets higher, your photo will gets more lighter 
In general we suggest you to set this value less than 1.
The most suitable value could be 1/16 or 1/8. 
This default value is 1.
``` objective-c
@property (nonatomic)           CGFloat sensitivity;
```
Property used to control light, when the value gets higher, your photo will gets more lighter 
This default value is 0.5.
``` objective-c
@property (nonatomic)           CGFloat ev;
```
Property used to control exposure time in seconds, when the value gets higher, your photo will gets more lighter 
This default value is 0.5 seconds
Note that if this value is too large, it will affect your iPhone's performance or take out all of your memory.
The suitable range could be 1/30 seconds to 30 seconds.
``` objective-c
@property (nonatomic)           float   exposureTime;
```
Set the camera is back or front
The default value is YES.
``` objective-c
@property (nonatomic)           BOOL    isCameraBack;
```
The image view used for showing frame buffer in camera's view
``` objective-c
@property (nonatomic, readonly) UIView *imgView;
```

## Method

Singleton method used for initialization
``` objective-c
+ (id)sharedInstance;
```
Start to run image buffer coming from your camera
``` objective-c
- (void)showViewInCamera;
```
Stop running image buffer coming from your camera
``` objective-c
- (void)stopViewInCamera;
```
Required method, set the preview image view to show buffer from your camera.
Without this method, your app will show nothing from your camera's view.
``` objective-c
- (void)setUpPreviewView:(UIView *)imgView;
```
Method used for taking photos
``` objective-c
- (void)takeSnap:(CameraBegin)begin withCompletetion:(CameraResult)result;
```

## About this Demo

In this example we just show the easiest way to demo how to take a long exposure picture with iPhone.
This class SHCamera still need to be improved, and if you find any question about this demo, just email us.

## ARC 

This step we just use ARC to build up this class


## Contact

[Shawn & TakoBear](https://github.com/shouian)
