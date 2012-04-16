//
//  CoreMedia_Timecodes.h
//  Scribbeo2
//
//  Created by Zachry Thayer on 12/15/11.
//  Copyright (c) 2011 Zachry Thayer. All rights reserved.
//

#import <CoreMedia/CoreMedia.h>
#import <Foundation/Foundation.h>

#ifndef __CoreMedia_Timecodes_H
#define __CoreMedia_Timecodes_H

typedef struct
{
    
    NSUInteger frames;
    NSInteger seconds;
    NSInteger minutes;
    NSInteger hours;
    
    float framerate;
    Float64 realSeconds;
    
} CMTimecode;

extern const CMTimecode CMTimcodeZero;

CMTimecode CMTimecodeFromCMTime(CMTime time, float framerate);
CMTimecode CMTimecodeFromCMTimeWithoutDrop(CMTime time, float framerate);

CMTime CMTimeFromCMTimecode(CMTimecode timecode);

Float64 CMTimecodeGetSeconds(CMTimecode timecode);

//CMTimecode Maths

#define CMTimecodeFramerateCompareTolerance 0.1
#define CMTimecodeSecondsInMinute 60
#define CMTimecodeMinutesInHour 60
#define CMTimecodeSecondsInHour (CMTimecodeSecondsInMinute * CMTimecodeMinutesInHour)

CMTimecode CMTimecodeAdd(CMTimecode addend1, CMTimecode addend2);

NSString * NSStringFromCMTimecode(CMTimecode timecode);

CMTimecode CMTimecodeFromNSString(NSString* timecode, float framerate);

#endif