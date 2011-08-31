//
//  MyUIWindow.m
//  VideoTree
//
//  Created by Steve Kochan on 6/20/11.
//  Copyright 2011 DFT Software. All rights reserved.
//

#import "MyUIWindow.h"
#import "VideoTreeViewController.h"
#import "MyDefs.h"

@implementation MyUIWindow

@synthesize spotView;

// This method handles the yellow spot that tracks the finger if demo mode
// is turned on.  This is useful for demoing the app with the output displayed
// on a large screen (e.g., through an HDMI port

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    NSLog2 (@"My hit test");
    
    // Only do this stuff if Demo Mode was selected from the Settings menu
    
    if (kdemoView) {
        if (! spotView) {
            UIImage *spot = [UIImage imageNamed:@"spot.png"];
            
            self.spotView = [[UIImageView alloc] initWithImage: spot]; 
            spotView.userInteractionEnabled = NO;
            [self addSubview: spotView];
            spotView.alpha = 0;
        }
        
        spotView.center = point;
        CABasicAnimation *theAnimation;
        
        // We want to animate the appearance/disappearance of the spot
        
        theAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        theAnimation.duration = 0.8;	
        theAnimation.repeatCount = 0;
        theAnimation.autoreverses = NO;	
        
        // Fade out
        
        theAnimation.fromValue = [NSNumber numberWithFloat: .9]; 
        theAnimation.toValue = [NSNumber numberWithFloat: 0];
        
        [spotView.layer addAnimation:theAnimation forKey:@"animateOpacity"];  
    }
    
    // Do whatever we normally do when the screen was touched
    
    return [super hitTest:point withEvent:event];
}
@end
