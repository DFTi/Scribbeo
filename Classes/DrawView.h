//
//  DrawView.h
//
//  Created by Steve Kochan on 9/10/10.
//  Copyright © 2010-2011 by Digital Film Tree. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VideoTreeAppDelegate.h"
#import "AVFoundation/AVFoundation.h"

#define RED  0
#define GREEN 1
#define BLUE 2

@interface DrawView : UIView {
	NSMutableArray *myDrawing;
    NSMutableArray *colors;

    BOOL         first;
    BOOL         twoBarMode;
    BOOL         wasTwoBarMode;
    CGFloat      straightX;
    NSInteger    color;
    float        scaleWidth, scaleHeight;
}

@property NSInteger color;
@property (nonatomic, assign) NSMutableArray *myDrawing;
@property (nonatomic, assign) NSMutableArray *colors;
@property float scaleWidth, scaleHeight;


-(void) drawPic;
-(IBAction) twoBars;
-(void) unDo;
-(void) cancelDrawing;
-(void) showDebugAlert;
@end
