//
//  OptionalView.m
//  SHLongExposureCamera
//
//  Created by shouian on 13/8/24.
//  Copyright (c) 2013年 shouian. All rights reserved.
//

#import "OptionalView.h"

@interface OptionalView ()
{
    CGPoint previousLocation;
    
    UISegmentedControl *speedSeg;
    UISegmentedControl *focusSeg;
    UISegmentedControl *isoSeg;
    
}
@end

@implementation OptionalView

@synthesize exposureTime = _exposureTime;
@synthesize EV           = _EV;
@synthesize sensitvity   = _sensitvity;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.userInteractionEnabled = YES;
        
        //Allocate UILabel
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(self.bounds.origin.x + 5, self.bounds.origin.y, 120.0f, 40.0f)];
        label.text = @"Shutter Speed";
        label.font = [UIFont systemFontOfSize:14.0f];
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor whiteColor];
        [self addSubview:label];
        
        //Allocate Speed
        NSArray *speed = [NSArray arrayWithObjects:@"0.5",@"1",@"2",@"4", @"8", nil];
        self.exposureTime = 0.5f;
        speedSeg = [[UISegmentedControl alloc] initWithItems:speed];
        [speedSeg addTarget:self action:@selector(segmentClick:) forControlEvents:UIControlEventValueChanged];
        [speedSeg setFrame:CGRectMake(self.bounds.origin.x+5,
                                      self.bounds.origin.x + 40,
                                      self.bounds.size.width-10,
                                      25.0f)];
        [self addSubview:speedSeg];
        
        //Allocate F-Stop
        UILabel *focusLabel = [[UILabel alloc] initWithFrame:CGRectMake(speedSeg.frame.origin.x,
                                                                        speedSeg.frame.origin.y + 25,
                                                                        speedSeg.bounds.size.width,
                                                                        speedSeg.bounds.size.height)];
        focusLabel.text = @"EV";
        focusLabel.font = [UIFont systemFontOfSize:14.0f];
        focusLabel.backgroundColor = [UIColor clearColor];
        focusLabel.textColor = [UIColor whiteColor];
        [self addSubview:focusLabel];
        
        NSArray *foucs = [NSArray arrayWithObjects:@"2.0",@"1.0", @"1/2", @"1/5", @"0", nil];
        focusSeg = [[UISegmentedControl alloc] initWithItems:foucs];
        [focusSeg addTarget:self action:@selector(focusClick:) forControlEvents:UIControlEventValueChanged];
        [focusSeg setFrame:CGRectMake(focusLabel.frame.origin.x,
                                      focusLabel.frame.origin.y + 40,
                                      speedSeg.bounds.size.width,
                                      speedSeg.bounds.size.height)];
        [self addSubview:focusSeg];
        
        //Allocate ISO
        UILabel *isoLabel = [[UILabel alloc] initWithFrame:CGRectMake(focusSeg.frame.origin.x,
                                                                      focusSeg.frame.origin.y + 25,
                                                                      focusSeg.bounds.size.width,
                                                                      focusSeg.bounds.size.height)];
        isoLabel.text = @"Sensitivity";
        isoLabel.font = [UIFont systemFontOfSize:14.0f];
        isoLabel.backgroundColor = [UIColor clearColor];
        isoLabel.textColor = [UIColor whiteColor];
        [self addSubview:isoLabel];
        
        NSArray *iso = [NSArray arrayWithObjects:@"1/32",@"1/16",@"1/8",@"1/4",@"1/2",@"1",nil];
        isoSeg = [[UISegmentedControl alloc] initWithItems:iso];
        [isoSeg addTarget:self action:@selector(isoClick:) forControlEvents:UIControlEventValueChanged];
        [isoSeg setFrame:CGRectMake(isoLabel.frame.origin.x,
                                    isoLabel.frame.origin.y + 40,
                                    focusSeg.bounds.size.width,
                                    focusSeg.bounds.size.height)];
        [self addSubview:isoSeg];
        
        //Allocate Gesture
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        self.gestureRecognizers = [NSArray arrayWithObject:pan];
    }
    return self;
}

-(void)removeAllSubviews
{
    NSArray *sub = [self subviews];
    for (UIView *view in sub ) {
        [view removeFromSuperview];
    }
    [self removeFromSuperview];
    return;
}

#pragma mark - Actions
-(void)segmentClick: (id)sender
{
    NSArray *exposureItems = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.5f],
                                                       [NSNumber numberWithFloat:1.0f],
                                                       [NSNumber numberWithFloat:2.0f],
                                                       [NSNumber numberWithFloat:4.0f],
                                                       [NSNumber numberWithFloat:8.0f], nil];
    
    _exposureTime = [[exposureItems objectAtIndex:[sender selectedSegmentIndex]] floatValue];
    
}
-(void)focusClick: (id)sender
{
    NSArray *EVItems = [NSArray arrayWithObjects:[NSNumber numberWithFloat:2.0f],
                                                 [NSNumber numberWithFloat:1.0f],
                                                 [NSNumber numberWithFloat:0.5f],
                                                 [NSNumber numberWithFloat:0.2f],
                                                 [NSNumber numberWithFloat:0.0f], nil];
    
    _EV = [[EVItems objectAtIndex:[sender selectedSegmentIndex]] floatValue];
}

-(void)isoClick: (id) sender
{
    NSArray *sensitvityItems = [NSArray arrayWithObjects:[NSNumber numberWithFloat:powf(0.5f, 5.0f)],
                                                         [NSNumber numberWithFloat:powf(0.5f, 4.0f)],
                                                         [NSNumber numberWithFloat:powf(0.5f, 3.0f)],
                                                         [NSNumber numberWithFloat:powf(0.5f, 2.0f)],
                                                         [NSNumber numberWithFloat:powf(0.5f, 1.0f)],
                                                         [NSNumber numberWithFloat:1.0f], nil];

    _sensitvity = [[sensitvityItems objectAtIndex:[sender selectedSegmentIndex]] floatValue];
}

#pragma mark - Gesture
-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.superview bringSubviewToFront:self];
    previousLocation = self.center;
}

-(void)handlePan:(UIPanGestureRecognizer *)pan
{
    CGPoint translation = [pan translationInView:self.superview];
    CGPoint newCenter = CGPointMake(previousLocation.x + translation.x, previousLocation.y + translation.y);
    // Constrain
    float halfx = CGRectGetMidX(self.bounds);
    newCenter.x = MAX(halfx, newCenter.x);
    newCenter.x = MIN(self.superview.bounds.size.width - halfx, newCenter.x);
    
    float halfy = CGRectGetMidY(self.bounds);
    newCenter.y = MAX(halfy, newCenter.y);
    newCenter.y = MIN(self.superview.bounds.size.height - halfy, newCenter.y);
    
    self.center = newCenter;
}

@end
