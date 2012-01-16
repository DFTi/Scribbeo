//
//  DrawView.m
//
//  Created by  Steve Kochan on 9/10/10.
//  Copyright © 2010-2011 by Digital Film Tree. All rights reserved.
//

#import "DrawView.h"
#import "VideoTreeViewController.h"
#import <QuartzCore/CAAnimation.h>

@implementation DrawView
@synthesize color, colors, myDrawing, scaleWidth, scaleHeight;

// allocate a new drawing array 

-(void) setMyDrawing: (NSMutableArray *) theDrawing
{
    if (myDrawing != theDrawing)
        [myDrawing release];
    
    myDrawing = [theDrawing mutableCopy];
}

// set the corresponding colors array that parallels myDrawing

-(void) setColors: (NSMutableArray *) theColors
{
    if (colors != theColors)
        [colors release];
    
    colors = [theColors mutableCopy];
}

// initialize the instance variables for this class

-(id) initWithFrame: (CGRect) theFrame
{
    if (self = [super initWithFrame: theFrame]) {
        color = RED;
        myDrawing = [[NSMutableArray alloc] initWithCapacity:0];
        colors = [[NSMutableArray alloc] initWithCapacity:0];
    }

    return self;
}

// triple tap displays free memory as an alert

-(void) showDebugAlert
{
    NSString *alertMsg = [NSString stringWithFormat: @"Free Mem = %.2f MB", 
        [(VideoTreeAppDelegate *) [[UIApplication sharedApplication] delegate] freemem] / (1024. * 1024.)];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"" 
            message: alertMsg  delegate:self 
            cancelButtonTitle: @"OK" otherButtonTitles: nil];
    
    [alert show];
    [alert release];
}

// Draws the current line segments in myDrawing according to the colors in the
// colors array into the view

- (void)drawRect:(CGRect)rect {      
    if (![myDrawing count])
        return;
        
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    CGContextSetLineWidth(ctx, 4);
    
    // Each entry in myDrawing is an array of points that represent
    // line segments.   For each array, there's a corresponding color in the 
    // colors array.  Go through each array and draw each line according to that color

    for (int i = 0; i < [myDrawing count]; ++i) {	
        NSArray *thisArray = [myDrawing objectAtIndex: i];
        NSInteger theColor = [[colors objectAtIndex: i] integerValue];
        
        if ([thisArray count] > 2) {
            switch (theColor) {
                case RED:
                    CGContextSetRGBStrokeColor(ctx, (CGFloat) 1, (CGFloat) 0, (CGFloat) 0, (CGFloat) 1.0);
                    break;
                case GREEN:
                    CGContextSetRGBStrokeColor(ctx, (CGFloat) 0, (CGFloat) 1, (CGFloat) 0, (CGFloat) 1.0);
                    break;
                case BLUE:
                    CGContextSetRGBStrokeColor(ctx, (CGFloat) 0, (CGFloat) 0, (CGFloat) 1, (CGFloat) 1.0);
                    break;
            }
            
            // Get the first two points for the start of the line
            
            float thisX = [[thisArray objectAtIndex:0] floatValue] * scaleWidth;
            float thisY = [[thisArray objectAtIndex:1] floatValue] * scaleHeight;

            CGContextBeginPath(ctx);
            CGContextMoveToPoint(ctx, thisX, thisY);
            
            // Now join the line segments together
            
            for (int j = 2; j < [thisArray count] ; j+=2) {
                thisX = [[thisArray objectAtIndex:j] floatValue] * scaleWidth;
                thisY = [[thisArray objectAtIndex:j+1] floatValue] * scaleHeight;
                
                CGContextAddLineToPoint(ctx, thisX,thisY);
            }
            
            // Stroke the line (i.e., paint it)
           
            CGContextStrokePath(ctx);
       }
    }
}

// case 1: Touch while playing clip pauses it
// case 2: Touch while autoplaying a still pauses autoplay
// case 3: Touch while keyboard is showing hides it
// case 4: Touch while in full screen mode exits full screen mode
// Otherwise start a new line segment

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    VideoTreeViewController *vc = [kAppDel viewController];
    AVPlayer *player = [vc player];
    BOOL still = [vc stillShows];

    NSLog (@"touches began in DrawView");
    
    if (!player && !still)
        return;
        
    if ([vc keyboardShows])  {                                      // 3
        [[[kAppDel viewController] newNote] resignFirstResponder];
        return;
    }
    else if ((player || still) && [vc fullScreenMode]) {            // 4
        [vc leaveFullScreen: nil];
        return;
    }
    else if ([vc slideshowTimer]) {                                 // 2
        [vc playPauseButtonPressed: nil];
        return;
    }
    else if (player && ([player rate] != 0.0 || [vc theTimer])) {   // 1
        [vc pauseIt];
        return;
    }

    scaleWidth = scaleHeight = 1.0;
	[myDrawing addObject:[[NSMutableArray alloc] initWithCapacity:4]];
    
#ifdef TWOBAR
    if (twoBarMode) 
        [myDrawing addObject:[[NSMutableArray alloc] initWithCapacity:4]];
#endif
    
    int numObjs = [myDrawing count];
    
	CGPoint curPoint = [[touches anyObject] locationInView:self];
    
    NSLog (@"Touch began at (%g, %g)", curPoint.x, curPoint.y);
    
    // Add the new touch point to the end of the myDrawing array
    
    straightX = curPoint.x;
	[[myDrawing objectAtIndex: numObjs - 1] addObject:[NSNumber numberWithFloat:curPoint.x]];
	[[myDrawing objectAtIndex: numObjs - 1] addObject:[NSNumber numberWithFloat:curPoint.y]];

#ifdef TWOBAR
    if (twoBarMode) {
        [[myDrawing objectAtIndex: numObjs - 2] addObject:[NSNumber numberWithFloat:curPoint.x + 8]];
        [[myDrawing objectAtIndex: numObjs - 2] addObject:[NSNumber numberWithFloat:curPoint.y]];
    }
#endif
    
    // Record the current color for drawing the new line segment
        
    [colors addObject: [NSNumber numberWithInteger: color]];
 
#ifdef TWOBAR
    if (twoBarMode)
        [colors addObject: [NSNumber numberWithInteger: color]];
#endif
}

// Continue drawing line segment as long as we have a current video that's paused

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    AVPlayer *player = [[kAppDel viewController] player];
    BOOL still = [[kAppDel viewController] stillShows];
    
    if ((!player || [player rate]) && !still) 
        return;
        
	CGPoint curPoint = [[touches anyObject] locationInView:self];
    CGFloat theX;
    
    if (twoBarMode)
        theX = straightX;
    else
        theX = curPoint.x;
    
    // Add the current touch point to the end of the current line segment
    
	[[myDrawing lastObject] addObject:[NSNumber numberWithFloat: theX]];
	[[myDrawing lastObject] addObject:[NSNumber numberWithFloat: curPoint.y]];
 
#ifdef TWOBAR
    if (twoBarMode) {
        int numObjs = [myDrawing count];
        
        [[myDrawing objectAtIndex: numObjs - 2] addObject:[NSNumber numberWithFloat: theX + 8]];
        [[myDrawing objectAtIndex: numObjs - 2] addObject:[NSNumber numberWithFloat: curPoint.y]];
    }
#endif
    
    // Draw the line
    
	[self setNeedsDisplay];
}

// Double tap while playback paused resumes playback
// Triple tap shows debug info

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    AVPlayer *player = [[kAppDel viewController] player];
    BOOL still = [[kAppDel viewController] stillShows];

    if ((player && [player rate]) || still ) 
        return;
    
	CGPoint curPoint = [[touches anyObject] locationInView:self];
    CGFloat  theX;
    
    // Here we can check the number of taps
    
    int taps = [[touches anyObject] tapCount];
    
    // Look at the start of the method to interpret the tap count
    
//    if (taps == 3) {
//        [[kAppDel viewController] erase];
//        [self showDebugAlert];
//        
//        return;
//    }
//    else
//    if (taps == 2) {
//        [[kAppDel viewController] playPauseButtonPressed: nil];
//        return;
//    }
    
    if (twoBarMode)
        theX = straightX;
    else
        theX = curPoint.x;
    
	[[myDrawing lastObject] addObject:[NSNumber numberWithFloat: theX]];
	[[myDrawing lastObject] addObject:[NSNumber numberWithFloat: curPoint.y]];
  
#ifdef TWOBAR
    if (twoBarMode) {
        int numObjs = [myDrawing count];
        
        [[myDrawing objectAtIndex: numObjs - 2] addObject:[NSNumber numberWithFloat: theX + 8]];
        [[myDrawing objectAtIndex: numObjs - 2] addObject:[NSNumber numberWithFloat:curPoint.y]];
    }
#endif
    
	[self setNeedsDisplay];
 
#ifdef TWOBAR
    if (twoBarMode) {
        twoBarMode = NO;
        wasTwoBarMode = YES;
    }
    else
        wasTwoBarMode = NO;
#endif
}

// All the twoBar is here for drawing parallel lines down the screen
// This is legacy code for PDF markup

-(IBAction) twoBars
{
    twoBarMode = YES;
}

// Wipe out the current drawing

-(void) cancelDrawing {
	[myDrawing removeAllObjects];
    [colors removeAllObjects];
	[self setNeedsDisplay];
}

// Erase the last line segment

-(void) unDo
{
    int n = [myDrawing count];
    
    if (n) {
        [myDrawing removeObjectAtIndex: n - 1];
        [colors removeObjectAtIndex: n - 1];
    
#ifdef TWOBAR   
        if (wasTwoBarMode) {
            [myDrawing removeObjectAtIndex: n - 2];
            [colors removeObjectAtIndex: n - 2];
        }
#endif
    }
    
    wasTwoBarMode = NO;
    [self setNeedsDisplay];
}

- (void)dealloc {
    [super dealloc];
	[myDrawing release];
    [colors release];
}

@end

