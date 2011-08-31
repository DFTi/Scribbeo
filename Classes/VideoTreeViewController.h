//
//  VideoTreeViewController.h
//  VideoTree
//
//  Created by Steve Kochan on 9/10/10.
//  Copyright © 2010-2011 by Digital Film Tree. All rights reserved.
//
// This class controls the overall operation of VideoTree.  It responds to 
// all buttons pressed on the toolbars, with the exception of drawing on
// the video overlay (handled by the DrawView class) or selection of a 
// video clip, which is managed by the DetailViewController class
//

@class Note;

#import <UIKit/UIKit.h>
#import "MyPlayerLayerView.h"
#import "VideoTreeAppDelegate.h"
#import "DrawView.h"
#import <AVFoundation/AVFoundation.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import <ctype.h>
#import <MediaPlayer/MPVolumeView.h>
#import <MediaPlayer/MPMoviePlayerController.h>
#import "myDefs.h"
#import "VoiceMemo.h"
#import "XMLURL.h"
#import "HelpScreenController.h"

void CGContextShowMultilineText (CGContextRef pdfContext, const char *noteText, int currentY);

// What type of file are we downloading?

enum downloadType { kNotes, kTimecode, kAvidTXT };

@interface VideoTreeViewController : UIViewController <UITableViewDelegate, UITableViewDataSource,
            UITextFieldDelegate, MFMailComposeViewControllerDelegate, UIPrintInteractionControllerDelegate>  {
    NSMutableArray              *noteData;
    UITextView                  *newNote;
    UIToolbar                   *playerToolbar;
    UILabel                     *theTime;
    UILabel                     *stampLabel, *stampLabelFull;
    UITableView                 *notes;
    UIImage                     *newThumb;
    
    UIView                      *playerLayerView;
    BOOL                        seekToZeroBeforePlay;
    BOOL                        maxLabelSet;
    BOOL                        isSeeking;
    BOOL                        isSaving;
    BOOL                        fullScreenMode;
	AVPlayer                    *player;
    AVPlayerLayer               *playerLayer;
    AVPlayerItem                *playerItem;
    AVURLAsset                  *theAsset;
    DrawView                    *drawView;
    UISlider                    *movieTimeControl;
    UIImage                     *pauseImage, *playImage, *recImage, *isRecordingImage;
    UIImageView                 *notePaper;

    id                          playerTimeObserver;
    NSURL                       *movieURL;

    UILabel                     *maxLabel;
    UIBarButtonItem             *playOutButton;
    UILabel                     *minLabel;
    UILabel                     *volLabel;
    UILabel                     *backgroundLabel;
    float                       fps;
    dispatch_queue_t            mQueue;
    
    UIBarButtonItem             *pausePlayButton, *rewindToStartButton, *frameBackButton,
                                *frameForwardButton, *forwardToEndButton, *fullScreenButton,
                                *rewindButton, *fastForwardButton, *skipBackButton, *skipForwardButton;
    UIBarButtonItem             *editButton;
    UIButton                    *recordButton;
    UIPopoverController         *popoverController;

    UIToolbar                   *noteBar;
    UIToolbar                   *drawingBar;

    NSString                    *show, *episode, *filmDate, *tape, *clip,  *clipPath, *currentlyPlaying;
    BOOL                        isediting;
    NSString                    *initials, *curInitials;
    CGRect                      saveFrame, saveFrame2;
    CGContextRef                pdfContext;
    CGRect                      pageRect;
    CGFloat                     currentY;   // for PDF location
    int                         pageNumber;
    int                         noteNumber;
    NSTimer                     *theTimer;
    BOOL                        goingForward;
    BOOL                        keyboardShows, pendingSave;
    BOOL                        durationSet;
    BOOL                        autoPlay;
    BOOL                        watermark;
    BOOL                        runAllMode;
    BOOL                        FCPXML, AvidExport;
    CMTime                      endOfVid;
                    
//  Audio Note support
                    
    VoiceMemo                   *voiceMemo;
    BOOL                        madeRecording; 
    AVAudioPlayer               *audioPlayer;
    UILabel                     *recording;
                    
    NSMutableArray              *notePaths;
    NSMutableArray              *xmlPaths, *txtPaths;   // FCP and Avid import files
    NSMutableArray              *markers;
    XMLURL                      *XMLURLreader;

    NSMutableArray              *allClips;
    int                         clipNumber;
                    
//   Show progress for clip loading
                    
    UIView                      *progressView;
    UIActivityIndicatorView     *activityIndicator;
                    
//   Show progress for note loading
                    
    UIView                      *noteProgressView;
    UIActivityIndicatorView     *noteActivityIndicator;
                    
    MPVolumeView                *myVolumeView;
    UIView                      *remote;
    UIView                      *mySquareView;
    int                         noteFileProcessed;
    MPMoviePlayerController     *movieController;       // for AirPlay
    BOOL                        FTPMode;
                    
    Float64                     startTimecode;
    BOOL                        selectedNextClip;
    BOOL                        emailPDF, isPrinting;
    int                         skipValue;
    BOOL                        timecodeFormat;
                    
    UIView                      *uploadActivityIndicatorView;
    UIActivityIndicatorView     *uploadActivityIndicator;

    UIImage                     *FCPImage;
    UIImage                     *FCPChapterImage;
    UIImageView                 *airPlayImageView;
    UIImage                     *AvidImage;

    enum downloadType           download;

    UIView                      *filenameView;
    UITextField                 *saveFilename;
}

@property (nonatomic, retain)  NSString                     *showName;
@property (nonatomic, retain)  NSURL                        *movieURL;
@property (nonatomic, retain)  UIImage                      *FCPImage;
@property (nonatomic, retain)  UIImage                      *AvidImage;

@property (nonatomic, retain)  UIImage                      *FCPChapterImage;

@property (nonatomic, retain)  IBOutlet UIImageView         *airPlayImageView;
@property (nonatomic, retain)  AVPlayer                     *player;
@property (nonatomic, retain)  AVURLAsset                   *theAsset;
@property (nonatomic, retain)  AVPlayerLayer                *playerLayer;
@property (nonatomic, retain)  AVPlayerItem                 *playerItem;
@property (nonatomic, retain)  NSTimer                      *theTimer;
@property (nonatomic, retain)  UIView                       *progressView;
@property (nonatomic, retain)  UIActivityIndicatorView      *activityIndicator;
@property (nonatomic, retain)  UIView                       *noteProgressView;
@property (nonatomic, retain)  UIActivityIndicatorView      *noteActivityIndicator;
@property (nonatomic, retain)  IBOutlet UIView              *uploadActivityIndicatorView;
@property (nonatomic, retain)  UIActivityIndicatorView      *uploadActivityIndicator;
@property (nonatomic, retain)  IBOutlet UIImageView         *notePaper;
@property (nonatomic, retain)  IBOutlet UIView              *filenameView;
@property (nonatomic, retain)  IBOutlet UITextField         *saveFilename;

@property  int    uploadCount;

@property (nonatomic, retain) NSMutableArray     *notePaths;
@property (nonatomic, retain) NSMutableArray     *xmlPaths, *txtPaths;
@property (nonatomic, retain) NSArray            *markers;
@property (nonatomic, retain) XMLURL             *XMLURLreader;

@property (nonatomic, retain) NSMutableArray      *allClips;
@property (nonatomic)        int                clipNumber, skipValue;

@property (nonatomic, retain) NSString           *initials;
@property (nonatomic, retain) NSString           *curInitials;

@property BOOL seekToZeroBeforePlay;
@property BOOL isSaving;
@property BOOL fullScreenMode;
@property BOOL autoPlay;
@property BOOL watermark;
@property BOOL airPlayMode;
@property BOOL runAllMode;
@property BOOL madeRecording;
@property BOOL isPrinting;
@property BOOL keyboardShows;

@property (nonatomic, retain) IBOutlet UITextView *newNote;
@property (nonatomic, retain) IBOutlet UIToolbar *playerToolbar;
@property (nonatomic, retain) IBOutlet UILabel    *theTime;
@property (nonatomic, retain) IBOutlet UISlider *movieTimeControl;
@property (nonatomic, retain) IBOutlet DrawView *drawView;
@property (nonatomic, retain) IBOutlet UIView   *playerLayerView;
@property (nonatomic, retain) IBOutlet UIView   *remote;
@property (nonatomic, retain) IBOutlet UILabel   *minLabel;
@property (nonatomic, retain) IBOutlet UILabel   *maxLabel;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *playOutButton;
@property (nonatomic, retain) IBOutlet UILabel   *volLabel;
@property (nonatomic, retain) IBOutlet UIBarButtonItem   *editButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *skipForwardButton, *skipBackButton;
@property (nonatomic, retain) IBOutlet UIToolbar     *noteBar;
@property (nonatomic, retain) IBOutlet UIToolbar     *drawingBar;
@property (nonatomic, retain) IBOutlet UIButton            *recordButton;
@property (nonatomic, retain) IBOutlet UILabel            *recording;
@property (nonatomic, retain) UILabel  *backgroundLabel;


@property (nonatomic, retain) IBOutlet UILabel   *episodeLabel, *dateLabel, *tapeLabel, *clipLabel;


@property (nonatomic, retain)  UIImage  *pauseImage, *playImage, *recImage, *isRecordingImage;
@property (nonatomic, retain)  UITableView *notes;
@property (nonatomic, retain)  UIImage *newThumb;
@property (nonatomic, retain)  NSMutableArray *noteData;
@property (nonatomic, retain)   NSString        *show;
@property (nonatomic, retain)   NSString        *filmDate;
@property (nonatomic, retain)   NSString        *tape;
@property (nonatomic, retain)   NSString        *clip, *clipPath;
@property (nonatomic, retain)   NSString        *episode;
@property (nonatomic, retain)   NSString        *currentlyPlaying;
@property (nonatomic, retain)   IBOutlet  UILabel *stampLabel;
@property (nonatomic, retain) UILabel *stampLabelFull;
@property (nonatomic, retain) VoiceMemo *voiceMemo;

@property BOOL uploadIndicator;
@property enum downloadType download;

@property Float64 startTimecode;

@property (nonatomic, retain) IBOutlet UIBarButtonItem  *pausePlayButton, *rewindToStartButton, 
                *frameBackButton, *frameForwardButton, *forwardToEndButton, 
                *fullScreenButton, *rewindButton, *fastForwardButton;
@property (nonatomic, retain) IBOutlet MPMoviePlayerController *movieController;

// Markup

-(IBAction) erase;
-(IBAction) unDo;
-(IBAction) editNotesTable: (UIBarButtonItem *) button;
-(IBAction) color: (UISegmentedControl *) colorControl;
-(void) red;
-(void) green;
-(void) blue;

// User interaction

-(IBAction) fastForward;
-(IBAction) forwardFrame;
-(IBAction) forwardToEnd;
-(IBAction) rewind;
-(IBAction) backFrame;
-(IBAction) rewindToStart;
-(IBAction) playPauseButtonPressed: (id)sender;
-(IBAction) fullScreen;
-(IBAction) recordNote;
-(IBAction) skipBack;
-(IBAction) skipForward;
-(IBAction) showNav;
-(IBAction) showHelp;

// airPlay support
-(IBAction) airPlay;
-(BOOL) nextClip;
-(void) airPlayWork;

-(void) loadMovie: (id) theMovie;
-(NSString *) archiveFilePath;

// Utility methods

-(void) makeSettings;
-(Float64) convertTimeToSecs: (NSString *) timeStamp;
-(void) updateTimeLabel;
-(NSString *) formatDate: (BOOL) includeTime;
-(void) timeStats;
-(NSString *) timeFormat: (CMTime) theTime;
-(void) cleanup;

-(void) updateTimeControl;
-(void) startObservingTimeChanges;
-(void) stopObservingTimeChanges;
-(void) leaveFullScreen: (NSNotification *) aNotification;
-(void) changeState: (NSNotification *) aNotification;
-(void) pauseIt;
-(void) singleFrame;
-(void) showActivity;
-(void) stopActivity;
-(void) noteShowActivity;
-(void) noteStopActivity;
-(void) uploadActivityIndicator: (BOOL) startOrStop;
-(void) movieControllerDetach;
-(Float64) getStartTimecode;

// Data storage and loading

-(void) loadData: (NSString *) theInitials;
-(void) storeData;
#ifdef APPSTORE
-(void) drawMarkups: (CGContextRef) ctx width: (float) wid height: (float) ht;
#endif
-(void) animateSave;
-(IBAction) save;
-(void) keyboardDidShow: (id) notUsed;
-(void) keyboardDidHide: (id) notUsed;
-(void) clearAnyNotes;

// Functions and methods to create the PDF file and then email

-(void) createPDFFile: (NSString *) filePath title: (NSString *) pageTitle; 
-(void) noteToPDF: (Note *) aNote;
-(void) closePDFFile;
-(void) newPDFPage: (NSString *) title;
-(void) saveToPDF;

// Create HTML email

-(NSMutableString *) saveToHTML;
-(NSString *) noteToHTML: (Note *) theNote;

-(IBAction) emailNotes;
-(NSString *) uploadAudio: (Note *) theNote;
-(void) uploadHTML: (NSString *) theHTML file: (NSString *) fileName;
-(IBAction) printNotes;

-(NSString *) exportXML;                // FCP XML out
-(void) getXML: (NSString *) file;      // FCP XML in

-(NSString *) exportAvid;               // Avid export out
-(void) getAvid: (NSString *) file;      // Avid tab file in
-(NSArray *) parseAvidMarkers;


@end

