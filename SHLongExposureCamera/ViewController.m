//
//  ViewController.m
//  SHLongExposureCamera
//
//  Created by shouian on 13/8/23.
//  Copyright (c) 2013年 shouian. All rights reserved.
//

#import "ViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "SHCamera.h"
#import "OptionalView.h"

#define IMGVIEW_TAG    1001
#define OPTIONVIEW_TAG 1002
#define ALERTVIEW_TAG  1003

#define TOOLBAR_HEIGHT 130

@interface ViewController ()
{
    BOOL isShow;
    OptionalView *optionView;
}

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    SHCamera *camera = [SHCamera sharedInstance];
    // Set up preview in view
    [camera setExposureTime:1.0f];
    [camera showViewInCamera];
        
    // Camera Button
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - TOOLBAR_HEIGHT, 120, 44)];
    [button setCenter:CGPointMake(CGRectGetMidX(self.view.frame), button.center.y)];
    [button setTitle:@"Snap!" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button setBackgroundColor:[UIColor redColor]];
    [button addTarget:self action:@selector(buttonDidClick:) forControlEvents:UIControlEventTouchUpInside];
    [button.layer setCornerRadius:5.0f];
    
    [self.view addSubview:button];

    // Camera View
    UIView *imgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - TOOLBAR_HEIGHT)];
    imgView.tag = IMGVIEW_TAG;
    [self.view addSubview:imgView];
    
    // Option Button
    UIButton *option = [[UIButton alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - TOOLBAR_HEIGHT, 70, 44)];
    [option setCenter:CGPointMake(CGRectGetMidX(self.view.frame) +  100, button.center.y)];
    [option setTitle:@"Option" forState:UIControlStateNormal];
    [option setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [option setBackgroundColor:[UIColor blueColor]];
    [option addTarget:self action:@selector(optionButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    [option.layer setCornerRadius:5.0f];
    [self.view addSubview:option];
    
    // Set option view
    optionView = [[OptionalView alloc] initWithFrame:CGRectMake(10, 150, 300, 250)];
    optionView.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.55];
    
    isShow = NO;
    
    // Set alert view
    UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    
    [activityView setFrame:CGRectMake(imgView.center.x,
                                      imgView.center.y,
                                      activityView.bounds.size.width,
                                      activityView.bounds.size.height)];
    
    [activityView setHidesWhenStopped:YES];
    activityView.tag = ALERTVIEW_TAG;
    [self.view addSubview:activityView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLayoutSubviews
{
    UIView *imgView = [self.view viewWithTag:IMGVIEW_TAG];
    [[SHCamera sharedInstance] setUpPreviewView:imgView];
}

#pragma mark - Action
- (void)buttonDidClick:(id)sender
{
    UIActivityIndicatorView *indicator = (UIActivityIndicatorView *)[self.view viewWithTag:ALERTVIEW_TAG];
    
    if (isShow == NO) {
        
        [[SHCamera sharedInstance] takeSnap:^{
            
            [indicator startAnimating];
            
        } withCompletetion:^(UIImage *image) {
            
            [indicator stopAnimating];
            NSLog(@"Successfully write image!");
            UIImageWriteToSavedPhotosAlbum(image, self, nil, nil);
        }];
        
    }

}

- (void)optionButtonClick:(id)sender
{
    NSLog(@"click");
    isShow = !isShow;
    UIButton *buttonSender = (UIButton *)sender;
    
    UIView *imgView = [self.view viewWithTag:IMGVIEW_TAG];
    
    if (isShow) {
        [imgView addSubview:optionView];
        [self.view bringSubviewToFront:optionView];
        [buttonSender setTitle:@"Done" forState:UIControlStateNormal];
    } else {
        
        SHCamera *camera = [SHCamera sharedInstance];
        [camera setExposureTime:optionView.exposureTime];
        [camera setSensitivity:optionView.sensitvity];
        [camera setEv:optionView.EV];
        
        // Remove the option
        [optionView removeFromSuperview];
        [buttonSender setTitle:@"Option" forState:UIControlStateNormal];
    }
}

@end
