//
//  DrawView.h
//
//  Created by Steve Kochan on 9/10/10.
//  Copyright © 2010-2011 by Digital Film Tree. All rights reserved.
//

//  This class handles the drawing view that is placed on top of the player view
//  It responds to touch events and build an array containing arrays of line segments and
//  another array of corresponding colors

#import <UIKit/UIKit.h>
#import "VideoTreeAppDelegate.h"
#import "AVFoundation/AVFoundation.h"

#define RED  0
#define GREEN 1
#define BLUE 2

@interface DrawView : UIView {
	NSMutableArray *myDrawing;      // array of arrays of line segments
    NSMutableArray *colors;         // array of corresponding line segment colors

    BOOL         twoBarMode;        // not used by the app
    BOOL         wasTwoBarMode;     // ditto
    CGFloat      straightX;         // only used for two bar drawing mode
    NSInteger    color;
    float        scaleWidth, scaleHeight;  // scale factor so drawings work on iPhone and iPad
}

@property NSInteger color;
@property (nonatomic, assign) NSMutableArray *myDrawing;
@property (nonatomic, assign) NSMutableArray *colors;
@property float scaleWidth, scaleHeight;

-(IBAction) twoBars;        // not used
-(void) unDo;               // undo last drawing command
-(void) cancelDrawing;      // erase all drawing commands
-(void) showDebugAlert;     // triple tap shows free memory (for debugging)
@end
