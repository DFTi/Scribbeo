//
//  CoreMedia_Timecodes.m
//  Scribbeo2
//
//  Created by Zachry Thayer on 12/15/11.
//  Copyright (c) 2011 Zachry Thayer. All rights reserved.
//


#include "CoreMedia_Timecodes.h"

BOOL floatEquals(float a, float b, float tolerance);

#pragma mark - Constants

const CMTimecode CMTimcodeZero = {0,0,0,0,-1.f,0.f};

#pragma mark - CMTimecode

CMTimecode CMTimecodeFromCMTime(CMTime time, float framerate)
{
    
    if (framerate <= 0.f)
    {
        return CMTimcodeZero;
    }
    
    #ifdef DEBUG
    NSLog(@"CMTimecodeFromCMTime time: framerate:%f ", framerate);
    #endif
    
    // Get input in seconds
    Float64 seconds = CMTimeGetSeconds(time);
    Float64 realSeconds = seconds;
    
    //Round up
    framerate = ceilf(framerate);
    
    //Calculate minutes    
    NSInteger minutes = (NSInteger)floor(seconds / 60.) % 60;  
    //Calculate hours  
    NSInteger hours = (NSInteger)floor(seconds / 60.) - minutes;
    
    //Remove the number of seconds used for minutes and hours
    seconds -= (minutes * 60.) + (hours * 3600.);
    //Remove floating point trail 
    seconds = floor(seconds);
    
    Float64 totalFrames = realSeconds * framerate;
    //Every 1000th frame is dropped, this is the inverse ratio
    Float64 droppedFrameMagic = 1. - 1000./1001.;
    //Calculate the number of frames that have been dropped
    Float64 totalDroppedFrames = (totalFrames*droppedFrameMagic);
    
    //Remove the number of dropped frames in minutes and hours
    while (totalDroppedFrames >= framerate) {
        totalDroppedFrames -= framerate;//subtract 1 second in frames
        seconds -= 1;// subtract one second
        
        if (seconds < 0) {//if negative seconds remove a minute and increase to highest second before minute
            minutes -= 1;
            seconds = 59;
            
            if (minutes < 0) {//if negative minutes remove a minute and increase to the highest minute before hour
                hours -= 1;
                minutes = 59;
            }
        }
    }
    
    //Calculate in seconds the number of frames
    Float64 frameFloat = realSeconds - floor(realSeconds);
    
    //Calculate the number of frames
    NSInteger frame = frameFloat * framerate;
    
    //If the number of dropped frames is greater than frames this second
    if (totalDroppedFrames >= frame) {
        seconds -= 1;//Remove a second
        if (seconds < 0) {//if negative seconds remove a minute and increase to highest second before minute
            minutes -= 1;
            seconds = 59;
            
            if (minutes < 0) {//if negative minutes remove a minute and increase to the highest minute before hour
                hours -= 1;
                minutes = 59;
            }
        }
        
        //Remove the number of dropped frames from the new second
        frame = framerate - totalDroppedFrames;
        
    }else
    {
        //Remove the number of dropped frames
        frame -= totalDroppedFrames;
        
    }
    
    Float64 recalcedSeconds = (1./framerate*frame)+(seconds)+(60*minutes)+(60*60*hours) + (1./framerate*(totalFrames*droppedFrameMagic));
    
    NSInteger frameDiff = floor((realSeconds - recalcedSeconds)/(1.f/framerate));
    
    frame += frameDiff;
    
    return (CMTimecode){frame, seconds, minutes, hours, framerate, realSeconds};
    
}

CMTimecode CMTimecodeFromCMTimeWithoutDrop(CMTime time, float framerate)
{
    
#ifdef DEBUG
    NSLog(@"CMTimecodeFromCMTimeWithoutDrop time: framerate:%f ", framerate);
#endif
    
    // Get input in seconds
    Float64 seconds = CMTimeGetSeconds(time);
    Float64 realSeconds = seconds;
    
    //Round up
    framerate = ceil(framerate);
    
    //Calculate hours  
    NSInteger hours = seconds / 3600;
    seconds -= hours * 3600;
    
    //Calculate minutes    
    NSInteger minutes = seconds / 60;
    seconds -= minutes * 60;
    
    seconds = floor(seconds);
    
    //Calculate in seconds the number of frames
    Float64 frameFloat = realSeconds - floor(realSeconds);
    //Calculate the number of frames
    NSInteger frame = frameFloat * framerate;
    
    return (CMTimecode){frame, seconds, minutes, hours, framerate, realSeconds};
    
}

CMTime CMTimeFromCMTimecode(CMTimecode timecode)
{
    
#ifdef DEBUG
    NSLog(@"CMTimeFromCMTimecode timecode:%@ ", NSStringFromCMTimecode(timecode));
#endif
    
    if (timecode.framerate > 0.f)
    {
        NSInteger framerate = ceilf(timecode.framerate) + 1;
        
        Float64 seconds = (Float64)(timecode.frames) / framerate;
        seconds += timecode.seconds;
        seconds += timecode.minutes * CMTimecodeSecondsInMinute;
        seconds += timecode.hours * CMTimecodeSecondsInHour;
        
        CMTime baseTime = CMTimeMakeWithSeconds(seconds, 1000000000);
        
        Float64 droppedFrameMagic = 1 - 1000./1001.;
        
        NSInteger frameCount = seconds * framerate * droppedFrameMagic;
                
        CMTime timeAdjust = CMTimeMakeWithSeconds( (Float64)frameCount / framerate , 1000000000);
        
        return CMTimeAdd(baseTime, timeAdjust);

    }
    
    return kCMTimeZero;
}

Float64 CMTimecodeGetSeconds(CMTimecode timecode)
{
    
#ifdef DEBUG
    NSLog(@"CMTimecodeGetSeconds timecode:%@ ", NSStringFromCMTimecode(timecode));
#endif
    
    return timecode.realSeconds;
}

#pragma mark - Math

CMTimecode CMTimecodeAdd(CMTimecode addend1, CMTimecode addend2)
{
    
    
#ifdef DEBUG
    NSLog(@"CMTimecodeAdd addend1:%@ +addend2:%@ ", NSStringFromCMTimecode(addend1), NSStringFromCMTimecode(addend2));
#endif
    
    if (floatEquals(addend1.framerate, addend2.framerate, CMTimecodeFramerateCompareTolerance)) {
        
        float framerate = addend1.framerate;//They should be the same TODO: average 2?
        
        if (framerate <= 0.f)
        {
            return CMTimcodeZero;
        }
        
        NSInteger frames = addend1.frames + addend2.frames;
        
        NSInteger seconds = addend1.seconds + addend2.seconds;
        
        while (frames >= framerate){
            seconds += 1;
            frames -= framerate;
        }
        
        NSInteger minutes = addend1.minutes + addend2.minutes;
        
        while (seconds >= CMTimecodeSecondsInMinute){
            minutes += 1;
            seconds -= CMTimecodeSecondsInMinute;
        }
        
        NSInteger hours = addend1.hours + addend2.hours;
        
        while (minutes >= CMTimecodeMinutesInHour){
            hours += 1;
            minutes -= CMTimecodeMinutesInHour;
        }
        
        return (CMTimecode){frames, seconds, minutes, hours, framerate, addend1.realSeconds + addend2.realSeconds};
    }
    else
    {
        return CMTimcodeZero;
    }
}

#pragma mark - Helpers

BOOL floatEquals(float a, float b, float tolerance){
    
    return (fabs(a-b) < fabs(tolerance));
    
}

#pragma mark - NSString

NSString * NSStringFromCMTimecode(CMTimecode timecode)
{
    NSString* timecodeString = [NSString stringWithFormat:@"%02i:%02i:%02i:%02i", timecode.hours, timecode.minutes, timecode.seconds, timecode.frames];
    
    #ifdef DEBUG
    NSLog(@"NSStringFromCMTimecode %@", timecodeString);
    #endif
    
    return timecodeString;
}

CMTimecode CMTimecodeFromNSString(NSString* timecode, float framerate)
{
    
    if (framerate <= 0.f)
    {// LOL!
        framerate = 23.97;
    }
    
#ifdef DEBUG
    NSLog(@"CMTimecodeFromNSString timecode:%@ framerate:%f", timecode, framerate);
#endif
    
    CMTimecode newTimecode = {0,0,0,0,0.f};
    
    NSArray* components = [timecode componentsSeparatedByString:@":"];
    
    if ([components count] == 4) {
        newTimecode.framerate = framerate;
        newTimecode.hours = [[components objectAtIndex:0] intValue];
        newTimecode.minutes = [[components objectAtIndex:1] intValue];
        newTimecode.seconds = [[components objectAtIndex:2] intValue];
        newTimecode.frames = [[components objectAtIndex:3] intValue];
        newTimecode.realSeconds = (newTimecode.hours * 3600) + (newTimecode.minutes * 60) + newTimecode.seconds + (newTimecode.frames / framerate);
        return newTimecode;
    }
    
    return CMTimcodeZero;
}