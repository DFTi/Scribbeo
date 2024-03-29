//
//  Note.h
//  VideoTree
//
//  Created by Steve Kochan on 9/21/10.
//  Copyright © 2010-2011 by Digital Film Tree. All rights reserved.
//

//
// This class defines the basic format for a Note
//

#import <Foundation/Foundation.h>
#import "myDefs.h"

@interface Note : NSObject <NSCoding> {
    NSData          *thumb;
    NSData          *voiceMemo;
    NSString        *text;
    NSString        *timeStamp;
    float           secs;
    NSString        *date;
    NSString        *initials;
    NSMutableArray  *drawing;
    NSMutableArray  *colors;
    float           frameWidth, frameHeight;  
    NSString        *imageName;   
    int             rotation;
}

@property (nonatomic, retain)  NSData     *thumb;         // the thumbnail of the frame
@property (nonatomic, retain)  NSData     *voiceMemo;     // the audio note data
@property (nonatomic, copy)    NSString    *text;         // the text entered for the note
@property (nonatomic, retain)  NSString    *timeStamp;    // the timecode for the frame
@property (nonatomic, retain)  NSString    *date;         // when the note was made
@property (nonatomic, retain)  NSString    *initials;     // who made the note
@property (nonatomic, retain)  NSString    *imageName;    // populated if this is a still
@property (nonatomic, copy)    NSMutableArray  *drawing;  // an array (of an array) of line segments
@property (nonatomic, copy)    NSMutableArray  *colors;   // an array of colors for each line segment
@property (nonatomic) Float64 framerate;
@property float frameWidth, frameHeight, secs;                  // a scale factor so iPhone/iPad notes work
@property int   rotation;
-(BOOL) isStill;
@end
