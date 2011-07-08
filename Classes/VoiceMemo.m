//
//  VoiceMemo.m
//  VideoTree
//
//  Created by Steve Kochan on 1/31/11.
//  Copyright © 2010-2011 by Digital Film Tree. All rights reserved.//

#import "VoiceMemo.h"
#import "VideoTreeAlert.h"

@implementation VoiceMemo
@synthesize audioRecorder;

-(NSURL *) memoURL 
{
    NSArray *dirList = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *docDir = [dirList objectAtIndex: 0];
    
    return [NSURL fileURLWithPath: [docDir stringByAppendingPathComponent: @"memo.caf"]];
}

-(IBAction) startRecording
{
    NSLog(@"startRecording");
    [audioRecorder release];
    audioRecorder = nil;
    recordEncoding = ENC_AAC;
        
    // Init audio with record capability
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryRecord error:nil];
    [audioSession setActive: YES error: NULL];
    
    if (!recordSettings)
        recordSettings = [[NSMutableDictionary alloc] initWithCapacity:10];
    
    if(recordEncoding == ENC_AAC)
    {
        [recordSettings setObject:[NSNumber numberWithInt: kAudioFormatAppleIMA4 ] forKey: AVFormatIDKey];  // kAudioFormatLinearPCM
        [recordSettings setObject:[NSNumber numberWithFloat: 16000.0] forKey: AVSampleRateKey];  // 44100
        [recordSettings setObject:[NSNumber numberWithInt:1] forKey:AVNumberOfChannelsKey];
        [recordSettings setObject:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
        [recordSettings setObject:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsBigEndianKey];
        [recordSettings setObject:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsFloatKey];   
    }
    else
    {
        NSNumber *formatObject;
        
        switch (recordEncoding) {
            case (ENC_AAC): 
                formatObject = [NSNumber numberWithInt: kAudioFormatMPEG4AAC];
                break;
            case (ENC_ALAC):
                formatObject = [NSNumber numberWithInt: kAudioFormatAppleLossless];
                break;
            case (ENC_IMA4):
                formatObject = [NSNumber numberWithInt: kAudioFormatAppleIMA4];
                break;
            case (ENC_ILBC):
                formatObject = [NSNumber numberWithInt: kAudioFormatiLBC];
                break;
            case (ENC_ULAW):
                formatObject = [NSNumber numberWithInt: kAudioFormatULaw];
                break;
            default:
                formatObject = [NSNumber numberWithInt: kAudioFormatAppleIMA4];
        }
        
        [recordSettings setObject:formatObject forKey: AVFormatIDKey];
        [recordSettings setObject:[NSNumber numberWithFloat: 16000.0] forKey: AVSampleRateKey];   // 44100.0
        [recordSettings setObject:[NSNumber numberWithInt: 1] forKey:AVNumberOfChannelsKey];
        [recordSettings setObject:[NSNumber numberWithInt:12800] forKey:AVEncoderBitRateKey];
        [recordSettings setObject:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
        [recordSettings setObject:[NSNumber numberWithInt: AVAudioQualityMedium] forKey: AVEncoderAudioQualityKey];
    }
    
    NSError *error = nil;
    audioRecorder = [[AVAudioRecorder alloc] initWithURL: [self memoURL] settings: recordSettings error:&error];
    
    if (!audioRecorder) {
        [UIAlertView doAlert: @"" 
                     withMsg: @"Can't save the recording!"];
        return;
    }
    
    if ([audioRecorder prepareToRecord] == YES) {
        [audioRecorder record];
    } else {
        int errorCode = CFSwapInt32HostToBig ([error code]); 
        NSLog(@"Error: %@ [%4.4s])" , [error localizedDescription], (char*)&errorCode); 
        
    }
    NSLog(@"recording");
}

-(IBAction) stopRecording
{
    NSLog(@"stopRecording");
    [audioRecorder stop];
    NSLog(@"stopped");
}

-(IBAction) playRecording
{
    NSLog(@"playRecording");
    // Init audio with playback capability
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    [audioSession setActive: YES error: NULL];
    
    NSError *error;
    
    audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL: [self memoURL] error:&error];
    
    NSLog (@"audio playback time = %lf", audioPlayer.duration);
    if (error) {
        int errorCode = CFSwapInt32HostToBig ([error code]); 
        NSLog(@"Playback error: %@ [%4.4s])" , [error localizedDescription], (char*)&errorCode); 
    }
    
    [audioPlayer play];
    NSLog(@"playing");
}

-(IBAction) stopPlaying
{
    NSLog(@"stopPlaying");
    [audioPlayer stop];
    NSLog(@"stopped");
}

- (void)dealloc
{
    [audioPlayer release];
    [audioRecorder release];
    [recordSettings release];
    recordSettings = nil;
    [super dealloc];
}

@end
