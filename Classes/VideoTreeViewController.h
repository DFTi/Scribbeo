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
#import "UIImageView+Scaling.h"
#import "FileCell.h"
#import "IASKAppSettingsViewController.h"
#import "SVHTTPRequest.h"

void CGContextShowMultilineText (CGContextRef pdfContext, const char *noteText, int currentY);

// What type of file are we downloading?

enum downloadType { kNotes, kTimecode, kAvidTXT };


@interface VideoTreeViewController : UIViewController <UITableViewDelegate, UITableViewDataSource,
            UITextFieldDelegate, MFMailComposeViewControllerDelegate, 
            UIWebViewDelegate, UIPrintInteractionControllerDelegate, IASKSettingsDelegate, UITextViewDelegate>  {            
    NSMutableArray              *noteData;                  // The table of notes
    NSMutableArray *activeAsyncRequests; // Store requests here so we can cancel them.

    UITextView                  *newNote;                   // The area where the text of a note is displayed
    UITableView                 *notes;                     // The table of notes
    UIImage                     *newThumb;                  // a new thumbnail
    
    UIView                      *playerLayerView;           // The view for video playback
	AVPlayer                    *player;                    // Ahh, the actual player object
    AVPlayerLayer               *playerLayer;               // The layer and the item related to playback
    AVPlayerItem                *playerItem;
    AVURLAsset                  *theAsset;                  // The asset related to the above
    DrawView                    *drawView;                  // Here's where the markups are made
    UISlider                    *movieTimeControl;          // The scrubber
    UIImage                     *pauseImage, *playImage, *recImage, *isRecordingImage;
                                                            // Various images placed on the buttons
    UIImageView                 *notePaper;                 // The lined notepaper

    id                          playerTimeObserver;         // timer for frame forward/reverse
    NSURL                       *movieURL;                  // As its name implies
    NSString                    *mediaPath;                 // For loading stills from notes

    UILabel                     *stampLabel, *stampLabelFull;   // The labels for the watermark (one for full screen)
    UILabel                     *theTime;                   // The current time
    UILabel                     *minLabel;                  // start and end of the video
    UILabel                     *maxLabel;              
    UIBarButtonItem             *playOutButton;             // button for playout to AirPlay
    UILabel                     *volLabel;
    UILabel                     *backgroundLabel;
    float                       fps;                        // fps set from the video
    dispatch_queue_t            mQueue;                     // queue for running code with GCD
                
                                // various buttons on the toolbar; some we hide/disable as necessary
    
    UIBarButtonItem             *pausePlayButton, *rewindToStartButton, *frameBackButton,
                                *frameForwardButton, *forwardToEndButton, *fullScreenButton,
                                *rewindButton, *fastForwardButton, *skipBackButton, *skipForwardButton;
    UIBarButtonItem             *editButton;
                
    UIButton                    *recordButton;
    UIPopoverController         *popoverController;         // popover used for camera roll selection

    UIToolbar                   *noteBar;
    UIToolbar                   *drawingBar;
    UIToolbar                   *playerToolbar;             // The toolbar that holds all the playback buttons

                                                            // Most of these for the DVD Remote
    NSString                    *show, *episode, *filmDate, *tape, *clip,  *clipPath, *currentlyPlaying;
    BOOL                        isediting;
                
    NSString                    *initials, *curInitials;    // used for watermarking and notes
                
    CGRect                      saveFrame, saveFrame2;      // temp holding places
    CGContextRef                pdfContext;                 // For generating the notes in PDF format
    CGRect                      pageRect;
    CGFloat                     currentY;                   // for PDF location
    int                         pageNumber;                 // For pagination
    int                         noteNumber;
                
    NSTimer                     *theTimer;                  // Timer used for updating controls
    NSTimer                     *slideshowTimer;            // Timer used for autoplay slide shows
    float                       slideshowTime;
                
    BOOL                        goingForward;               // Are we advancing forward or banchward?
    BOOL                        keyboardShows, pendingSave; // Is the keyboard showing?  Are we doing a Save?
    BOOL                        durationSet;                // Did we set the duratiom for the vid yet?
    BOOL                        autoPlay;                   // Sequence through vids or stills
    BOOL                        watermark;                  // Are we imprinting?
    BOOL                        runAllMode;
    BOOL                        FCPXML, AvidExport;
    BOOL                        seekToZeroBeforePlay;       // Start from the beginning?
    BOOL                        maxLabelSet;                // Have we set the max timecode yet?
    BOOL                        isSeeking;                  // Are we currently seeking?
    BOOL                        isSaving;                   // In the process of saving a note?
    BOOL                        fullScreenMode;             // Are we in full screen mode?
    BOOL                        timecodeFormat;             // Show timecodes or frame numbers
    CMTime                      endOfVid;
                    
    //  Audio Note support
                    
    VoiceMemo                   *voiceMemo;
    BOOL                        madeRecording; 
    AVAudioPlayer               *audioPlayer;
    UILabel                     *recording;             // Recording message goes in the textview
                    
    NSMutableArray              *notePaths;             // paths to all the relevant note files
    NSMutableArray              *noteURLs;
    NSMutableArray              *xmlPaths, *txtPaths;   // FCP and Avid import files
    NSMutableArray              *markers;             
    XMLURL                      *XMLURLreader;          // For parsing FCP markers in XML

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
                    
    NSString                    *timeCode;      // start timecode for current clip from json
    Float64                     startTimecode;
    BOOL                        selectedNextClip;
    BOOL                        emailPDF, isPrinting;
    int                         skipValue;
                    
    UIView                      *uploadActivityIndicatorView;  // We show activity when uploading to the networkƒ
    UIActivityIndicatorView     *uploadActivityIndicator;

    UIImage                     *FCPImage;              // FCP image for Notes table
    UIImage                     *FCPChapterImage;       // FCP Chapter marker image
    UIImageView                 *airPlayImageView;      // airPlay image when active
    UIImage                     *AvidImage;             // Avid imavge for Notes table (Locator record)

    enum downloadType           download;               // What type of file are we downloading?

    UIView                      *filenameView;          // The dialog for "Open In..." or selecting for the Camera Roll
    UITextField                 *saveFilename;
                
    // Still support
                
    UIImageView                 *stillView;             // The view to hold the still
    BOOL                        stillShows;
    BOOL                        noteTableSelected;
    int                         rotate;                 // 0 - 3 for 90 degree rotations
    CGRect                      drawViewFrame;
    UIImage                     *stillImage;
    BOOL                        allStills;              // Does the folder contain all stills?
    int                         curFileIndex;        // Current index of file browser
    NSMutableArray *curAssetURLs;   // Current asset URLs for current folder
}

@property (nonatomic, retain)  NSString                     *showName;
@property (nonatomic, retain)  NSURL                        *movieURL;
@property (nonatomic, retain)  NSString                     *mediaPath;
@property (nonatomic, retain)  UIImage                      *FCPImage;
@property (nonatomic, retain)  UIImage                      *AvidImage;

@property (nonatomic, retain)  UIImage                      *FCPChapterImage;

@property (nonatomic, retain)  IBOutlet UIImageView         *airPlayImageView;
@property (nonatomic, retain)  AVPlayer                     *player;
@property (nonatomic, retain)  AVURLAsset                   *theAsset;
@property (nonatomic, retain)  AVPlayerLayer                *playerLayer;
@property (nonatomic, retain)  AVPlayerItem                 *playerItem;
@property (nonatomic, retain)  NSTimer                      *theTimer, *slideshowTimer;
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
@property (nonatomic, retain) NSMutableArray     *noteURLs;
@property (nonatomic, retain) NSMutableArray     *activeAsyncRequests;
@property (nonatomic, retain) NSMutableArray     *xmlPaths, *txtPaths;
@property (nonatomic, retain) NSArray            *markers;
@property (nonatomic, retain) XMLURL             *XMLURLreader;

@property (nonatomic, retain) NSMutableArray      *allClips, *curAssetURLs;
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
@property BOOL stillShows;
@property BOOL noteTableSelected;
@property BOOL allStills;

@property (nonatomic, retain)  UIImageView *stillView;
@property (nonatomic, retain)  UIImage *stillImage;

@property (nonatomic, retain) IBOutlet UITextView *newNote;
@property (nonatomic, retain) IBOutlet UIToolbar *playerToolbar;
@property (nonatomic, retain) IBOutlet UILabel    *theTime;
@property (nonatomic, retain) IBOutlet UISlider *movieTimeControl;
@property (nonatomic, retain) DrawView *drawView;
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
@property (nonatomic, retain) NSString *timeCode;
@property BOOL uploadIndicator;
@property enum downloadType download;

@property Float64 startTimecode;

@property (nonatomic, retain) IBOutlet UIBarButtonItem  *pausePlayButton, *rewindToStartButton, 
                *frameBackButton, *frameForwardButton, *forwardToEndButton, 
                *fullScreenButton, *rewindButton, *fastForwardButton;
@property (nonatomic, retain) IBOutlet MPMoviePlayerController *movieController;

@property int curFileIndex;

- (void) swipedLeft:(UISwipeGestureRecognizer*)gesture;
- (void) swipedRight:(UISwipeGestureRecognizer*)gesture;

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
-(void) getAllHTTPNotes: (int)index;
-(void) storeData;
#ifdef APPSTORE
-(void) drawMarkups: (CGContextRef) ctx;
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


-(BOOL) canEmail; // Checks to see if email account exists
-(void) emailLogfile;
-(IBAction) emailNotes;
-(NSString *) uploadFile: (NSString *) localPath to: (NSString *) remotePath;
-(NSString *) downloadFile: (NSString *) remotePath to: (NSString *) localPath;
-(NSString *) uploadAudio: (Note *) theNote;
-(void) uploadHTML: (NSString *) theHTML file: (NSString *) fileName;
-(IBAction) printNotes;

-(NSString *) exportXML;                // FCP XML out
-(void) getXML: (NSString *) file;      // FCP XML in

-(NSString *) exportAvid;               // Avid export out
-(void) getAvid: (NSString *) file;      // Avid tab file in
-(NSArray *) parseAvidMarkers;

// Still image support

-(void) loadStill: (NSString *) link;
-(UIImage *) scaleImage: (CGImageRef) image  andRotate: (float) angle;
-(void) leaveFullScreenStill;

-(NSURL *) getTheURL: (NSString *) thePath;   // Used by loadMovie: and loadStill:

-(void) directlySetStartTimecode: (NSString *) timeCodeStr;
- (IBAction)clearNewNote:(id)sender;

@property (nonatomic, retain) IASKAppSettingsViewController *appSettingsViewController;


@end

