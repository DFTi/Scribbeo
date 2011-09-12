//
//  Note.m
//  VideoTree
//
//  Created by Steve Kochan on 9/21/10.
//  Copyright © 2010-2011 by Digital Film Tree. All rights reserved.//

#import "Note.h"

@implementation Note
@synthesize thumb, text, timeStamp, drawing, colors, date, initials, voiceMemo, frameWidth, frameHeight, imageName, rotation;

// The method used to archive a note

-(void) encodeWithCoder: (NSCoder *) encoder {
    [encoder encodeObject: thumb forKey:@"NoteThumb"];
    [encoder encodeObject: voiceMemo forKey:@"NotevoiceMemo"];
    [encoder encodeObject: text forKey: @"NoteText"]; 
    [encoder encodeObject: timeStamp forKey: @"NoteTimeStamp"];
    [encoder encodeObject: date forKey: @"NoteDate"];
    [encoder encodeObject: drawing forKey: @"NoteDrawing"];
    [encoder encodeObject: colors forKey: @"NoteColors"];
    [encoder  encodeObject: initials forKey: @"NoteInitials"];
    [encoder  encodeFloat: frameWidth forKey: @"NoteFrameWidth"];
    [encoder  encodeFloat: frameHeight forKey: @"NoteFrameHeight"];
    [encoder  encodeObject: imageName forKey: @"NoteImageName"];
    [encoder  encodeInt: rotation forKey: @"NoteRotation"];
}

// The method used to unarchive a note

-(id) initWithCoder: (NSCoder *) decoder
{
    thumb = [[decoder decodeObjectForKey: @"NoteThumb"] retain];
    voiceMemo = [[decoder decodeObjectForKey: @"NotevoiceMemo"] retain];
    text = [[decoder decodeObjectForKey: @"NoteText"] retain]; 
    timeStamp = [[decoder decodeObjectForKey: @"NoteTimeStamp"] retain]; 
    date = [[decoder decodeObjectForKey: @"NoteDate"] retain]; 
    initials = [[decoder decodeObjectForKey: @"NoteInitials"] retain]; 
    drawing = [[decoder decodeObjectForKey: @"NoteDrawing"] mutableCopy]; 
    colors = [[decoder decodeObjectForKey: @"NoteColors"] mutableCopy]; 
    frameWidth =  [decoder decodeFloatForKey: @"NoteFrameWidth"]; 
    frameHeight =  [decoder decodeFloatForKey: @"NoteFrameHeight"]; 
    imageName = [[decoder  decodeObjectForKey: @"NoteImageName"] retain];
    rotation = [decoder  decodeIntForKey: @"NoteRotation"];
 
    NSLog2 (@"Restored one note, timeStamp = %@", timeStamp);
    return self;
}

-(void) dealloc
{
    [thumb release];
    [voiceMemo release];
    [text release];
    [timeStamp release];
    [drawing release];
    [colors release];
    [date release];
    [initials release];
    [imageName release];
    
    [super dealloc];
}

@end
