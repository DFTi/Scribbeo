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


- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    NSLog2 (@"My hit test");
    
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
        
        theAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        theAnimation.duration = 0.8;	
        theAnimation.repeatCount = 0;
        theAnimation.autoreverses = NO;	
        theAnimation.fromValue = [NSNumber numberWithFloat: .9]; 
        theAnimation.toValue = [NSNumber numberWithFloat: 0];
        
        [spotView.layer addAnimation:theAnimation forKey:@"animateOpacity"];  
    }
    
    return [super hitTest:point withEvent:event];
}
@end
