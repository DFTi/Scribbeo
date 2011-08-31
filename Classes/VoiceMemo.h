//
//  VoiceMemo.h
//  VideoTree
//
//  Created by Steve Kochan on 1/31/11.
//  Copyright © 2010-2011 by Digital Film Tree. All rights reserved.

//
// This class handles the recording of an audio note
// The audio note is stored in a Note object and archived as an NSData object
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface VoiceMemo : NSObject {
    AVAudioPlayer    *audioPlayer;
    AVAudioRecorder  *audioRecorder;
    int recordEncoding;
    enum
    {
        ENC_AAC = 1,
        ENC_ALAC = 2,
        ENC_IMA4 = 3,
        ENC_ILBC = 4,
        ENC_ULAW = 5,
        ENC_PCM = 6,
    } encodingTypes;
    
    NSMutableDictionary *recordSettings;
}

@property (nonatomic, retain)   AVAudioRecorder  *audioRecorder;

-(IBAction) startRecording;
-(IBAction) stopRecording;
-(IBAction) playRecording;
-(IBAction) stopPlaying;
-(NSURL *) memoURL;

@end
