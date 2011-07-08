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

-(void)drawPic {	    
    first = YES;
    twoBarMode = NO;
    wasTwoBarMode = YES;
	[self setNeedsDisplay];
}

-(void) setMyDrawing: (NSMutableArray *) theDrawing
{
    if (myDrawing != theDrawing)
        [myDrawing release];
    
    myDrawing = [theDrawing mutableCopy];
}

-(void) setColors: (NSMutableArray *) theColors
{
    if (colors != theColors)
        [colors release];
    
    colors = [theColors mutableCopy];
}


-(id)initWithCoder: (NSCoder *) decoder
{
    [super initWithCoder: decoder];
    color = RED;
    myDrawing = [[NSMutableArray alloc] initWithCapacity:0];
    colors = [[NSMutableArray alloc] initWithCapacity:0];

    return self;
}

-(void) showDebugAlert
{
    // Alert for saving the image or copying it to the pasteboard 
    
    NSString *alertMsg = [NSString stringWithFormat: @"Free Mem = %.2f MB", 
        [(VideoTreeAppDelegate *) [[UIApplication sharedApplication] delegate] freemem] / (1024. * 1024.)];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"" 
            message: alertMsg  delegate:self 
            cancelButtonTitle: @"OK" otherButtonTitles: nil];
    
    [alert show];
    [alert release];
}

- (void)drawRect:(CGRect)rect {   
    if (![myDrawing count])
        return;
        
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    CGContextSetLineWidth(ctx, 4);

    for (int i = 0; i < [myDrawing count]; ++i) {	
        NSArray *thisArray = [myDrawing objectAtIndex: i];
        NSInteger theColor = [[colors objectAtIndex: i] integerValue];
        
        if ([thisArray count] > 2) {
            switch ( theColor) {
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
            
            float thisX = [[thisArray objectAtIndex:0] floatValue] * scaleWidth;
            float thisY = [[thisArray objectAtIndex:1] floatValue] * scaleHeight;

            CGContextBeginPath(ctx);
            CGContextMoveToPoint(ctx, thisX, thisY);
            
            for (int j = 2; j < [thisArray count] ; j+=2) {
                thisX = [[thisArray objectAtIndex:j] floatValue] * scaleWidth;
                thisY = [[thisArray objectAtIndex:j+1] floatValue] * scaleHeight;
                
                CGContextAddLineToPoint(ctx, thisX,thisY);
            }
           
            CGContextStrokePath(ctx);
       }
    }
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    VideoTreeAppDelegate *app = (VideoTreeAppDelegate *) [[UIApplication sharedApplication] delegate];
    AVPlayer *player = [[app viewController] player];

    NSLog (@"touches began in DrawView");
    
    if (!player)
        return;
    
    if ([[app viewController] keyboardShows])  {
        [[[app viewController] newNote] resignFirstResponder];
        return;
    }
    else if (player && [[app viewController] fullScreenMode]) {
        [[app viewController] leaveFullScreen: nil];
        return;
    }
    else if (player && ([player rate] != 0.0 || [[app viewController] theTimer])) {
        [[app viewController] pauseIt];
        return;
    }

    scaleWidth = scaleHeight = 1.0;
	[myDrawing addObject:[[NSMutableArray alloc] initWithCapacity:4]];
    
    if (twoBarMode) 
        [myDrawing addObject:[[NSMutableArray alloc] initWithCapacity:4]];
    
    int numObjs = [myDrawing count];
//	NSLog (@"myDrawing = %i", numObjs);
    
	CGPoint curPoint = [[touches anyObject] locationInView:self];
    
    straightX = curPoint.x;
	[[myDrawing objectAtIndex: numObjs - 1] addObject:[NSNumber numberWithFloat:curPoint.x]];
	[[myDrawing objectAtIndex: numObjs - 1] addObject:[NSNumber numberWithFloat:curPoint.y]];
    
    if (twoBarMode) {
        [[myDrawing objectAtIndex: numObjs - 2] addObject:[NSNumber numberWithFloat:curPoint.x + 8]];
        [[myDrawing objectAtIndex: numObjs - 2] addObject:[NSNumber numberWithFloat:curPoint.y]];
    }
        
    [colors addObject: [NSNumber numberWithInteger: color]];
    
    if (twoBarMode)
        [colors addObject: [NSNumber numberWithInteger: color]];
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    AVPlayer *player = [[(VideoTreeAppDelegate *)[[UIApplication sharedApplication] delegate] viewController] player];
    
    if (player && [player rate]) 
        return;
    
    if (!player)
        return;
    
	CGPoint curPoint = [[touches anyObject] locationInView:self];
    CGFloat theX;
    
    if (twoBarMode)
        theX = straightX;
    else
        theX = curPoint.x;

    
	[[myDrawing lastObject] addObject:[NSNumber numberWithFloat: theX]];
	[[myDrawing lastObject] addObject:[NSNumber numberWithFloat: curPoint.y]];
    
    if (twoBarMode) {
        int numObjs = [myDrawing count];
        
        [[myDrawing objectAtIndex: numObjs - 2] addObject:[NSNumber numberWithFloat: theX + 8]];
        [[myDrawing objectAtIndex: numObjs - 2] addObject:[NSNumber numberWithFloat: curPoint.y]];
    }
    
	[self setNeedsDisplay];
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    VideoTreeAppDelegate *app = (VideoTreeAppDelegate *) [[UIApplication sharedApplication] delegate];
    AVPlayer *player = [[app viewController] player];

    if (player && [player rate] ) 
        return;
    
	CGPoint curPoint = [[touches anyObject] locationInView:self];
    CGFloat  theX;
    
    int taps = [[touches anyObject] tapCount];
    if (taps == 3) {
        [[app viewController] erase];
        [self showDebugAlert];
        
        return;
    }
    else if (taps == 2) {
        [[app viewController] playPauseButtonPressed: nil];
        return;
    }
    
    if (twoBarMode)
        theX = straightX;
    else
        theX = curPoint.x;
    
	[[myDrawing lastObject] addObject:[NSNumber numberWithFloat:theX]];
	[[myDrawing lastObject] addObject:[NSNumber numberWithFloat:curPoint.y]];
    
    if (twoBarMode) {
        int numObjs = [myDrawing count];
        
        [[myDrawing objectAtIndex: numObjs - 2] addObject:[NSNumber numberWithFloat: theX + 8]];
        [[myDrawing objectAtIndex: numObjs - 2] addObject:[NSNumber numberWithFloat:curPoint.y]];
    }
    
	[self setNeedsDisplay];
    
    if (twoBarMode) {
        twoBarMode = NO;
        wasTwoBarMode = YES;
    }
    else
        wasTwoBarMode = NO;
}

-(IBAction) twoBars
{
    twoBarMode = YES;
}

-(void) cancelDrawing {
	[myDrawing removeAllObjects];
    [colors removeAllObjects];
	[self setNeedsDisplay];
}

-(void) unDo
{
    int n = [myDrawing count];
    
    if (n) {
        [myDrawing removeObjectAtIndex: n - 1];
        [colors removeObjectAtIndex: n - 1];
        
        if (wasTwoBarMode) {
            [myDrawing removeObjectAtIndex: n - 2];
            [colors removeObjectAtIndex: n - 2];
        }
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

