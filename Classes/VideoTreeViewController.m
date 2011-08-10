//
//  VideoTreeViewController.m
//  VideoTree
//
//  Created by Steve Kochan on 9/10/10.
//  Copyright © 2010-2011 by Digital Film Tree. All rights reserved.
//


#import "VideoTreeViewController.h"
#import "VideoTreeAppDelegate.h"
#import "DetailViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "Note.h"
#import "FullScreen.h"
#import "FTPHelper.h"
#import <Endian.h>
#import "VoiceMemo.h"


#define MYGRAY [UIColor colorWithRed: .8 green: .8 blue: .9 alpha: 1]
#define MYWHITE [UIColor colorWithRed: .9 green: .9 blue: .9 alpha: 1]

#define kCMTimeMakeWithSeconds(secs)  CMTimeMakeWithSeconds(secs, NSEC_PER_SEC)
#define kCVTime(t)   (CMTimeGetSeconds(t) / ((int) (fps + .5) / (long double) fps))

static void *VideoTreeViewControllerCommonMetadataObserverContext = @"VideoTreeViewControllerCommonMetadataObserverContext";
static void *VideoTreeViewControllerTimedMetadataObserverContext = @"VideoTreeViewControllerTimedMetadataObserverContext";
static void *VideoTreeViewControllerRateObservationContext = @"VideoTreeViewControllerRateObservationContext";
static void *VideoTreeViewControllerDurationObservationContext = @"VideoTreeViewControllerDurationObservationContext";
static void *VideoTreeViewControllerStatusObservationContext = @"VideoTreeViewControllerStatusObservationContext";
static void *VideoTreeViewControllerAirPlayObservationContext = @"VideoTreeViewControllerAirPlayObservationContext";

@implementation VideoTreeViewController
@synthesize airPlayImageView;
@synthesize playerToolbar;
@synthesize playOutButton;

@synthesize showName, newNote, fullScreenMode, drawView, movieTimeControl, notes, newThumb, noteBar, drawingBar;
@synthesize player, seekToZeroBeforePlay, movieURL, playerLayerView, theTime, maxLabel, minLabel, noteData, currentlyPlaying, isSaving, markers;
@synthesize pausePlayButton, pauseImage, playImage, recImage, isRecordingImage, clip, clipPath, show, tape, filmDate, playerLayer, editButton, initials, episode, playerItem, theTimer;
@synthesize progressView, activityIndicator, notePaths, xmlPaths, txtPaths, noteProgressView, noteActivityIndicator, volLabel, curInitials, movieController;
@synthesize fullScreenProgressView, fullScreenActivityIndicator, stampLabel, stampLabelFull, theAsset, startTimecode, download, clipLabel, runAllMode;
@synthesize rewindToStartButton, frameBackButton, frameForwardButton, forwardToEndButton, fullScreenButton, rewindButton, fastForwardButton, airPlayMode, remote;
@synthesize allClips, clipNumber, autoPlay, watermark, episodeLabel, dateLabel, tapeLabel, voiceMemo;
@synthesize recordButton, recording, skipForwardButton, skipBackButton, isPrinting, notePaper, uploadActivityIndicator, uploadActivityIndicatorView, uploadCount, keyboardShows, madeRecording, backgroundLabel, skipValue, uploadIndicator, FCPImage, AvidImage, FCPChapterImage, XMLURLreader, saveFilename, filenameView;;

#pragma mark -
#pragma mark view loading/unloading

static int reTryCount = 0;   // number of retries for an ftp list: request???

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

- (BOOL)canBecomeFirstResponder {
    NSLog (@"Yes, I can become first responder");
    return YES;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.

- (void) viewDidLoad {
    NSLog (@"view controller view did load");
    
    [super viewDidLoad];
    CGPoint theOrigin = {0, 0};
    CGSize theSize;
    CGRect theFrame;
    
    if (iPHONE) {
        newNote.font = [UIFont fontWithName: @"Helvetica" size: 10];
        self.editButton = nil;
        theFrame = drawView.frame;
        theFrame.origin = theOrigin;
        drawView.frame = theFrame;
    }
            
//    mQueue = dispatch_queue_create("AVPlayerCaptureFrame queue", 0);
 
    // Add a volume control for Airplay; Add a Route Button if >= iOS5
 
    if (! iPHONE) {
        CGRect volFrame = { 580, 165, 300, 50 };
        myVolumeView = [[MPVolumeView alloc] initWithFrame: volFrame];
        
        if (! kRunningOS5OrGreater)
            myVolumeView.showsRouteButton = NO;
        
        [self.view addSubview: myVolumeView];
    } 
    
    // remove the playout button from the toolbar if iOS 5 or greater
    
    if (kRunningOS5OrGreater) {
        NSMutableArray    *items = [[playerToolbar.items mutableCopy] autorelease];
        [items removeObject: playOutButton];
        playerToolbar.items = items;
    }
    
    [self uploadActivityIndicator: NO];
    
    newNote.layer.borderWidth = 2;
	newNote.layer.borderColor = [[UIColor grayColor] CGColor];
    
    if (iPHONE)
        newNote.layer.cornerRadius = 8;
    else {
//      newNote.layer.cornerRadius = 12;
    }

    // Add the TableView for the Notes
    
    if (iPHONE) {
        theOrigin =  (CGPoint) {6, 160};
        theSize = (CGSize) {128, 80};   
    }
    else {
        theOrigin =  (CGPoint) {0, 393};
        theSize = (CGSize) {208, 355};
        
        noteBar.clipsToBounds = YES;

        // set corner radious
        noteBar.layer.cornerRadius = 10;
    }
    
    theFrame = (CGRect) {theOrigin, theSize};
        
    notes = [[UITableView alloc] initWithFrame: theFrame];
    notes.delegate = self;
    notes.dataSource = self;
    notes.scrollEnabled = YES;
    
    remote.alpha = 0;

    [self.view addSubview: notes]; 
    [notes release];
    
    [self red];  
    
    int size = (iPHONE) ? 18 : 52;
    
#if RAMYDIDNTLIKETHIS
    backgroundLabel    = [[UILabel alloc] initWithFrame: theTime.frame];
    backgroundLabel.font = [UIFont fontWithName:@"Quartz DB" size: size];
    // backgroundLabel.text = @"00:00:00:00";
    backgroundLabel.text = @"";

    backgroundLabel.alpha = 0.4;
    backgroundLabel.textColor = [UIColor grayColor];
    backgroundLabel.backgroundColor = [UIColor clearColor];
    backgroundLabel.textAlignment = UITextAlignmentRight;
    [self.view addSubview:backgroundLabel];
#endif
    
    // Use the custom LCD font for the timecode display

    theTime.font = [UIFont fontWithName:@"Quartz DB" size: size];
    // theTime.textAlignment = UITextAlignmentRight;
    theTime.hidden = NO;
    
    // minLabel.font = [UIFont fontWithName:@"DBLCDTempBlack" size:10];
    // maxLabel.font = [UIFont fontWithName:@"DBLCDTempBlack" size:10];

    // Set various default settings
    
    maxLabelSet = NO;
    isSaving = NO;
    isPrinting = NO;
    fullScreenMode = NO;
    durationSet = NO;
    selectedNextClip = NO;
    airPlayMode = NO;
    
    fps = 0.0;
    pausePlayButton.enabled = NO;
    self.pauseImage = [UIImage imageNamed: @"pause2.png"];
    self.playImage = [UIImage imageNamed: @"play.png"];

    seekToZeroBeforePlay = YES;    
    movieTimeControl.value = 0;
    drawView.hidden = NO;
    notePaper.hidden = NO;
    keyboardShows = NO;
    pendingSave = NO;
    download  = kNotes;
    saveFrame = playerLayerView.frame;
    runAllMode = NO;
    recordButton.enabled = NO;
    self.recImage = [UIImage imageNamed: @"mic.png"];
    self.isRecordingImage = [UIImage imageNamed: @"micrec.png"];
    [recordButton setImage: recImage forState: UIControlStateNormal];
    [recordButton setImage: isRecordingImage forState: UIControlStateHighlighted];    
    playerLayerView.backgroundColor = [UIColor blackColor];
    
    self.notePaths = [NSMutableArray array];
    self.xmlPaths = [NSMutableArray array];
    self.txtPaths = [NSMutableArray array];
    self.noteData = [NSMutableArray array];
    voiceMemo = [[VoiceMemo alloc] init];
    recording.hidden = YES;
    
    self.FCPImage = [UIImage imageNamed: @"fcp.png"];
    self.FCPChapterImage = [UIImage imageNamed: @"fcpChapter.png"];
    self.AvidImage = [UIImage imageNamed: @"avid.png"];

    [movieTimeControl addTarget:self action:@selector(sliderDragBeganAction) forControlEvents:UIControlEventTouchDown];
    [movieTimeControl addTarget:self action:@selector(sliderDragEndedAction) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
    [movieTimeControl addTarget:self action:@selector(sliderValueChange) forControlEvents:UIControlEventValueChanged];	
    
    movieTimeControl.backgroundColor = [UIColor clearColor];	
    UIImage *stetchLeftTrack = [[UIImage imageNamed:@"redhi.png"] stretchableImageWithLeftCapWidth:10.0 topCapHeight:0.0];
    [movieTimeControl setMinimumTrackImage:stetchLeftTrack forState: UIControlStateNormal];
    
    // This is for the dialog for an "Open in.." or the camera roll

    filenameView.hidden = YES;
    filenameView.layer.borderWidth = 2;
	filenameView.layer.borderColor = [[UIColor grayColor] CGColor];
    
    CGPoint center = filenameView.center;
    saveFilename.delegate = self;
    
    if (! iPHONE) {
        center.x = 512;
        center.y = 200;
    }
    else {
        center.x = 240;
        center.y = 90;
    }
    
    filenameView.center = center;
    [self.view addSubview: filenameView];
 
    if (uploadCount)
        [uploadActivityIndicator stopAnimating];
    
    uploadCount = 0;
}

- (void) viewDidAppear: (BOOL) animated {
    
    [super viewDidAppear: animated];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
}

// Only observe time changes when the view controller's view is visible.
- (void)viewWillAppear:(BOOL)animated
{    
	[super viewWillAppear:animated];
    
    //---registers the notifications for keyboard---
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(keyboardDidShow:) 
                                                 name:UIKeyboardDidShowNotification 
                                               object:self.view.window]; 
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidHide:)
                                                 name:UIKeyboardDidHideNotification
                                               object:nil];
    
    [self makeSettings];
	[self startObservingTimeChanges];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	[self stopObservingTimeChanges];
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [self resignFirstResponder];
}


// Override to allow orientations other than the default portrait orientation.

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return interfaceOrientation == UIInterfaceOrientationLandscapeLeft || 
                    interfaceOrientation == UIInterfaceOrientationLandscapeRight;
}

- (void) didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	NSLog (@"*** VideoTreeViewController did receive memory warning");
    
    if (! activityIndicator.isAnimating) {
        self.activityIndicator = nil;
        self.progressView = nil;
    }
    
    if (! noteActivityIndicator.isAnimating) {
        self.noteActivityIndicator = nil;
        self.noteProgressView = nil;
    }
    
    if (! fullScreenActivityIndicator.isAnimating) {
        self.fullScreenActivityIndicator = nil;
        self.fullScreenProgressView = nil;
    }
}

- (void)viewDidUnload {
    [self setAirPlayImageView:nil];
    [self setPlayerToolbar:nil];
    [self setPlayOutButton:nil];
    NSLog (@"Viewcontroller view did unload");
    self.newNote = nil;
    self.theTime = nil;
    self.movieTimeControl = nil;
    self.drawView = nil;
    self.playerLayerView = nil;
    self.maxLabel = nil;
}


#pragma mark -
#pragma mark remote control (e.g. headphones)

-(void)remoteControlReceivedWithEvent:(UIEvent *)event {
    NSLog (@"Remote control event received");
    
    if (movieController) {
        switch (event.subtype) {
            case UIEventSubtypeRemoteControlTogglePlayPause:
                if (movieController.playbackState == MPMoviePlaybackStatePlaying)
                    [movieController pause];
                else if (movieController.playbackState == MPMoviePlaybackStatePaused)
                    [movieController play];
                break;
                
            case UIEventSubtypeRemoteControlPlay:
                [movieController play];
                break;
                
            case UIEventSubtypeRemoteControlPause:
                [movieController pause];
                break;
                
            case UIEventSubtypeRemoteControlBeginSeekingBackward:
                [movieController beginSeekingBackward];
                break;
                
            case UIEventSubtypeRemoteControlEndSeekingBackward: 
                [movieController endSeeking];
                break;
                
            case UIEventSubtypeRemoteControlBeginSeekingForward:
                [movieController beginSeekingForward];
                break;
            case UIEventSubtypeRemoteControlEndSeekingForward:
                [movieController endSeeking];
                break;
                
            default:
                break;
        }
        
        return;
    }
    
    if (!player)
        return;
    
    switch (event.subtype) {
        case UIEventSubtypeRemoteControlTogglePlayPause:
            [self playPauseButtonPressed: nil];
            break;
            
        case UIEventSubtypeRemoteControlPlay:
            if (player.rate == 0)
                [self playPauseButtonPressed: nil];
            break;
            
        case UIEventSubtypeRemoteControlPause:
            if (player.rate)
                [self playPauseButtonPressed: nil];
            break;
            
        case UIEventSubtypeRemoteControlBeginSeekingBackward:
            [self rewind];
            break;
            
        case UIEventSubtypeRemoteControlEndSeekingBackward: 
            [self playPauseButtonPressed: nil];
            break;

        case UIEventSubtypeRemoteControlBeginSeekingForward:
            [self fastForward];
            break;
            
        case UIEventSubtypeRemoteControlEndSeekingForward:
            [self playPauseButtonPressed: nil];
            break;
            
        default:
            break;
    }
}

#pragma mark -
#pragma mark activity indicators

-(void) showActivity
{
	if (!progressView) {
        CGRect theFrame = playerLayerView.frame;
        theFrame.origin = CGPointMake (0.0, 0.0);
        
        progressView = [[UIView alloc] initWithFrame: theFrame];
        progressView.alpha = 0.5;
        progressView.backgroundColor = [UIColor lightGrayColor];
        activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleWhiteLarge];
	
        CGSize theSize = playerLayerView.frame.size;
        CGPoint theCenter;
	
        theCenter.x = theSize.width / 2;
        theCenter.y = theSize.height / 2;
        activityIndicator.center = theCenter;
    }
	
    [progressView addSubview: activityIndicator];
	[activityIndicator startAnimating];
	[playerLayerView addSubview: progressView];
}

-(void) noteShowActivity
{
	if (!noteProgressView) {
        CGRect theFrame = notes.frame;
        theFrame.origin = CGPointMake (0.0, 0.0);
        
        noteProgressView = [[UIView alloc] initWithFrame: theFrame];
        noteProgressView.alpha = 0.5;
        noteProgressView.backgroundColor = [UIColor lightGrayColor];
        noteActivityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleWhiteLarge];
        
        CGSize theSize = notes.frame.size;
        CGPoint theCenter;
        
        theCenter.x = theSize.width / 2;
        theCenter.y = theSize.height / 2;
        noteActivityIndicator.center = theCenter;
        [noteProgressView addSubview: noteActivityIndicator];
    }
	
	[noteActivityIndicator startAnimating];
	[notes addSubview: noteProgressView];
}

-(void) fullScreenShowActivity
{
	if (!fullScreenProgressView) {
        CGRect theFrame = CGRectMake (0.0, 0.0, 1024., 768.);
        theFrame.origin = CGPointMake (0.0, 0.0);
        
        fullScreenProgressView = [[UIView alloc] initWithFrame: theFrame];
        fullScreenProgressView.alpha = 0.8;
        fullScreenProgressView.backgroundColor = [UIColor lightGrayColor];
        fullScreenActivityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleWhiteLarge];
        
        CGSize theSize = self.view.frame.size;
        CGPoint theCenter;
        
        theCenter.x = theSize.height / 2;
        theCenter.y = theSize.width / 2;
        fullScreenActivityIndicator.center = theCenter;
        [fullScreenProgressView addSubview: fullScreenActivityIndicator];
    }
	
	[fullScreenActivityIndicator startAnimating];
	[self.view addSubview: fullScreenProgressView];
}

-(void) stopActivity
{
//  NSLog (@"video clip: stopping activity indicator");
    
    if (activityIndicator.isAnimating) 
        [activityIndicator stopAnimating];
    
    [activityIndicator removeFromSuperview];
    [progressView removeFromSuperview];
    self.progressView = nil;
    self.activityIndicator = nil;

    if (autoPlay) {
        mySleep (1000);
        
        pausePlayButton.image = pauseImage;

        if (! airPlayMode) 
            [player play];
    }
}

-(void) noteStopActivity
{
//  NSLog (@"note table: stopping activity indicator");
    
    if (noteActivityIndicator.isAnimating)
        [noteActivityIndicator stopAnimating];
    
    [noteProgressView removeFromSuperview];
}

-(void) fullScreenStopActivity
{
    NSLog (@"fullscreen: stopping activity indicator");
    
    if (fullScreenActivityIndicator.isAnimating)
        [fullScreenActivityIndicator stopAnimating];
        
    [fullScreenProgressView removeFromSuperview];
}


-(void) uploadActivityIndicator: (BOOL) start
{
    NSLog (@"upload activity indicator: %i, count = %i", start, uploadCount);
    
    if (start == NO)   // stop the animation
        if (![uploadActivityIndicator isAnimating])
            return;
        else if (--uploadCount == 0) {
            [uploadActivityIndicator stopAnimating];
            uploadActivityIndicatorView.hidden = YES;

            [uploadActivityIndicator removeFromSuperview];
            self.uploadActivityIndicator = nil;
            return;
        }
    else if ([uploadActivityIndicator isAnimating])   // check if it's already started
        return;
    
    // start the animation
       
    uploadActivityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleWhite];
    CGSize theSize = {20, 20};
    CGPoint theCenter;
    
    theCenter.x = theSize.width / 2;
    theCenter.y = theSize.height / 2;
    uploadActivityIndicatorView.hidden = NO;
    activityIndicator.center = theCenter;
    [uploadActivityIndicatorView addSubview: uploadActivityIndicator];
 
    [uploadActivityIndicator startAnimating];
    [self.view bringSubviewToFront: uploadActivityIndicatorView];
    ++uploadCount;
}

- (IBAction)textFieldFinished: (UITextField *) textField
{
    NSLog (@"text field finished");
    [textField resignFirstResponder];
}

- (BOOL) textFieldShouldReturn: (UITextField *) textField 
{
    NSLog (@"text field should return");
    [textField resignFirstResponder];
    [self keyboardDidHide: nil];
    return NO;
}


- (void) keyboardDidShow: (id) notUsed
{
    keyboardShows = YES;
}

- (void) keyboardDidHide: (id) notUsed
{
    keyboardShows = NO;
    
    if (pendingSave) {
        pendingSave = NO;
        [self save];
        return;
    }
    
    // keyboard hides for entering file name to save

    if (filenameView.hidden == NO)
        [kAppDel saveFileNameEntered];
}

-(void) makeSettings
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // User's initials
    
    initials = [defaults objectForKey: @"Initials"];
    
    if (!initials || [initials isEqualToString: @""])
        initials = @"XXX";
    
    NSLog (@"Setting initials to %@", initials);
    
    // Watermark
    
    watermark = (BOOL) [defaults boolForKey: @"Watermark"];
    
    NSLog (@"Setting watermark to %i", watermark);
    
    // FCP export on or off
    
    FCPXML = [defaults boolForKey: @"FCPXML"];
    
    NSLog (@"Export XML: %i", FCPXML);
    
    // Avid export on or off
    
    AvidExport = [defaults boolForKey: @"AvidExport"];
    
    NSLog (@"Export Avid: %i", AvidExport);
    
    // Autoplay clips on or off
    
    autoPlay = (BOOL) [defaults boolForKey: @"AutoPlay"];
    
    NSLog (@"Setting autoplay to %i", autoPlay);
    
    // emailPDF on or off
    
    emailPDF = (BOOL) [defaults boolForKey: @"emailPDF"];
    
    NSLog (@"Setting emailPDF to %i", emailPDF);
    
    // timecodeFormat on or off
    
    timecodeFormat = (BOOL) [defaults boolForKey: @"Timecode"];
    
    NSLog (@"Setting timecodeFormat to %i", timecodeFormat);
    
    // Skip value
    
    skipValue = [[defaults objectForKey: @"skipValue"] integerValue];
    
    if (skipValue == 0)
        skipValue = 30;
    
    NSLog (@"Setting skip value to %i", skipValue);
    
    skipForwardButton.title = [NSString stringWithFormat: @"+%i", skipValue];
    skipBackButton.title = [NSString stringWithFormat: @"-%i", skipValue];
    
    if (watermark)  {
        self.stampLabel.text = initials;
        stampLabel.hidden = NO;
    }
    else
        stampLabel.hidden = YES;
         
    if (airPlayMode)
        [self airPlay];
}


#pragma mark -
#pragma mark Buttons

-(IBAction) color: (UISegmentedControl *) colorControl
{
    //  Programmatically change the image for the selected color
    
    switch (colorControl.selectedSegmentIndex) {
        case 0: 
            [self red];  
            [colorControl setImage: [UIImage imageNamed: @"redhi.png"] forSegmentAtIndex: 0]; 
            [colorControl setImage: [UIImage imageNamed: @"blue.png"] forSegmentAtIndex: 1]; 
            [colorControl setImage: [UIImage imageNamed: @"green.png"] forSegmentAtIndex: 2]; 

            break;
        case 1: 
             [self blue]; 
            [colorControl setImage: [UIImage imageNamed: @"red.png"] forSegmentAtIndex: 0]; 
            [colorControl setImage: [UIImage imageNamed: @"bluehi.png"] forSegmentAtIndex: 1]; 
            [colorControl setImage: [UIImage imageNamed: @"green.png"] forSegmentAtIndex: 2]; 
            break;
        case 2: 
            [self green];
            [colorControl setImage: [UIImage imageNamed: @"red.png"] forSegmentAtIndex: 0]; 
            [colorControl setImage: [UIImage imageNamed: @"blue.png"] forSegmentAtIndex: 1]; 
            [colorControl setImage: [UIImage imageNamed: @"greenhi.png"] forSegmentAtIndex: 2]; 
            
            break;
    }
}

-(void) red
{
    drawView.color = RED;
}

-(void) green
{
    drawView.color = GREEN;
}

-(void) blue
{
    drawView.color = BLUE;
}

-(IBAction) erase
{
    NSLog2 (@"Erase");
    [drawView cancelDrawing];
    [audioPlayer stop];
}

-(IBAction) recordNote
{
    if ([voiceMemo audioRecorder].isRecording) {
        NSLog (@"is recording...stop it");
        [recordButton setImage: recImage forState: UIControlStateNormal];
        [voiceMemo stopRecording];
        recording.hidden = YES;
        madeRecording = YES;
        newNote.text = [newNote.text stringByAppendingString: @" <<<Audio Note>>>"];
        [self save];
    }
    else {
        NSLog (@"Start recording");
        [self pauseIt];
        [recordButton setImage: isRecordingImage forState: UIControlStateNormal];
        recording.hidden = NO;
        [self.view bringSubviewToFront: recording];
        [voiceMemo startRecording];
    }
}

-(IBAction) unDo
{
    NSLog (@"Undo");
    [drawView unDo];
}

#pragma mark -
#pragma mark Playback Control

-(IBAction) backFrame
{
    [self erase];
    goingForward = NO;
    [self singleFrame];
}  
    

-(IBAction) rewind
{
    [self erase];
    
    if (!player)
        return;
    else
        pausePlayButton.image = pauseImage;
    
    if (player.rate >= 0.0)
        player.rate = -1.75;
    else if (player.rate < -13.0)
        player.rate = 1.0;
    else
        player.rate *= 2.0;

}

-(IBAction) rewindToStart
{
    [self erase];
    [player seekToTime: kCMTimeZero];
}

- (IBAction)playPauseButtonPressed:(id)sender
{    
    if (theTimer) 
        player.rate = 1.0;
    
	if (player.rate == 0.0) {
		// if we are at the end of the movie we must seek to the beginning first before starting playback
		if (YES == seekToZeroBeforePlay) {
			seekToZeroBeforePlay = NO;
			[player seekToTime: kCMTimeZero];
		}
        
        newNote.text = @"";
        [self erase];
		player.rate = 1.0;
        pausePlayButton.image = pauseImage;
	} else {
		[self pauseIt];
	}
}

-(IBAction) fastForward
{
    [self erase];
    
    if (!player)
        return;
    else
        pausePlayButton.image = pauseImage;
    
    if (player.rate <= 1.0)
        player.rate = 1.75;
    else if (player.rate > 13)
        player.rate = 1.0;
    else
        player.rate *= 2;
}

-(void) advance: (int) secs;
{
    if (!player || !pausePlayButton.enabled) 
        return;
    
    [self pauseIt];
    CMTime spot = CMTimeAdd ([player currentTime], kCMTimeMakeWithSeconds (secs));
    [player seekToTime: spot toleranceBefore: kCMTimeZero toleranceAfter: kCMTimeZero];
    [self playPauseButtonPressed: nil];
}

    
-(IBAction) skipBack
{
    NSLog (@"skip back");
    
    [self advance: -skipValue];
}


-(IBAction) skipForward
{
    NSLog (@"skip forward");

    [self advance: skipValue];
}


-(void) nextFrame: (NSTimer *) timer 
{
    if (goingForward)
        [player.currentItem stepByCount: 1];
    else
        [player.currentItem stepByCount: -1];
}

-(void) singleFrame
{
    if (!player)
        return;
    
    if (theTimer) {
        [self pauseIt];
        return;
    }   
    
    newNote.text = @"";
    [self erase];
    
    pausePlayButton.image = pauseImage;
    
    self.theTimer = [NSTimer scheduledTimerWithTimeInterval: .25 target:self 
                        selector:@selector(nextFrame:) userInfo:nil repeats:YES]; 
}

-(IBAction) forwardFrame
{
    [self erase];
    goingForward = YES;
    [self singleFrame];
}

-(IBAction) forwardToEnd
{
    if (!player)
        return;
    
    if (! durationSet) 
        return;
    
    [self erase];
        
    NSLog (@"Forwarding to %lg", CMTimeGetSeconds (endOfVid));
    [player seekToTime:  endOfVid  toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}
     

-(IBAction) pauseIt
{
    [player pause];
    pausePlayButton.image = playImage;
    
    if (theTimer) {
        [theTimer invalidate];
        self.theTimer = nil;
    }
}

#pragma mark -
#pragma mark Clip and Tape advance


#pragma mark -
#pragma mark Saving a note

// The first set of methods will only work if we can get an accurate screen grab
// The second set uses UIGetScreenImage (), which is a private API and may present problems
// getting through the app store

#define APPSTORE

#ifdef APPSTORE
-(void)drawMarkups: (CGContextRef) ctx width: (float) wid height: (float) ht { 
    //  CGContextTranslateCTM (ctx, playerLayerView.bounds.size.width / 8 - wid, ht);
    CGContextTranslateCTM (ctx, 0, ht);
    CGContextScaleCTM (ctx, ((wid * 8) / drawView.bounds.size.width) / 8, - ((ht * 8) / drawView.bounds.size.height) / 8 ); 
    
    NSArray *myDrawing = drawView.myDrawing;
    NSArray *colors = drawView.colors;
    
    if ([myDrawing count] > 0) {
        CGContextSetLineWidth(ctx, 4);
        
        for (int i = 0; i < [myDrawing count]; ++i) {	
            NSArray *thisArray = [myDrawing objectAtIndex: i];
            NSInteger theColor = [[colors objectAtIndex: i] integerValue];
            
            if ([thisArray count] > 2) {
                switch ( theColor) {
                    case RED:
                        CGContextSetRGBStrokeColor(ctx, (CGFloat) 1, (CGFloat) 0, (CGFloat) 0, (CGFloat) 1);
                        break;
                    case GREEN:
                        CGContextSetRGBStrokeColor(ctx, (CGFloat) 0, (CGFloat) 1, (CGFloat) 0, (CGFloat) 1);
                        break;
                    case BLUE:
                        CGContextSetRGBStrokeColor(ctx, (CGFloat) 0, (CGFloat) 0, (CGFloat) 1, (CGFloat) 1);
                        break;
                }
                
                float thisX = [[thisArray objectAtIndex:0] floatValue];
                float thisY = [[thisArray objectAtIndex:1] floatValue];
                
                CGContextBeginPath(ctx);
                CGContextMoveToPoint(ctx, thisX, thisY);
                
                for (int j = 2; j < [thisArray count] ; j += 2) {
                    thisX = [[thisArray objectAtIndex:j] floatValue];
                    thisY = [[thisArray objectAtIndex:j + 1] floatValue];
                    
                    CGContextAddLineToPoint(ctx, thisX,thisY);
                }
                CGContextStrokePath(ctx);
            }
        }
    }
}

-(void) frameDraw
{
// [player seekToTime:[player currentTime] toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    
    AVAssetImageGenerator *imageGen = [[AVAssetImageGenerator alloc] initWithAsset: [[player currentItem] asset]];
 
    if (!imageGen) {
        NSLog (@"AVAssetImageGenerator failed!");
        return;
    }
    
//  [imageGen setMaximumSize: CGSizeMake (320, 196)];
    [imageGen setVideoComposition:[[player currentItem] videoComposition]];
    [imageGen setAppliesPreferredTrackTransform:YES];
    
    if (kRunningOS5OrGreater){
        [imageGen setRequestedTimeToleranceAfter: kCMTimeZero];
        [imageGen setRequestedTimeToleranceBefore: kCMTimeZero];
    }

    NSError *error = nil;
    CMTime actual;
    CMTime request = [player currentTime];   // kCMTimeMakeWithSeconds (kCVTime([player currentTime]));

    CGImageRef image = [imageGen copyCGImageAtTime: request actualTime: &actual error: &error];
    NSLog (@"Request for frame at %@, actual = %@ (fps = %f)", [self timeFormat: request], [self timeFormat: actual], fps);

    if (error)  {
        NSLog (@"Error trying to capture image: %@ at time: %@", [error localizedDescription], [self timeFormat: request]);
        return;
    }
   
#ifdef ASYNC  
    NSArray *requestedTimes = [NSArray arrayWithObject: [NSValue valueWithCMTime: request]];
    
    [imageGen generateCGImagesAsynchronouslyForTimes: requestedTimes completionHandler:
        ^(CMTime requestedTime, CGImageRef image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error) {
            if (error) 
                NSLog (@"Error trying to capture image: %@ at time: %@", [error localizedDescription], [self timeFormat: requestedTime]);
            
            NSLog (@"Async Request for frame at %@, actual = %@ (fps = %f)", [self timeFormat: requestedTime], [self timeFormat: actualTime], fps);
        }];
#endif

   CGImageAlphaInfo	alphaInfo = CGImageGetAlphaInfo(image);
    
    NSLog (@"alphaInfo = %x", alphaInfo);
    
    if (alphaInfo == kCGImageAlphaNone)
        alphaInfo = kCGImageAlphaNoneSkipLast;
    
    int  wid = CGImageGetWidth (image) + CGImageGetWidth (image) % 8;
    int  ht =  CGImageGetHeight (image)  + CGImageGetHeight(image) % 8;  
    
    wid = 320;
    ht = 192;
    
    NSLog (@"image width,height = (%i, %i)", wid, ht);
    
    CGRect thumbRect = { 
        {0.0f, 0.0f}, 
        {(float) wid, (float) ht}
    };
    
    NSLog (@"bits per component = %i, color space = %i",  CGImageGetBitsPerComponent(image), CGImageGetColorSpace(image));
    
    // Build a bitmap context that's the size of the thumbRect
    CGContextRef bitmap = CGBitmapContextCreate(
                NULL,
                thumbRect.size.width,		// width
                thumbRect.size.height,		// height
                CGImageGetBitsPerComponent(image),	
                4 * thumbRect.size.width,	// rowbytes
                CGImageGetColorSpace(image),
                alphaInfo
                );
    
    // Draw into the context, this scales the image
    CGContextDrawImage(bitmap, thumbRect, image);
    
    [self drawMarkups: bitmap width: wid height: ht];
    
    // Get an image from the context and a UIImage
    CGImageRef	ref = CGBitmapContextCreateImage(bitmap);
    self.newThumb = [UIImage imageWithCGImage:ref];
    NSLog (@"saved image size = %f x %f", newThumb.size.width, newThumb.size.height);
    
    CGContextRelease (bitmap);	// ok if NULL
    CGImageRelease (ref);
    CGImageRelease (image);
    [imageGen release];
}

#else

- (CGImageRef)CGImageRotatedByAngle:(CGImageRef)imgRef angle:(CGFloat)angle
{
	CGFloat angleInRadians = angle * (M_PI / 180);
	CGFloat width = CGImageGetWidth(imgRef);
	CGFloat height = CGImageGetHeight(imgRef);
    
	CGRect imgRect = CGRectMake(0, 0, width, height);
	CGAffineTransform transform = CGAffineTransformMakeRotation(angleInRadians);
	CGRect rotatedRect = CGRectApplyAffineTransform(imgRect, transform);
    
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef bmContext = CGBitmapContextCreate(NULL,
                            rotatedRect.size.width,
                            rotatedRect.size.height,
                            8,
                            0,
                            colorSpace,
                            kCGImageAlphaPremultipliedFirst);
	CGContextSetAllowsAntialiasing(bmContext, YES);
	CGContextSetInterpolationQuality(bmContext, kCGInterpolationHigh);
	CGColorSpaceRelease(colorSpace);
	CGContextTranslateCTM(bmContext,
						  +(rotatedRect.size.width/2),
						  +(rotatedRect.size.height/2));
	CGContextRotateCTM(bmContext, angleInRadians);
	CGContextDrawImage(bmContext, CGRectMake(-width/2, -height/2, width, height),
					   imgRef);
    
	CGImageRef rotatedImage = CGBitmapContextCreateImage(bmContext);
	CFRelease(bmContext);  
    
	return rotatedImage;
}


-(void) frameDraw
{
    CGImageRef UIGetScreenImage ();
    CGImageRef rotatedScreen = UIGetScreenImage ();
    
    CGRect thumbRect = playerLayerView.frame; 
   
    if ( !iPHONE) 
        if (self.interfaceOrientation == UIDeviceOrientationLandscapeLeft) {
            NSLog (@"UIDeviceOrientationLandscapeLeft");
            thumbRect.origin = (CGPoint) {thumbRect.origin.y - thumbRect.size.height / 2, thumbRect.origin.x + 20};
            thumbRect.size = (CGSize) {thumbRect.size.height, thumbRect.size.width};
        }
        else  {     
            NSLog (@"Not UIDeviceOrientationLandscapeLeft");
            thumbRect.origin = (CGPoint) {thumbRect.origin.y + 20, thumbRect.origin.x - thumbRect.size.height / 2};
            thumbRect.size = (CGSize) {thumbRect.size.height, thumbRect.size.width};
        }
    else {
        thumbRect.origin = (CGPoint) {145 + thumbRect.size.width / 2, thumbRect.size.height / 2};
        thumbRect.size = (CGSize) { thumbRect.size.width * 2, thumbRect.size.height * 2 };
    }
    
    CGImageRef imageR;
    CGImageRef image;

    if (iPHONE) {
        if (self.interfaceOrientation  == UIDeviceOrientationLandscapeRight)
             image = [self CGImageRotatedByAngle: rotatedScreen angle: -90];
        else
             image = [self CGImageRotatedByAngle: rotatedScreen angle: 90];

        imageR = CGImageCreateWithImageInRect (image, thumbRect);
    }
    else {
        image = CGImageCreateWithImageInRect (rotatedScreen, thumbRect);        
        
        if (self.interfaceOrientation  == UIDeviceOrientationLandscapeRight)
            imageR = [self CGImageRotatedByAngle: image angle: -90];
        else
            imageR = [self CGImageRotatedByAngle: image angle: 90];
    }
      
    self.newThumb = [UIImage imageWithCGImage: imageR scale: iPHONE ? 4 : 64 orientation: UIImageOrientationUp];
    CGImageRelease (rotatedScreen);  
    
    NSLog (@"bits per component = %i, color space = %i",  CGImageGetBitsPerComponent(image), CGImageGetColorSpace(image));
    
    CGImageRelease (image);
    CGImageRelease (imageR);  

    NSLog (@"saved image size = %f x %f", newThumb.size.width, newThumb.size.height);
}
#endif

-(IBAction) save
{
    if (keyboardShows)  {
        [newNote resignFirstResponder];
        pendingSave = YES;
        return;
    }
    
    if ([voiceMemo audioRecorder].isRecording)  { 
        [self recordNote];
        return;
    }
    
    if (!player || player.rate != 0.0)
        return;

    Note *aNewNote = [[Note alloc] init];

    [self frameDraw];
    
    CMTime curTime =  kCMTimeMakeWithSeconds (kCVTime ([player currentTime]) + startTimecode);

    aNewNote.text = newNote.text;
    
    BOOL saveFormat = timecodeFormat;
    timecodeFormat = YES;
    aNewNote.timeStamp = [self timeFormat: curTime];
    timecodeFormat = saveFormat;
    
    aNewNote.drawing = [drawView myDrawing];
    aNewNote.colors = [drawView colors];
    aNewNote.date = [self formatDate: NO];
    aNewNote.initials = initials;
    aNewNote.frameWidth = playerLayerView.frame.size.width;
    aNewNote.frameHeight = playerLayerView.frame.size.height;

    if (madeRecording)
        aNewNote.voiceMemo = [NSData dataWithContentsOfURL:[voiceMemo memoURL]];
    else
        aNewNote.voiceMemo = nil;

    isSaving = YES;
    aNewNote.thumb = UIImageJPEGRepresentation(newThumb, 0.25f);

    [self animateSave];
    
    // Find where to put the note in the table
    
    Float64 now = CMTimeGetSeconds(curTime);
                                         
    int row = 0;
    for (Note *theNote in noteData) {
        if ([self convertTimeToSecs: theNote.timeStamp] > now)
            break;
        ++row;
    }
    
    // Insert the note into the array and table
    
    NSIndexPath *indexP = [NSIndexPath indexPathForRow: row inSection:0];
    NSArray *indexPaths = [[NSArray alloc] initWithObjects: indexP, nil];
    
    [noteData insertObject: aNewNote atIndex: row];
    [aNewNote release];

    [notes insertRowsAtIndexPaths:(NSArray *)indexPaths 
                     withRowAnimation:(UITableViewRowAnimation)UITableViewRowAnimationLeft];

    @try 
    {
        [notes scrollToRowAtIndexPath: indexP 
                     atScrollPosition: UITableViewScrollPositionBottom animated: YES];
    }
    @catch (NSException * e)
    {
        //do nothing
        NSLog (@"Tace condition with notes table exception: %@", [e reason]);
    }

    
    // Clear the note
    
    newNote.text = @"";
    [self erase];
    madeRecording = NO;
    [indexPaths release];
    [self storeData];
    
    pendingSave = NO;
}

-(void) animateSave {
    // animate frame save
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, playerLayerView.layer.frame.origin.x + playerLayerView.layer.bounds.size.width / 2,
                      playerLayerView.frame.origin.y + playerLayerView.layer.bounds.size.height / 2);
    if ( !iPHONE)
        CGPathAddQuadCurveToPoint(path, NULL, 350, playerLayerView.layer.frame.origin.y, 0, 600);
    else
        CGPathAddQuadCurveToPoint(path, NULL, 350, playerLayerView.layer.frame.origin.y, 0, 300);
    
    CAKeyframeAnimation *pathAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    pathAnimation.path = path;
    pathAnimation.duration = 1.0;
    
    CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
    CATransform3D t = CATransform3DMakeScale(0.1, 0.1, 1.0);
    scaleAnimation.toValue = [NSValue valueWithCATransform3D:t];
    
    CABasicAnimation *alphaAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    alphaAnimation.toValue = [NSNumber numberWithFloat:0.5f];    
    
    CAAnimationGroup *animationGroup = [CAAnimationGroup animation];
    animationGroup.animations = [NSArray arrayWithObjects:pathAnimation, scaleAnimation, alphaAnimation, nil];
    animationGroup.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animationGroup.duration = 1.0;
    
    [playerLayerView.layer addAnimation:animationGroup forKey:nil];
    
    CFRelease(path);
    
    // animate note saving
    path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, newNote.frame.origin.x + newNote.bounds.size.width / 2,
                      newNote.frame.origin.y + newNote.bounds.size.height / 2);
    if ( !iPHONE)
        CGPathAddQuadCurveToPoint(path, NULL, 450, newNote.frame.origin.y, 0, 800);
    else
        CGPathAddQuadCurveToPoint(path, NULL, 450, newNote.frame.origin.y, 0, 400);
    
    CAKeyframeAnimation *pathAnimation2 = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    pathAnimation2.path = path;
    pathAnimation2.duration = 1.0;
    
    CABasicAnimation *scaleAnimation2 = [CABasicAnimation animationWithKeyPath:@"transform"];
    CATransform3D t2 = CATransform3DMakeScale(0.1, 0.1, 1.0);
    scaleAnimation2.toValue = [NSValue valueWithCATransform3D:t2];
    
    CABasicAnimation *alphaAnimation2 = [CABasicAnimation animationWithKeyPath:@"opacity"];
    alphaAnimation2.toValue = [NSNumber numberWithFloat:0.5f];    
    
    CAAnimationGroup *animationGroup2 = [CAAnimationGroup animation];
    animationGroup2.animations = [NSArray arrayWithObjects:pathAnimation2, scaleAnimation2, alphaAnimation2, nil];
    animationGroup2.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animationGroup2.duration = 1;
    
    [newNote.layer addAnimation:animationGroup2 forKey:nil];
    
    CFRelease(path);
}

#pragma mark -
#pragma mark make file paths

-(NSString *) txtFilePath
{
	NSArray *dirList = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *docDir = [dirList objectAtIndex: 0];
    
    NSString *fileName = [NSString stringWithFormat: @"%@.txt", [clip stringByDeletingPathExtension]];
    NSLog (@"Archive file name = %@", fileName);
	return [docDir stringByAppendingPathComponent: fileName];
}


-(NSString *) archiveFilePath
{
	NSArray *dirList = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *docDir = [dirList objectAtIndex: 0];
    
    NSString *fileName = [NSString stringWithFormat: @"%@.%@", clip, initials];
    NSLog (@"Archive file name = %@", fileName);
	return [docDir stringByAppendingPathComponent: fileName];
}

// Archiving methods for our data

-(void) loadData: (NSString *) theInitials  {
    download = kNotes;
    
    if (kFTPMode) {
        [FTPHelper sharedInstance].delegate = self;
        [FTPHelper sharedInstance].uname =  kFTPusername;
        [FTPHelper sharedInstance].pword =  kFTPpassword;
        
        NSString *home = homeDir;
        
        if ( kBonjourMode )
            home = @"/Sites";
        
        NSString *urlString = [NSString stringWithFormat: @"ftp://%@%@", kFTPserver, home ];
 //    urlString = [urlString stringByReplacingOccurrencesOfString: @" " withString: @"%20"];
        
        NSLog (@"Trying to download file from %@",  urlString);
        [FTPHelper sharedInstance].urlString = urlString;
        
        [FTPHelper download: [NSString stringWithFormat: @"Notes/%@.%@", clip, theInitials] to: [self archiveFilePath]];
        NSLog (@"download returned...in process");
    }
    else 
        dispatch_async (dispatch_get_main_queue(),
            ^{
                NSFileManager *fm = [NSFileManager defaultManager];
                [self noteShowActivity];
                
                if ([fm fileExistsAtPath: [self archiveFilePath]]) {
                    NSArray *noteArray = [NSKeyedUnarchiver unarchiveObjectWithFile: [self archiveFilePath]];
                    [noteData release];
                    noteData = [noteArray mutableCopy];
                    NSLog (@"Restored %i locally saved notes", [noteData count]);
                }
                else {
                    [noteData removeAllObjects];
                    [self.notes setEditing: NO];            
                    NSLog (@"No notes to restore");
                }
                [self noteStopActivity];
                [notes reloadData];
            });
}

-(void) setStartTimecode   
{
    if (kFTPMode) {
        if (startTimecode > 0.001) {
            if ([xmlPaths count]) 
                [self getXML: [xmlPaths objectAtIndex: 0]];
                        
            if ([txtPaths count]) 
                [self getAvid: [txtPaths objectAtIndex: 0]];
            
            return;
        }
        
        download = kTimecode;
        
        [FTPHelper sharedInstance].delegate = self;
        [FTPHelper sharedInstance].uname = kFTPusername;
        [FTPHelper sharedInstance].pword = kFTPpassword;
        
         NSString *urlString = [NSString stringWithFormat: @"ftp://%@/", kFTPserver];
        
        [FTPHelper sharedInstance].urlString = urlString;
        
        NSArray *dirList = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *docDir = [dirList objectAtIndex: 0];
        
        NSString *fileName = [NSString stringWithFormat: @"%@.tc", [clip stringByDeletingPathExtension]];
        fileName = [docDir stringByAppendingPathComponent: fileName];
        NSLog (@"Trying to download ftp timecode file %@ to %@", [clipPath  stringByDeletingPathExtension], fileName);
      
        [FTPHelper download: [NSString stringWithFormat: @"%@.tc", [clipPath stringByDeletingPathExtension]] to: fileName];

    }
}

-(void) getAllFTPNotes
{
    [FTPHelper sharedInstance].delegate = self;
	[FTPHelper sharedInstance].uname = kFTPusername;
	[FTPHelper sharedInstance].pword = kFTPpassword;
    
    NSString *home = homeDir;
    
    if (kBonjourMode)
        home = @"/Sites";
    
	// Listing
	[FTPHelper list: [NSString stringWithFormat: @"ftp://%@:%@@%@%@/Notes/", [FTPHelper sharedInstance].uname, 
    [FTPHelper sharedInstance].pword, kFTPserver, home]];
}

// the FTP listing has finished; gather all the notes

#define CONTAINS(x,y) ([x rangeOfString: y].location != NSNotFound)

#pragma mark -
#pragma mark XML import

-(void) XMLDone: (NSArray *) data
{
	self.markers = data;

    for (NSDictionary *aDict in markers) {
        Note *XMLNote = [[Note alloc] init];
        
        XMLNote.text = [aDict objectForKey: @"comment"];
        
        if ( [XMLNote.text rangeOfString: @"<CHAPTER>"].location != NSNotFound)  {
            NSLog (@"Chapter marker");
            XMLNote.thumb = UIImageJPEGRepresentation(FCPChapterImage, 1.0f);
        }
        else
            XMLNote.thumb = UIImageJPEGRepresentation(FCPImage, 1.0f);
        
        XMLNote.initials = [aDict objectForKey: @"name"];
        XMLNote.date = @"";
        XMLNote.frameWidth = 1.0;
        XMLNote.frameHeight = 1.0;
        XMLNote.drawing = [NSMutableArray array];
        XMLNote.colors = [NSMutableArray array];
        
        if (fps < .001)
            fps = 24;

        int32_t fpsUse = fps + .5; 
        
        Float64  now =  [[aDict objectForKey: @"in"] floatValue] / fpsUse + startTimecode;
        XMLNote.timeStamp = [self timeFormat: kCMTimeMakeWithSeconds (now)];
        
        NSLog (@"XML Marker timecode = %@ (%g), start = %g", XMLNote.timeStamp, now, startTimecode);
        
        int row = 0;
        
        for (Note *aNote in noteData) { 
            Float64  tabTime = [self convertTimeToSecs: aNote.timeStamp];
            if ( tabTime >= now ) 
                    break;
            ++row;
        }
            
        // Insert the note into the array and table
            
        [noteData insertObject: XMLNote atIndex: row];
    
        [XMLNote release];
    }

    [notes reloadData];
}

-(void) getXML: (NSString *) file
{
    NSLog (@"processing XML file %@", file);
    
    file = [file stringByReplacingOccurrencesOfString: @" " withString:@"%20"];
    
    if (!XMLURLreader)
		XMLURLreader = [[XMLURL alloc] init];

    NSString *url = [NSString stringWithFormat: @"%@%@/Notes/%@", kHTTPserver, userDir, file];
	
	[XMLURLreader parseXMLURL: url atEndDoSelector: @selector (XMLDone:) withObject: self];
}

-(void) receivedListing: (NSArray *) listing
{
    [self noteShowActivity];
    NSString *f = [[clip stringByReplacingOccurrencesOfString: @"%20" withString: @" "]
                   stringByDeletingPathExtension];

    NSLog (@"receivedListing, clip is %@", f);
    [notePaths removeAllObjects];
    [xmlPaths removeAllObjects];
    [txtPaths removeAllObjects];

	for (NSDictionary *dict in listing) {
        NSString *fileName = [FTPHelper textForDirectoryListing:(CFDictionaryRef) dict];
		NSLog (@"Found ftp file: %@", fileName);
        
        if ( [fileName rangeOfString: f].location == NSNotFound ) {
            NSLog2 (@"Skipping file %@", fileName);
            continue;
        }
        
        NSString *extension = [fileName pathExtension];
        
        if ( EQUALS (extension, @"mp4") || EQUALS (extension, @"m4v")  
            || EQUALS (extension, @"mov") || EQUALS (extension, @"m3u8")) {
            NSLog2 (@"Skipping FTP file %@", fileName);
            continue;
        }
        
        // Look for an XML or txt (Avid import) or note file
        
        if ( EQUALS (extension, @"xml") ) {
            [xmlPaths addObject: fileName];
            NSLog (@"Found XML file %@", fileName );
        }
        else if ( EQUALS (extension, @"txt") ) {
            [txtPaths addObject: fileName];
            NSLog (@"Found txt file (Avid import) %@", fileName );
        }
        else
            [notePaths addObject: extension];
    }
    
    // kick off the loading of the note files; the rest are loaded from the downloadFinished callback
    noteFileProcessed = 0;

    if ([notePaths count] != 0)
        [self loadData: [notePaths objectAtIndex: 0]];
    else {
        [self noteStopActivity];
        [self setStartTimecode];
    }
}

- (void) listingFailed
{    
	NSLog (@"Nothing to list on the server?");
    
    // retry -- seems to be a problem when awakening the App
    
    if (reTryCount < 3) {
        [self noteStopActivity];
        ++reTryCount;
        NSLog (@"retry #%i listing", reTryCount);
        [self getAllFTPNotes];
    }
    else {
        reTryCount = 0;
        [self noteStopActivity];
    }
}

-(NSMutableArray *) getMyNotes
{
    NSMutableArray *myNotes = [[NSMutableArray alloc] init];
    
    for (Note *aNote in noteData) 
        if ([aNote.initials isEqualToString: initials]) 
            [myNotes addObject: aNote];
    
    return myNotes;
}

-(void) storeData  {
    NSMutableArray *myNotes = [self getMyNotes];
    NSString *archivePath = [self archiveFilePath];
    
    // Write the notes to a local archive file first 
    
    if ([NSKeyedArchiver archiveRootObject: myNotes toFile: archivePath] == NO) {
        [myNotes release];
        [UIAlertView doAlert: @"Notes" 
                     withMsg: @"Couldn't save your notes locally!"];
        NSLog (@"Save failed");
    }
    else {
        if (kFTPMode) {   // Upload the notes archive with FTP
            [myNotes release];
            [FTPHelper sharedInstance].delegate = self;
            [FTPHelper sharedInstance].uname = kFTPusername;
            [FTPHelper sharedInstance].pword = kFTPpassword;
            
            NSString *urlString = [NSString stringWithFormat: @"ftp://%@", kFTPserver];
            
            NSLog (@"Saving file %@ to %@", archivePath, urlString);
            [FTPHelper sharedInstance].urlString = urlString;

            [FTPHelper upload: archivePath];
            NSLog2 (@"upload returned...in process");
        }
    }
}

#pragma mark -
#pragma mark FTP Callbacks



- (void) dataUploadFinished: (NSNumber *) bytes;
{
	NSLog (@"Uploaded %@ bytes", bytes);
    [self uploadActivityIndicator: NO];
}

- (void) dataUploadFailed: (NSString *) reason
{
	NSLog (@"Upload Failed: %@", reason);
    [UIAlertView doAlert: @"File Server" 
                 withMsg: [NSString stringWithFormat: @"File upload failed.  Reason: %@", reason]];
    [self uploadActivityIndicator: NO];
}

- (void) downloadFinished
{
    NSFileManager *fm = [NSFileManager defaultManager];
    
    if (download == kTimecode) {
        startTimecode = 0.0;
        
        NSArray *dirList = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *docDir = [dirList objectAtIndex: 0];
        
        NSString *fileName = [NSString stringWithFormat: @"%@.tc", [clip stringByDeletingPathExtension]];
        fileName = [docDir stringByAppendingPathComponent: fileName];
        
        NSString *data = [NSString stringWithContentsOfFile: fileName encoding: NSASCIIStringEncoding error: NULL];
        
        if (data) {
            startTimecode = [self convertTimeToSecs: data];
            NSLog (@"Read starting timecode from file: %@ (%lg)", data, startTimecode);

            durationSet = NO;
            maxLabelSet = NO;
            [self updateTimeControl];
            [self updateTimeLabel];
        }        
        
        if ([txtPaths count]) {
            download = kAvidTXT;
            
            [self getAvid: [txtPaths objectAtIndex: 0]];
        }
        
        // XML file access is done via http:
        
        if ([xmlPaths count]) 
            [self getXML: [xmlPaths objectAtIndex: 0]];
        
        return;
    }
    else if (download == kAvidTXT) {
        // Avid import support is done through ftp download

        self.markers = [self parseAvidMarkers];
        download  = kNotes;

        return;
    }
    
    // Download notes files
    
    NSString *path = [self archiveFilePath];
    
	NSLog (@"File stored to %@", path);

    NSArray *noteArray = nil;
    
    if ([fm fileExistsAtPath: path]) {
        // This can throw an exception, so let's catch it if it does
        
        @try  {
            noteArray = [NSKeyedUnarchiver unarchiveObjectWithFile: path];
        }
        @catch (NSException *exception) {
            NSLog (@"unarchiving failed!");
            goto Next;
        }
        
        [fm removeItemAtPath: path error: NULL];
            
        for (Note *theNote in noteArray) {
            Float64 now = [self convertTimeToSecs: theNote.timeStamp];
            int row = 0;
            
            for (Note *aNote in noteData) {
                if ([self convertTimeToSecs: aNote.timeStamp] > now)
                    break;
                ++row;
            }
            
            // Insert the note into the array and table
            
            [noteData insertObject: theNote atIndex: row];
        }
        
        NSLog (@"Restored %i notes", [noteData count]);
        [notes reloadData];
    }  
    
    // kick off the next download now
    
Next:
    ++noteFileProcessed;
    if (noteFileProcessed >= [notePaths count]) {
        [self setStartTimecode];        
        [self noteStopActivity];

        return;
    }
    else
        [self loadData: [notePaths objectAtIndex: noteFileProcessed]];
}

-(void) clearAnyNotes
{
    [noteData removeAllObjects];
    [self.notes setEditing: NO];
    [notes reloadData];
}

- (void) dataDownloadFailed: (NSString *) reason
{
	NSLog (@"Download failed... %@", reason);
    
    if (download == kTimecode) {
        if ([xmlPaths count]) 
            [self getXML: [xmlPaths objectAtIndex: 0]];
        
        if ([txtPaths count])  {
            download = kAvidTXT;
            [self getAvid: [txtPaths objectAtIndex: 0]];
        }
    }
}


#pragma mark -
#pragma mark FCPPro export

-(NSString *) exportXML     // Final Cut Pro Marker export
{
    if ( ! FCPXML || ! [noteData count])
        return nil;
    
    NSString *theClip = [[clip  uppercaseString] stringByDeletingPathExtension];
    
    NSMutableString *XML = [NSMutableString stringWithString: 
    [NSString stringWithFormat: 
@"<?xml version=\"1.0\" encoding=\"UTF-8\"?> \n\
<!DOCTYPE xmeml> \n\
<xmeml version=\"4\">\n\
<clip id=\"%@\">\n\
<name>%@</name>\n\
<duration>%i</duration>\n\
<rate>\n\
\t<ntsc>TRUE</ntsc>\n\
\t<timebase>%i</timebase>\n\
</rate>\n\
<media>\n\
\t<video>\n\
\t\t<track>\n\
\t\t<clipitem id=\"%@1\">\n\
\t\t<file id=\"%@2\">\n\
\t\t<name>%@</name>\n\
\t\t<pathurl>file://localhost/Volumes/Movies/%@</pathurl>\n\
\t\t</file>\n\
\t\t</clipitem>\n\
\t\t</track>\n\
\t</video>\n\
</media>\n", 
     theClip, theClip,
     (int) (CMTimeGetSeconds (player.currentItem.asset.duration) * (int)(fps + .5)), 
     (int) (fps + .5), theClip, theClip, theClip, clip]];
           
    int marker = 1;
 
    for (Note *aNote in noteData) {
       [XML appendString: [NSString stringWithFormat: 
@"<marker>\n\
    <name>VideoTree #%i</name>\n\
    <comment>%@</comment>\n\
    <in>%i</in>\n\
    <out>-1</out>\n\
</marker>\n", marker, 
       [[[aNote.text stringByReplacingOccurrencesOfString: @"<<<Audio Note>>>" 
            withString: @"--audio note---"] 
                    stringByReplacingOccurrencesOfString: @"<" withString: @"&lt;"]
                    stringByReplacingOccurrencesOfString: @">" withString: @"&gt;"]             , 
            (int) (([self convertTimeToSecs: aNote.timeStamp] - startTimecode) * (int) (fps + .50000001))]];
        ++marker;
    }
    
    [XML appendString: @"</clip>\n</xmeml>\n"];
    NSLog (@"\n%@", XML);
    
    // Write the XML out to a local file
    
    NSArray *dirList = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDir = [dirList objectAtIndex: 0];
    
    NSString *fileName = [NSString stringWithFormat: @"%@.xml", [clip stringByDeletingPathExtension]];
    NSLog (@"XML file name = %@", fileName);
    fileName = [docDir stringByAppendingPathComponent: fileName];
    if (! [XML writeToFile: fileName atomically: NO  encoding: NSUTF8StringEncoding error: NULL]) {
        NSLog (@"Write of XML file failed");
        return nil;
    }
    else
        return fileName;
                                   
#if 0  
    [FTPHelper sharedInstance].delegate = self;
    [FTPHelper sharedInstance].uname = [kAppDel FTPusername];
    [FTPHelper sharedInstance].pword = [kAppDel FTPpassword];
    
    NSString *urlString = [NSString stringWithFormat: @"ftp://%@", [kAppDel FTPserver]];
    
    NSLog2 (@"Saving file %@ to %@", fileName, urlString);
    [FTPHelper sharedInstance].urlString = urlString;
    
    [FTPHelper upload: fileName];
    NSLog2 (@"upload returned...in process");
#endif
}


#pragma mark -
#pragma mark Avid Locator import/export
                                   

-(NSString *) exportAvid
{
    if ( ! AvidExport || ! [noteData count])
        return nil;
        
    NSMutableString *LocatorString = [NSMutableString string]; 
    
    int marker = 1;
    
    for (Note *aNote in noteData) {
        [LocatorString appendString: 
        [NSString stringWithFormat: @"VideoTree #%i\t%i\tred\t%@\n", marker, 
        (int) (([self convertTimeToSecs: aNote.timeStamp] - startTimecode) * (int) (fps + .50000001)), aNote.text]];
        ++marker;
    }
    
    NSLog (@"\n%@", LocatorString);
    
    // Write the Locator file  to a local file
    
    NSArray *dirList = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDir = [dirList objectAtIndex: 0];
    
    NSString *fileName = [NSString stringWithFormat: @"%@.txt", [clip stringByDeletingPathExtension]];
    NSLog (@"Avid Locator file name = %@", fileName);
    fileName = [docDir stringByAppendingPathComponent: fileName];
    if (! [LocatorString writeToFile: fileName atomically: NO  encoding: NSUTF8StringEncoding error: NULL]) {
        NSLog (@"Write of XML file failed");
        return nil;
    }
    else
        return fileName;
}

-(NSArray *) parseAvidMarkers
{
    // Create an array of dictionaries to match the output from the XML parser
    
    NSMutableArray *locators = [NSMutableArray array];
    
    // Read each line from the text file and parse it
    
    NSLog (@"Parsing Avid locator file...");
    
    NSError *error;
    
    NSString * content = [NSString stringWithContentsOfFile: [self txtFilePath] encoding:NSUTF8StringEncoding error: &error];
    
    // Separate file into lines
    
    NSArray *allLines = [content componentsSeparatedByString: @"\n"];
    
    for (NSString *aLine in allLines) {
        Note *AvidNote = [[Note alloc] init];
        
        // Separate each line into fields
        
        NSArray *fields = [aLine componentsSeparatedByString: @"\t"];
        
        if ([fields count] > 4)
            AvidNote.text = [fields objectAtIndex: 4];
        else
            AvidNote.text = @"";

        AvidNote.thumb = UIImageJPEGRepresentation(AvidImage, 1.0f); 
        
        AvidNote.initials = @"Avid";
        AvidNote.date = @"";
        AvidNote.frameWidth = 1.0;
        AvidNote.frameHeight = 1.0;
        AvidNote.drawing = [NSMutableArray array];
        AvidNote.colors = [NSMutableArray array];
        
        if ([fields count] > 1) {
            if (fps < .001)
                fps = 24;
            
            int32_t fpsUse = fps + .5; 
            
            AvidNote.timeStamp = [fields objectAtIndex: 1];
            Float64  now =  [self convertTimeToSecs: AvidNote.timeStamp ] / fpsUse + startTimecode;
            
            NSLog (@"AVID Marker timecode = %@ (%g), start = %g", AvidNote.timeStamp, now, startTimecode);
            
            int row = 0;
            
            for (Note *aNote in noteData) { 
                Float64  tabTime = [self convertTimeToSecs: aNote.timeStamp];
                if ( tabTime >= now ) 
                    break;
                ++row;
            }
            
            // Insert the note into the array and table
            
            [noteData insertObject: AvidNote atIndex: row];
        }
            
        [AvidNote release];
    }
    
    // Remove downloaded file
    
    [[NSFileManager defaultManager] removeItemAtPath: [self txtFilePath] error: NULL];
    
    [notes reloadData];
    return locators;
}


-(void) getAvid: (NSString *) file
{
    NSLog (@"processing Avid import file %@", file);
	
    [FTPHelper sharedInstance].delegate = self;
    [FTPHelper sharedInstance].uname = kFTPusername;
    [FTPHelper sharedInstance].pword = kFTPpassword;    
    NSString *home = homeDir;
    
    if ( kBonjourMode )
        home = @"/Sites";
    
    NSString *urlString = [NSString stringWithFormat: @"ftp://%@%@", kFTPserver, home ];
    
    NSLog (@"Trying to download file from %@",  urlString);
    [FTPHelper sharedInstance].urlString = urlString;
    
    [FTPHelper download: [NSString stringWithFormat: @"Notes/%@", file] to: [self txtFilePath]];
    NSLog (@"Avid txt download returned...in process");  
}


#pragma mark -
#pragma mark misc

- (void) credentialsMissing
{
	NSLog (@"Please supply both user name and password before using FTP Helper");
}

- (void) progressAtPercent: (NSNumber *) aPercent;
{
	// printf("%0.2f\n", aPercent.floatValue);
}


#pragma mark -
#pragma mark PDF, email and printing

-(IBAction) printNotes
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"demo" ofType:@"jpg"];
    
    isPrinting = YES;
    [self saveToPDF];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *saveDirectory = [paths objectAtIndex:0];
    NSString *saveFileName = @"Notes.pdf";
    NSString *newFilePath = [saveDirectory stringByAppendingPathComponent:saveFileName];
    
    NSData *myData = [NSData dataWithContentsOfFile: newFilePath];
    UIPrintInteractionController *pic = [UIPrintInteractionController sharedPrintController];
    
    if ( pic && [UIPrintInteractionController canPrintData: myData] ) {
        pic.delegate = self;
        
        UIPrintInfo *printInfo = [UIPrintInfo printInfo];
        printInfo.outputType = UIPrintInfoOutputGeneral;
        printInfo.jobName = [path lastPathComponent];
        printInfo.duplex = UIPrintInfoDuplexLongEdge;
        pic.printInfo = printInfo;
        pic.showsPageRange = YES;
        pic.printingItem = myData;
        
        void (^completionHandler)(UIPrintInteractionController *, BOOL, NSError *) = ^(UIPrintInteractionController *pic, BOOL completed, NSError *error) {
            //self.content = nil;
            if (!completed && error) {
                [UIAlertView doAlert: @"Printing" 
                             withMsg: @"An error occurred trying to print"];
                NSLog(@"Failed due to error in domain %@ with error code %u", error.domain, error.code);
            } 
        };
        
        [pic presentAnimated:YES completionHandler: completionHandler];
    }
	
    isPrinting = NO;
}

-(IBAction) emailNotes
{
    NSString *emailBody;

    if (! [MFMailComposeViewController canSendMail]) {
        // Alert for saving the image or copying it to the pasteboard 
		
		[UIAlertView doAlert: @"email" 
                    withMsg: @"Your device is not setup for email"];

        return;
    }
        
    if (emailPDF) 
        [self saveToPDF];
 
    // Make sure email account is installed and available here
    
	MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
	picker.mailComposeDelegate = self;
	
	[picker setSubject: [NSString stringWithFormat: @"Notes for %@",
                [[clip stringByReplacingOccurrencesOfString: @"%20" withString:@" "]
                 stringByDeletingPathExtension], (FCPXML) ? @"(FCP XML attached)" : @"", 
                         (AvidExport) ? @"(Avid Locator file attached)" : @""]];
    
	// Set up recipients
    
	NSArray *toRecipients = [NSArray arrayWithObject: @"steve_kochan@mac.com"]; 
	NSArray *ccRecipients = [NSArray array];
	NSArray *bccRecipients = [NSArray array];
	
//	[picker setToRecipients: toRecipients];
	[picker setCcRecipients: ccRecipients];	
	[picker setBccRecipients: bccRecipients];
    
    if (FCPXML) {
        NSString *file = [self exportXML];
        
        if (file) {
            NSData *myData = [[NSData alloc] initWithContentsOfFile: file];
            [picker addAttachmentData: myData mimeType: @"text/xml" 
                             fileName: [file lastPathComponent]];
            [myData release];
        }
    }
	
    if (AvidExport) {
        NSString *file = [self exportAvid];
        
        if (file) {
            NSData *myData = [[NSData alloc] initWithContentsOfFile: file];
            [picker addAttachmentData: myData mimeType: @"text/plain" 
                             fileName: [file lastPathComponent]];
            [myData release];
        }
    }
    
	// Attach the PDF file to the email
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *saveDirectory = [paths objectAtIndex:0];
    NSString *saveFileName = @"Notes.pdf";
    NSString *newFilePath = [saveDirectory stringByAppendingPathComponent:saveFileName];
    
    if (emailPDF) {
        NSData *myData = [[NSData alloc] initWithContentsOfFile: newFilePath];
        [picker addAttachmentData:myData mimeType:@"application/pdf" fileName:@"Notes.pdf"];
        [myData release];
    }
    
	// Fill out the email body text
        
    if (emailPDF) {
        emailBody = [NSString stringWithFormat: 
                    @"Sent from VideoTree (v%@.%@), \u00A9 2010-2011 by DFT Software", 
                    [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],  [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]];
        [picker setMessageBody:emailBody isHTML:NO];
   }
    else  {
        NSString *theTitle = @"";
        
        //  NSString *theTitle = [
        //    [clip stringByReplacingOccurrencesOfString: @"_" withString: @" : "]
        //     stringByReplacingOccurrencesOfString: @"%20" withString:@" "];
        
        NSString *saveFileName = [NSString stringWithFormat: @"%@_%lu.html", initials, (long) [NSDate timeIntervalSinceReferenceDate]];
        
        NSString *fileName = [NSString stringWithFormat: @"%@/%@/Notes/%@", 
                 kHTTPserver, userDir, saveFileName]; 
        
        emailBody =  [NSString stringWithFormat: 
                       @"<html>Sent from VideoTree (v%@.%@), \u00A9 2010-2011 by DFT Software<br><p>",                         
                [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"],  
                [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]];

        if (kFTPMode && kSameServerAddress) 
            emailBody = [emailBody stringByAppendingString: 
                [NSString stringWithFormat: @"<a href=\"%@\">Click here to view this page in your browser.</a><p>%@</p>", fileName, theTitle]];

        emailBody = [emailBody stringByAppendingString: [self saveToHTML]];
        [picker setMessageBody:emailBody isHTML:YES];
        
        if (kFTPMode && kSameServerAddress) 
            [self uploadHTML: emailBody file: saveFileName];
    }
	
	[self presentModalViewController: picker animated:YES];
    [picker release];
}


// Dismisses the email composition interface when users tap Cancel or Send. Proceeds to update the message field with the result of the operation.

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error 
{
	NSString *message = @"";
    
	// Notifies users about errors associated with the interface
	switch (result)
	{
		case MFMailComposeResultCancelled:
			// message = @"Email request canceled";
			break;
		case MFMailComposeResultSaved:
			message = @"Your email has been saved";
			break;
		case MFMailComposeResultSent:
			message = @"Your email was sent";
			break;
		case MFMailComposeResultFailed:
			message = @"Your email was not sent";
			break;
		default:
			message = @"Your email was not sent";
			break;
	}
    
    // display message to user here
	[self dismissModalViewControllerAnimated:YES];
}

-(NSString *) hexFromData:(NSData *)data
{
    NSString *result = [[data description] stringByReplacingOccurrencesOfString:@" " withString:@""];
    result = [result substringWithRange:NSMakeRange(1, [result length] - 2)];
    return result;
}

- (NSString *) base64EncodedString: (NSData *) theData
{
    extern size_t EstimateBas64EncodedDataSize(size_t inDataSize);
    extern bool Base64EncodeData(const void *inInputData, size_t inInputDataSize, char *outOutputData, size_t *ioOutputDataSize);

    @try 
    {
        size_t base64EncodedLength = EstimateBas64EncodedDataSize([theData length]);
        char base64Encoded[base64EncodedLength];
        if(Base64EncodeData([theData bytes], [theData length], base64Encoded, &base64EncodedLength))
        {
            NSData* encodedData = [NSData dataWithBytes:base64Encoded length:base64EncodedLength];
            NSString* base64EncodedString = [[NSString alloc] initWithData:encodedData encoding:NSUTF8StringEncoding];
            return [base64EncodedString autorelease];
        }
    }
    @catch (NSException * e)
    {
        //do nothing
        NSLog (@"exception: %@", [e reason]);
    }
    return nil;
}

// Save a thumbnail image as a base64-encoded string to insert in the HTML stream

-(NSString *) outputImage: (Note *) theNote {
   NSString *result = [NSString stringWithFormat: @"<img width=400  src=\"data:image/jpeg;base64,%@\">", 
                       [self base64EncodedString: theNote.thumb ]];
//  NSLog (@"%@", result);
    return result;
}   

// Save the notes in HTML format

                      
-(NSMutableString *) saveToHTML {
        NSMutableString *emailBody = [NSMutableString string];
        [emailBody appendString: @"<table border=2 cellpadding=10 cellspacing=10>"];
        
        noteNumber = 1;

        for (Note *theNote in noteData) {
            [emailBody appendString: [self noteToHTML: theNote]];
            ++noteNumber;
        }
        
       [emailBody appendString: [NSString stringWithFormat: @"</table><p>Created by VideoTree(TM) %@ App. Copyright (c) 2010-2011 by DFT Software.",
            iPHONE ? @"iPhone" : @"iPad"]]; 
        
        return emailBody;
}

// Convert a single note into HTML
                      
-(NSString *) noteToHTML: (Note *) theNote {
    NSMutableString *emailBody = [NSMutableString string];
    
    // output the image
    [emailBody appendString: @"<tr align=top><td>"];
    [emailBody appendString: [self outputImage: theNote]];
    [emailBody appendString: @"</td>"];
    
    NSString *comment = [theNote.text stringByReplacingOccurrencesOfString: @"<CHAPTER>" withString: @""];
    
    if (kFTPMode && kSameServerAddress) 
        comment = [comment stringByReplacingOccurrencesOfString: @"<<<Audio Note>>>" withString: @""];
    
    comment = [[comment stringByReplacingOccurrencesOfString:  @"<" withString: @"&lt;"] stringByReplacingOccurrencesOfString: @">" withString: @"&gt;"];
    
    // output the note
    NSString *timeFormat = (timecodeFormat) ? theNote.timeStamp :
    [self timeFormat: kCMTimeMakeWithSeconds ([self convertTimeToSecs: theNote.timeStamp] - startTimecode) ];
    
    [emailBody appendString: [NSString stringWithFormat: @"<td valign=top><font color=red>%@</font>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;%@&nbsp;&nbsp;%@<p></p>%@", 
                timeFormat, theNote.date, theNote.initials, comment]];
 
    // audio -- upload to server and embed in HTML
    
    if (theNote.voiceMemo && kFTPMode && kSameServerAddress) {
        NSString *addr = [self uploadAudio: theNote];
        
        [emailBody appendString: [NSString stringWithFormat: @"<br><br><br><center><object type=\"audio/mpeg\" data=\"%@\"\
             width=\"175\" height=\"25\" alt=\"Audio link\" autoplay=false></object></center>", addr]];  

//      Following is HTML 5
//      [emailBody appendString: [NSString stringWithFormat: @"<br><br><br><center><audio src=\"%@\"></audio></center>", addr]];  
    }
     
     [emailBody appendString: @"</td></tr>"];

     return emailBody;
}

// Save the notes as a PDF file

-(void) saveToPDF
{
    // PDF file creation
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *saveDirectory = [paths objectAtIndex:0];
    NSString *saveFileName = @"Notes.pdf";
    NSString *newFilePath = [saveDirectory stringByAppendingPathComponent:saveFileName];
    NSString *pageTitle = clip;
        
    pageNumber = 1;
    noteNumber = 1;
    
    [self createPDFFile: (NSString *) newFilePath title: (NSString *) pageTitle];
    
    for (Note *aNote in noteData) {
       if (noteNumber % 4 == 1)
           [self newPDFPage: pageTitle];

       [self noteToPDF: aNote];
        
        if (noteNumber % 4 == 0) {
           CGContextEndPage (pdfContext);  
            ++pageNumber;
        }

        ++noteNumber;
    }
    
    //   [self noteToPDF: [noteData objectAtIndex: 0]];
    
    if (noteNumber % 4 != 1)
        CGContextEndPage (pdfContext);  
    
    [self closePDFFile];
}

-(void) createPDFFile: (NSString *) fileName title: (NSString *) title
{
	// This code block sets up our PDF Context so that we can draw to it
	CFStringRef path;
	CFURLRef url;
	CFMutableDictionaryRef myDictionary = NULL;
    pageRect = CGRectMake (0, 0, 612, 792);
    
	// Create a CFString from the filename we provide to this method when we call it
	path = CFStringCreateWithCString (NULL, [fileName UTF8String], kCFStringEncodingUTF8);
	// Create a CFURL using the CFString we just defined
	url = CFURLCreateWithFileSystemPath (NULL, path, kCFURLPOSIXPathStyle, 0);
	CFRelease (path);
    
	// This dictionary contains extra options mostly for 'signing' the PDF
	myDictionary = CFDictionaryCreateMutable(NULL, 0,
                &kCFTypeDictionaryKeyCallBacks,
                &kCFTypeDictionaryValueCallBacks);
	CFDictionarySetValue(myDictionary, kCGPDFContextTitle, CFSTR("Notes"));
	CFDictionarySetValue(myDictionary, kCGPDFContextCreator, CFSTR("SGK"));
    
    
	// Create our PDF Context with the CFURL, the CGRect we provide, and the above defined dictionary
	pdfContext = CGPDFContextCreateWithURL (url, &pageRect, myDictionary);
    
	// Cleanup our mess
	CFRelease(myDictionary);
	CFRelease(url);
}
    
#define inches  * 72 

-(void) newPDFPage: (NSString *) title
{
    // Starts our first page
	CGContextBeginPage (pdfContext, &pageRect);
    CGContextSetLineWidth(pdfContext, 1);
    
    currentY = pageRect.size.height;
    
	// Draws a black rectangle around the page inset by 50 on all sides
    // .75" top and bottom margins
    
	CGContextStrokeRect(pdfContext, CGRectMake(25, .78 inches, pageRect.size.width - 50, pageRect.size.height - 1.5 inches));
    
    CGContextSelectFont (pdfContext, "Helvetica", 11, kCGEncodingMacRoman);
    CGContextSetTextDrawingMode (pdfContext, kCGTextFill);
    
    // Page Title
    
    NSString *theTitle = [[title stringByReplacingOccurrencesOfString:@"_" withString:@" : "]
                          stringByReplacingOccurrencesOfString: @"%20" withString:@" "];
    const char *pageTitle = [theTitle UTF8String]; 
    
    CGContextShowTextAtPoint (pdfContext, .5 inches, pageRect.size.height - .65 inches, pageTitle, strlen(pageTitle));
    
    // Page Number
    
    const char *pageNumberString = [[NSString stringWithFormat: @"Page %i", pageNumber] UTF8String];
    CGContextShowTextAtPoint (pdfContext, pageRect.size.width - 70,
                              pageRect.size.height - .65 inches, pageNumberString, strlen(pageNumberString));
    currentY = pageRect.size.height - .78 inches;
    
    // Page footer
    
    // Logo
    
    UIImage *ui = [UIImage imageNamed: @"videotree_icon3.png"];
    CGImageRef ref = CGImageRetain(ui.CGImage);
    CGContextDrawImage (pdfContext, CGRectMake(30, .6 inches, CGImageGetWidth (ref) / 5, CGImageGetHeight (ref) / 5), ref);
    CGImageRelease (ref);
    
    // Text
    
    CGContextSelectFont (pdfContext, "Helvetica-Oblique", 9, kCGEncodingMacRoman);
    char *text;
    
    if (iPHONE)
        text = "Created by VideoTree(TM) iPhone App.  Copyright \251 2010-2011 by DFT Software.";
    else
        text = "Created by VideoTree(TM) iPad App.  Copyright \251 2010-2011 by DFT Software.";

    CGContextShowTextAtPoint (pdfContext, 25 + CGImageGetWidth (ref) / 5 + 15, .65 inches, text, strlen(text));
//  text = "VideoTree is a trademark of DFT Software.";
//  CGContextShowTextAtPoint (pdfContext, 25 + CGImageGetWidth (ref) / 5 + 15, .65 inches - 10, text, strlen(text));
}


-(void) uploadHTML: (NSString *) theHTML file: (NSString *) fileName
{
    // Save the audio file and upload to the server
    NSArray *dirList = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDir = [dirList objectAtIndex: 0];
    
    NSString *HTMLPath = [docDir stringByAppendingPathComponent: fileName];
    
    if (! [theHTML writeToFile: HTMLPath atomically: NO encoding: NSUTF8StringEncoding error: NULL]) 
        NSLog (@"Save of HTML file failed!");
    
    [FTPHelper sharedInstance].delegate = self;
    [FTPHelper sharedInstance].uname = kFTPusername;
    [FTPHelper sharedInstance].pword = kFTPpassword;    
    NSString *urlString = [NSString stringWithFormat: @"ftp://%@", kFTPserver];
    
    NSLog (@"Saving file %@ to %@", HTMLPath, urlString);
    [FTPHelper sharedInstance].urlString = urlString;
    
    [FTPHelper upload: HTMLPath];
    NSLog2 (@"upload returned...in process");
}

-(NSString *) uploadAudio: (Note *) aNote
{
    // Save the audio file and upload to the server
    NSArray *dirList = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *docDir = [dirList objectAtIndex: 0];
    
    NSString *fileName = [NSString stringWithFormat: @"%@_%i_%@.%@", 
                          [clip stringByDeletingPathExtension], noteNumber, initials, emailPDF ? @"mov.aac" : @"aac"];  // DUH!
    NSLog (@"Audio file name = %@", fileName);
    NSString *audioPath = [docDir stringByAppendingPathComponent: fileName];
    
    if (! [aNote.voiceMemo writeToFile: audioPath atomically: NO]) 
        NSLog (@"Save of audio file failed!");
    
    [FTPHelper sharedInstance].delegate = self;
    [FTPHelper sharedInstance].uname = kFTPusername;
    [FTPHelper sharedInstance].pword = kFTPpassword;    
    NSString *urlString = [NSString stringWithFormat: @"ftp://%@", kFTPserver];
    
    NSLog (@"Saving file %@ to %@", audioPath, urlString);
    [FTPHelper sharedInstance].urlString = urlString;
    
    [FTPHelper upload: audioPath];
    NSLog2 (@"upload returned...in process");
    
    return [NSString stringWithFormat: @"%@/%@/Notes/audio/%@", 
            kHTTPserver, userDir, fileName]; 
}

-(void) noteToPDF: (Note *) aNote {
    const char *noteText = [[aNote.text stringByReplacingOccurrencesOfString: @"<CHAPTER>" withString: @""] UTF8String];
    
    NSString *timeFormat = (timecodeFormat) ? aNote.timeStamp :
        [self timeFormat: 
           kCMTimeMakeWithSeconds ([self convertTimeToSecs: aNote.timeStamp] - startTimecode) ];
    
    const char *noteTime = [timeFormat UTF8String];
    char date [100];
    const char *who = [aNote.initials UTF8String];

    strcpy (date, [aNote.date UTF8String]);
    
#ifdef OLDSTUFF
    AVAssetImageGenerator *imageGen = [[AVAssetImageGenerator alloc] initWithAsset: [[player currentItem] asset]];
    
    if (!imageGen)
        NSLog (@"AVAssetImageGenerator failed!");

    [imageGen setMaximumSize: CGSizeMake (250., 150.)];
    [imageGen setAppliesPreferredTrackTransform:YES];
    
    Float64 secs = [self convertTimeToSecs: aNote.timeStamp];
    CGImageRef imageRef = [imageGen copyCGImageAtTime: kCMTimeMakeWithSeconds(secs) 
                            actualTime: NULL error: NULL];
    
    int wid = CGImageGetWidth (imageRef) + CGImageGetWidth (imageRef) % 8;
    int ht = CGImageGetHeight (imageRef) + CGImageGetHeight (imageRef) % 8;
    
    CGRect thumbRect = { 
        {0.0f, 0.0f}, 
        {(float) wid, (float) ht}
    };
    
    CGImageAlphaInfo	alphaInfo = CGImageGetAlphaInfo(imageRef);
        
    CGContextRef bitmap = CGBitmapContextCreate(
            NULL,
            thumbRect.size.width,		// width
            thumbRect.size.height,		// height
            CGImageGetBitsPerComponent(imageRef),	
            4 * thumbRect.size.width,	// rowbytes
            CGImageGetColorSpace(imageRef),
            alphaInfo
    );

    if (alphaInfo == kCGImageAlphaNone)
        alphaInfo = kCGImageAlphaNoneSkipLast;
    
    // Draw into the context, this scales the image
    CGContextDrawImage(bitmap, thumbRect, imageRef);
    
    drawView.myDrawing = aNote.drawing;
    drawView.colors = aNote.colors;
    [self drawMarkups: bitmap width: thumbRect.size.width height: thumbRect.size.height];
    
    CGImageRef	ref = CGBitmapContextCreateImage(bitmap);
    CGContextDrawImage (pdfContext, CGRectMake(40, currentY - 155, thumbRect.size.width, thumbRect.size.height), ref);
    CGImageRelease (imageRef);
    CGImageRelease (ref);
    CGContextRelease (bitmap);	// ok if NULL
    [imageGen release];
    
#else
    CGContextDrawImage (pdfContext, CGRectMake (40, currentY - 155, 250, 150), [UIImage imageWithData: aNote.thumb].CGImage);
#endif
    
    CGContextSelectFont (pdfContext, "Helvetica-Bold", 12, kCGEncodingMacRoman);
    CGContextSetRGBFillColor (pdfContext, 1, 0, 0, 1);
    CGContextShowTextAtPoint (pdfContext, 330, currentY - 20, noteTime, strlen(noteTime));
    
    CGContextSelectFont (pdfContext, "Helvetica", 12, kCGEncodingMacRoman);
    CGContextSetRGBFillColor (pdfContext, 0, 0, 1, 1);
 
    char *dateInitials = strcat (strcat (date, "   "), who);
	CGContextShowTextAtPoint (pdfContext, 490, currentY - 20, dateInitials, strlen(dateInitials));
    CGContextSetRGBFillColor (pdfContext, 0, 0, 0, 1);
 
    CGContextShowMultilineText (pdfContext, noteText, currentY - 40);
    
    if (aNote.voiceMemo && kFTPMode && !isPrinting) {
        NSURL *addr = [NSURL URLWithString: [self uploadAudio: aNote]];
                       
        CGPDFContextSetURLForRect (pdfContext, (CFURLRef) addr, CGRectMake (330, currentY - 140, 100.0, 20.0));
        CGContextSetRGBFillColor (pdfContext, 0, 0, 1, 1);
        CGContextShowTextAtPoint (pdfContext, 330, currentY - 140, "Click to Hear Note", strlen("Click to Hear Note"));
    }

    if (noteNumber % 4) {
        // Draws a line separator for the note
        CGContextMoveToPoint (pdfContext, 25, currentY - 165);
        CGContextAddLineToPoint (pdfContext, pageRect.size.width - 25, currentY - 165);
        CGContextStrokePath (pdfContext);
    }
    currentY -= 170;
}
     
-(void) closePDFFile
{     
     // We are done with our context now, so we release it
    CGContextRelease (pdfContext);
}

void CGContextShowMultilineText (CGContextRef pdfContext, const char *noteText, int curY)
{
    static CGFloat  leftMargin = 330;
    static CGFloat  rightMargin = 560;
    CGPoint         whereTo;
    CGPoint         currentPoint = {leftMargin, curY};
    int             i, numChars = strlen (noteText), wordSize;

    CGContextSetTextPosition (pdfContext, currentPoint.x, currentPoint.y);

    i = 0;
    int saveI;
    
    while (i < numChars) {        
        while (noteText[i] == '\n' || noteText[i] == '\r') {
            currentPoint.x = leftMargin;
            currentPoint.y -= 15;
            ++i;
        }
        
        saveI = i;
        
        while ((isalnum (noteText[i]) || ispunct (noteText[i])))
            ++i;
        
        if ( i == saveI )
            ++i;
        
        wordSize = i - saveI;
         
        CGContextSetTextDrawingMode (pdfContext, kCGTextInvisible);
        CGContextShowText (pdfContext, &noteText [saveI], wordSize);
        whereTo = CGContextGetTextPosition (pdfContext);
        
        if (whereTo.x > rightMargin) {
            currentPoint.x = leftMargin;
            currentPoint.y -= 15;

            while (isspace (noteText[saveI])) 
                ++saveI;
        }
        
        wordSize = i - saveI;
        
        CGContextSetTextPosition (pdfContext, currentPoint.x, currentPoint.y);
        CGContextSetTextDrawingMode (pdfContext, kCGTextFill);
        CGContextShowText (pdfContext, &noteText [saveI], wordSize);
        currentPoint = CGContextGetTextPosition (pdfContext);
    }
}    

#if 0
// Displays an email composition interface inside the application. Populates all the Mail fields. 
-(IBAction) emailNotes 
{
    if (!player || [noteData count] == 0)
    return;

    if (player.rate != 0)
        [self pauseIt];  
    
    NSLog (@"emailing notes");
    
    NSArray *keys = [NSArray arrayWithObject: @"tracks"];
    
    [player.currentItem.asset loadValuesAsynchronouslyForKeys:keys completionHandler:
      ^(void) {
          NSError *error = nil;
          
          switch (tracksStatus) {
              case AVKeyValueStatusLoaded: 
                  NSLog (@"tracksStatus loaded");
                  [self emailTheNotes];
                  break;
              case AVKeyValueStatusFailed:
                  break;
              case AVKeyValueStatusCancelled:
                  break;
          }
      }
     ];
}
#endif
         
#pragma mark -
#pragma mark scrubber

// Format the time either in timecode or absolute frame format

- (NSString *) timeFormat: (CMTime) aTime
{
    NSString *time1;
    Float64 secs = CMTimeGetSeconds (aTime);
    int theFPS = (fps < .1) ? 24 : (int) (fps + .4999);  // *****

    if (timecodeFormat) {
        int hours = secs / 3600;
        int mins = (secs - hours * 3600) / 60;
        int theSecs = (int) (secs + .0001) % 60;
        int frames = (int) ((secs - (int) secs) * theFPS + .01) % theFPS;
        
        if (mins < 0)
            return (@"00:00:00:00");
                                
        time1 = [NSString stringWithFormat: @"%.2i:%.2i:%.2i:%.2i", hours, mins, theSecs, frames];
    }
    else {
        long frames  =  secs * theFPS + (secs - (long) secs) * theFPS;
                        
        if (frames <= 0)
            time1 = @"0";
        else {
            time1 = [NSString stringWithFormat: @"%li", frames];
            // NSLog (@"time = %g, frame = %@, fps = %i", secs, time1, theFPS);
        }
    }
    
    return time1;
}

-(Float64) convertTimeToSecs: (NSString *) timeStamp
{
    Float64 secs = NAN;
    NSArray *timeSpot = [timeStamp componentsSeparatedByString:@":"];
    float theFPS = (fps != 0.0) ? fps : 24;

    if ([timeSpot count] == 3) {
        secs = [[timeSpot objectAtIndex:0] floatValue] * 60 + 
        [[timeSpot objectAtIndex:1] floatValue] + 
        [[timeSpot objectAtIndex:2] floatValue] / theFPS;
    }
    else if ([timeSpot count] == 4){
        secs = [[timeSpot objectAtIndex:0] floatValue] * 3600 + 
        [[timeSpot objectAtIndex:1] floatValue] * 60 + [[timeSpot objectAtIndex:2] floatValue] +
            [[timeSpot objectAtIndex:3] floatValue] / theFPS;
    }
    
    return secs;
}

-(NSString *) formatDate: (BOOL) includeTime
{
    NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    // [dateFormatter setTimeStyle:NSDateFormatterFullStyle];
    
    if (!includeTime)
        [dateFormatter setTimeStyle: NSDateFormatterNoStyle];
    else
        [dateFormatter setTimeStyle: NSDateFormatterLongStyle];
    
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];

    [dateFormatter setLocale:[NSLocale currentLocale]];
    
    return [dateFormatter stringFromDate: [NSDate date]];
}

- (void)updateTimeLabel
{
    Float64 curtime = (timecodeFormat) ?
        kCVTime ([player currentTime]) + startTimecode :
        kCVTime ([player currentTime]);
    
    theTime.text = [self timeFormat: kCMTimeMakeWithSeconds (curtime)];
}

static int saveRate;

- (void)sliderDragBeganAction
{
	isSeeking = YES;
    saveRate = player.rate;

    player.rate = 0;
    seekToZeroBeforePlay = NO;
    newNote.text = @"";
    [self erase];
}

- (void)sliderDragEndedAction
{
	isSeeking = NO;
    player.rate = saveRate;
    
    if (player.rate != 0)
        pausePlayButton.image = pauseImage;
    else
        pausePlayButton.image = pauseImage;
}

- (void)sliderValueChange
{
    Float64 playerTime = movieTimeControl.value * kCVTime ([[[player currentItem] asset] duration]); 
    
 	[player seekToTime: kCMTimeMakeWithSeconds(playerTime)];
}


- (void) updateTimeControl
{
    AVAsset *asset = [[player currentItem] asset];

    if (!asset)
		return;
    
    if (fps < 0.001) {
        NSArray *tracks = [asset tracks];
        
        NSLog2 (@"[tracks count] == %i, %@", [tracks count], tracks);

        if ([tracks count] > 0) {
            NSArray *tracks = [asset tracksWithMediaType: AVMediaTypeVideo];
            
            if ([tracks count] > 0) {
                fps = [[tracks objectAtIndex: 0] nominalFrameRate];

                if (fps > 0.0) 
                    NSLog (@"fps = %f", fps);
            }
         }
        
        if (! kFTPMode) {
            NSLog (@"trying to read start time code");
            startTimecode = [self getStartTimecode];
        }
        

        if (fps == 0) {
            [self cleanup];
            [UIAlertView doAlert:  @"Error" withMsg:
                 @"Trouble playing the movie--you may not have permission"];
        
            return;
        }
	}

    double duration;
        
    if (!durationSet) {
        endOfVid = player.currentItem.asset.duration; // [asset duration];
	    duration = kCVTime (endOfVid);
        
        Float64 theEnd = duration;
        
        if (timecodeFormat)
            duration += startTimecode;

        if (isfinite(duration))
        {
            if (!maxLabelSet) {
                maxLabel.text = [self timeFormat: kCMTimeMakeWithSeconds(theEnd)];
             NSLog (@"Setting duration to %@ (duration = %@ - %@ %lg, end = %lg)", maxLabel.text, 
                [self timeFormat: kCMTimeMakeWithSeconds(duration)],  [self timeFormat: endOfVid], duration, theEnd);
                
                if (timecodeFormat)
                    minLabel.text = [self timeFormat: kCMTimeMakeWithSeconds(startTimecode)];
                else
                    minLabel.text = @"1";
                
                maxLabelSet = YES;
            }
            
            durationSet = YES;
        }
    }
    else
        duration = kCVTime (endOfVid);
                    
    Float64 time = kCVTime([player currentTime]);
     
    movieTimeControl.value = (float) (time / duration);

    // [self timeStats];
        
    // Scroll the notes table in time with the video clip
    
    if ([noteData count] == 0 || player.rate == 0.0)
        return;
    
    Float64 now = kCVTime ([player currentTime]) + startTimecode;
    
    int row = 0;
    
    for (Note *theNote in noteData) {
        if ([self convertTimeToSecs: theNote.timeStamp] > now)
            break;
        ++row;
    }
    
    if (row < [noteData count]) {
        NSIndexPath *indexP = [NSIndexPath indexPathForRow: row inSection:0];
        
        @try  {
            [notes selectRowAtIndexPath: indexP animated: YES scrollPosition: UITableViewScrollPositionTop];
        }
        @catch (NSException *exception) {
            NSLog (@"race condition with tableview");
        }

    }
}

#pragma mark -
#pragma mark video management

-(Float64) getStartTimecode
{
    if (!player)
        return 0.0;
            
    NSArray *tcTracks = [player.currentItem.asset tracksWithMediaType:AVMediaTypeTimecode]; 
    
    if (![tcTracks count]) {
        NSLog (@"no timecode track");
        return 0.0;
    }
        
    NSError *error;

    AVAssetReader *assetReader = [[AVAssetReader alloc] initWithAsset: player.currentItem.asset error: &error];
    
    if (error) {
        NSLog (@"error initializing AVAssetReader: %@", error);
        [assetReader release];
        return 0.0;
    }
 
    AVAssetTrack *tcTrack = [tcTracks objectAtIndex: 0];
    AVAssetReaderTrackOutput *assetReaderOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack: tcTrack outputSettings: nil];
  
    [assetReader addOutput: assetReaderOutput];        
    if (! [assetReader startReading]) {
        NSLog (@"Can't start assetReader");
        [assetReader cancelReading];
        [assetReader release];
        [assetReaderOutput release];
        return 0.0;
    }
            
    CMSampleBufferRef buffer;
    
    NSLog (@"assetReader status = %i", [assetReader status]);
    
    while ( [assetReader status] == AVAssetReaderStatusReading || [assetReader status] == AVAssetReaderStatusUnknown ) {
        buffer = [assetReaderOutput copyNextSampleBuffer];
        
        long out;
        
        if (buffer) {  
            NSLog (@"asset reader buffer = %lx, buffer size = %li",  CMSampleBufferGetDataBuffer (buffer), (long) CMSampleBufferGetSampleSize (buffer, 0));
            CMBlockBufferCopyDataBytes (CMSampleBufferGetDataBuffer (buffer), 0, 4, &out);
            
            if (fps < .001)
                fps = 24;
            
            int32_t fpsUse = fps + .5; 
            Float64 timecode = EndianS32_BtoN(out) / (float) fpsUse;
            
            CMTime aTime = kCMTimeMakeWithSeconds(timecode);
            NSLog (@"output data = %@", [self timeFormat: aTime]);
            
            [assetReader cancelReading];
            [assetReader release];
            [assetReaderOutput release];
            return timecode;
        }
    }
    
     NSLog (@"getStartTimecode returning 0.0");
    [assetReader cancelReading];
    [assetReader release];
    [assetReaderOutput release];
    return 0.0;
}

-(void) timeStats
{
    CMTime currentTime = player.currentTime;
    CMTime endTime = CMTimeConvertScale (player.currentItem.asset.duration,
                                             currentTime.timescale,
                                             kCMTimeRoundingMethod_RoundHalfAwayFromZero);

    NSLog (@"** stats: current time = %@, value = %lu, timescale = %lu, endtime = %@, RTP = %i", 
        [self timeFormat: currentTime], (long) currentTime.value, (long) (currentTime.timescale), 
        [self timeFormat: endTime], (player.currentItem != nil) &&
           ([player.currentItem status] == AVPlayerItemStatusReadyToPlay));
}

-(void) cleanup
{
        if (!player)
            return;

        NSLog (@"cleaning up");

        [player removeObserver: self forKeyPath:@"rate"];
        [player removeObserver: self forKeyPath:@"currentItem.status"];
        [player removeObserver: self forKeyPath:@"currentItem.asset.duration"];
        [player removeObserver: self forKeyPath:@"currentItem.asset.commonMetadata"];
        [self stopObservingTimeChanges];

        player.rate = 0;
    
        [self pauseIt];
        [self stopActivity];
        [self noteStopActivity];

        if (!autoPlay && fullScreenMode)
            [self leaveFullScreen: nil];
        
       if (airPlayMode && !runAllMode && !autoPlay)
           [self airPlay];
        else    
            [self movieControllerDetach];

        [self clearAnyNotes];
        [self erase];
        [drawView setNeedsDisplay];
        self.playerLayer.player = nil; // this is the trick !
        [self.playerLayer removeFromSuperlayer];
        self.playerLayer = nil;
        self.currentlyPlaying = nil;
        player = nil;

        if ([voiceMemo audioRecorder].isRecording)            
            [voiceMemo stopRecording];
    
        recording.hidden = YES;
        fps = 0;
        isPrinting = NO;

        movieTimeControl.value = 0;
        durationSet = NO;
        theTime.text = [self timeFormat: kCMTimeZero];
        newNote.text = @"";
        maxLabelSet = NO;  
        startTimecode = 0.0;
        reTryCount = 0;
        maxLabel.text = [self timeFormat: kCMTimeZero];
        minLabel.text = [self timeFormat: kCMTimeZero];
}

- (void)loadMovie: (id) theMovie
{
    editButton.title = @"Edit";

    if (player) 
        [self cleanup];
    else
        [self erase];
    
    if (iPHONE) {
        UINavigationController  *nc = [(VideoTreeAppDelegate *) [[UIApplication sharedApplication] delegate] nc];
        nc.view.hidden = YES;
    }
    
    self.currentlyPlaying = [theMovie retain];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                name:AVPlayerItemDidPlayToEndTimeNotification  object:nil];

    if ([theMovie isKindOfClass: [NSString class]]) {
        NSRange network = [theMovie rangeOfString: @"http:"];
        if (network.location == NSNotFound)
            network = [theMovie rangeOfString: @"https:"];
        if (network.location == NSNotFound)
            network = [theMovie rangeOfString: @"file:"];
        
        if (network.location == NSNotFound) {
            NSLog (@"Loading movie %@", theMovie);
            
            if ([theMovie rangeOfString: @"Simulator"].location != NSNotFound)
                movieURL = [[NSURL alloc] initFileURLWithPath: [[NSBundle mainBundle] pathForResource: @"31-1A" ofType:@"m4v"]];
            else
                movieURL = [[NSURL alloc] initFileURLWithPath: theMovie];
            
        }
        else {
            NSLog (@"Loading movie %@ from Internet or camera roll", theMovie);
            self.movieURL = [NSURL URLWithString: theMovie];
        }
    }
    else
         self.movieURL = theMovie;
    
#if 0
    NSError *error;
    
    if ([movieURL checkResourceIsReachableAndReturnError: &error] == NO) 
        NSLog (@"Can't load from the URL: %@", error);  // Display an alert here
#endif
    
    if (! movieURL) 
        return;

    self.clip = [theMovie lastPathComponent];
 
    [self showActivity];

    // Load the notes table
    
    if (kFTPMode)
        [self getAllFTPNotes];
    else {
        [self loadData: initials];
    }
    
    // Create the movie asset and get the tracks keys
    
    NSMutableDictionary *optionsDict = [NSMutableDictionary dictionaryWithObjectsAndKeys: 
            [NSNumber numberWithBool: YES], AVURLAssetPreferPreciseDurationAndTimingKey, nil];
    self.theAsset = [AVURLAsset URLAssetWithURL: movieURL options: optionsDict];
    NSString *tracksKey = @"tracks";
    
    [theAsset loadValuesAsynchronouslyForKeys:[NSArray arrayWithObject:tracksKey] completionHandler:
     ^{ 
        NSLog2 (@"completion handler");
        NSError *error = nil; 

        AVKeyValueStatus status = [theAsset statusOfValueForKey:tracksKey error:&error];
       
        if (status != AVKeyValueStatusLoaded) 
            self.playerItem = [AVPlayerItem playerItemWithURL: movieURL]; 
        else 
            self.playerItem = [AVPlayerItem playerItemWithAsset: theAsset];
            
        self.player = [AVPlayer playerWithPlayerItem:playerItem];

        if (player && playerItem)
        {
            [[NSNotificationCenter defaultCenter]
                 addObserver:self
                 selector:@selector(itemDidPlayToEnd:)
                 name:AVPlayerItemDidPlayToEndTimeNotification
                 object:playerItem];
            
            seekToZeroBeforePlay = NO;
            
            if (kRunningOS5OrGreater)
                [player setAllowsAirPlayVideo: YES];
            
            [player addObserver:self forKeyPath:@"rate" options: NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context: VideoTreeViewControllerRateObservationContext];
            
            if (kRunningOS5OrGreater) {
                [player addObserver:self forKeyPath:@"airPlayVideoActive" options: NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context: VideoTreeViewControllerAirPlayObservationContext];
            }
            
            [player addObserver:self forKeyPath:@"currentItem.status" options: NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context: VideoTreeViewControllerStatusObservationContext];
            [player addObserver:self forKeyPath:@"currentItem.asset.duration" options: NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context: VideoTreeViewControllerDurationObservationContext];
            [player addObserver:self forKeyPath:@"currentItem.asset.commonMetadata" options: NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context: VideoTreeViewControllerCommonMetadataObserverContext];           
//          [player addObserver:self forKeyPath:@"currentItem.timedMetadata" options: NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:VideoTreeViewControllerTimedMetadataObserverContext];
//			[playerItem addObserver:self forKeyPath:@"currentItem.seekableTimeRanges" options:NSKeyValueObservingOptionInitial context:VideoTreeViewControllerSeekableTimeRangesObserverContext];

            self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:player]; 
            [player release];

            playerLayerView.hidden = NO;
            playerLayer.frame = playerLayerView.layer.bounds;
            [playerLayerView.layer addSublayer:playerLayer];
            playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;  // maintain aspect ratio
            
            if (watermark) {
  //            [playerLayerView bringSubviewToFront: stampLabel];
                self.stampLabel.hidden = NO;
            }
            else
                self.stampLabel.hidden = YES;

            [playerLayerView addSubview:drawView];
            [playerLayerView bringSubviewToFront: drawView];
            
            if (kRunningOS5OrGreater) {
                NSLog (@"setting up player, airPlayVideoActive = %i", [player isAirPlayVideoActive]);
            
                if ([player isAirPlayVideoActive])
                    airPlayImageView.hidden = NO;
                else
                    airPlayImageView.hidden = YES;
            }
        }
        else
            NSLog (@"Failed to initiliaze the movie player!");
 
#if 0
        NSLog2 (@"playLayerView frame origin = (%g, %g), drawView frame origin = (%g, %g)",
               playerLayerView.frame.origin.x, playerLayerView.frame.origin.y,
               drawView.frame.origin.x, drawView.frame.origin.y);
        NSLog2 (@"playLayerView wid, ht = (%g, %g), drawView wid, ht = (%g, %g)",
               playerLayerView.frame.size.width, playerLayerView.frame.size.height,
               drawView.frame.size.width, drawView.frame.size.height);
        
        NSLog2 (@"playLayerView bounds origin = (%g, %g), drawView bounds origin = (%g, %g)",
               playerLayerView.bounds.origin.x, playerLayerView.bounds.origin.y,
               drawView.bounds.origin.x, drawView.bounds.origin.y);
        NSLog2 (@"playLayerView  bounds wid, ht = (%g, %g), drawView  bounds wid, ht = (%g, %g)",
               playerLayerView.bounds.size.width, playerLayerView.bounds.size.height,
               drawView.bounds.size.width, drawView.bounds.size.height);
        NSLog2 (@"common metadata formats = %@", player.currentItem.asset.availableMetadataFormats);
        NSLog2 (@"common metadata = %@", player.currentItem.asset.commonMetadata);
         
         for (NSString *meta in player.currentItem.asset.availableMetadataFormats) 
             NSLog2 (@"*** %@", meta, [player.currentItem.asset metadataForFormat: meta]);
         
         NSLog2 (@"loaded time ranges = %@", player.currentItem.loadedTimeRanges);  
         
 //      player.currentItem.reversePlaybackEndTime = kCMTimeMakeWithSeconds(10.0);
 //      player.currentItem.forwardPlaybackEndTime = kCMTimeMakeWithSeconds(25.0);
         NSLog2 (@"reverse playback end time = %@", [self timeFormat: player.currentItem.reversePlaybackEndTime]); 
         NSLog2 (@"forward playback end time = %@", [self timeFormat: player.currentItem.forwardPlaybackEndTime]);
         NSLog2 (@"timed metadata = %@", player.currentItem.timedMetadata); 
#endif

         NSLog (@"playbackLikelyToKeepUp = %i", player.currentItem.isPlaybackLikelyToKeepUp);
//       NSLog (@"%@, %@", playerItem.asset.commonMetadata, playerItem.timedMetadata);
         
//         NSLog (@"%@, %@, %lu, %lu", player, player.currentItem, player.currentItem.asset.duration.value, player.currentItem.asset.duration.timescale);

         [self updateTimeControl];
         
         if (airPlayMode) 
             [self airPlayWork];
    } ];
}


- (void)syncPlaybackButton {
//    NSLog (@"syncPlaybackButton");

    if ((player.currentItem != nil) &&
        ([playerItem status] == AVPlayerItemStatusReadyToPlay)) {
        if (![movieController.view isDescendantOfView: playerLayerView])
            pausePlayButton.enabled = YES;
            recordButton.enabled = YES;
        
        [self startObservingTimeChanges];
        
        if (activityIndicator.isAnimating)
            [self stopActivity];
 
        if (player.rate == 0.0 && ! theTimer)
            pausePlayButton.image = playImage;
        
 //     NSLog (@"Has protected content = %i, limitReadAhead = %i", [[playerItem asset] hasProtectedContent], [playerItem limitReadAhead]);
    }
    else {
        pausePlayButton.enabled = NO;
        recordButton.enabled = NO;
    }
}

-(IBAction) airPlay
{
    [UIView animateWithDuration: .3 animations: ^{ 
        remote.alpha = 0;
    }];

    runAllMode = NO;
    
    if (! airPlayMode)  {   // Turn on airPlay mode if off
        [self airPlayWork];
        return;
    }

    // Turn off airPlay mode and return to normal screen
    
    [self movieControllerDetach];
    
    theTime.hidden = NO;
    backgroundLabel.hidden = NO;
    drawingBar.hidden = NO;
    movieTimeControl.hidden = NO;
    maxLabel.hidden = NO;
    minLabel.hidden = NO;
    pausePlayButton.enabled = YES;
    
    skipForwardButton.enabled = YES;
    skipBackButton.enabled = YES;
    skipForwardButton.title = [NSString stringWithFormat: @"+%i", skipValue];
    skipBackButton.title = [NSString stringWithFormat: @"-%i", skipValue];
    
    rewindToStartButton.enabled = YES; 
    frameBackButton.enabled = YES; 
    frameForwardButton.enabled = YES; 
    forwardToEndButton.enabled = YES; 
    fullScreenButton.enabled = YES;
    rewindButton.enabled = YES;
    fastForwardButton.enabled = YES;
//  myVolumeView.hidden = YES;
    
    if (watermark) {
        [playerLayerView addSubview: stampLabel];
        [playerLayerView bringSubviewToFront: stampLabel];
    }
    
    airPlayMode = NO;
}


-(void) airPlayWork
{
    NSLog (@"airPlayWork: airPlayMode = %i", airPlayMode);
    
    [self pauseIt];
    [self movieControllerDetach];
    
    self.movieController = [[[MPMoviePlayerController alloc] initWithContentURL: movieURL] autorelease];

    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(MPPlayerDone:)                                                 
                                                 name:MPMoviePlayerPlaybackDidFinishNotification object: movieController];    
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(MPPlayerDone:) 
                                                 name:MPMoviePlayerDidExitFullscreenNotification object: movieController];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(changeState:) 
                                                 name:MPMoviePlayerLoadStateDidChangeNotification object: movieController];
        
    [movieController prepareToPlay];   
    movieController.shouldAutoplay = NO;

    theTime.hidden = YES;
    backgroundLabel.hidden = YES;
    drawingBar.hidden = YES;
    movieTimeControl.hidden = YES;
    maxLabel.hidden = YES;
    minLabel.hidden = YES;
    rewindToStartButton.enabled = NO; 
    frameBackButton.enabled = NO; 
    frameForwardButton.enabled = NO; 
    forwardToEndButton.enabled = NO; 
    fullScreenButton.enabled = NO;
    rewindButton.enabled = NO;
    fastForwardButton.enabled = NO;
    pausePlayButton.enabled = NO;

    skipForwardButton.enabled = NO;
    skipBackButton.enabled = NO;
    skipForwardButton.title = @"";
    skipBackButton.title = @"";
    
//  myVolumeView.hidden = NO;

#ifdef DVDSUPPORT
    if (runAllMode) {
        [self updateClipLabels];

        [UIView animateWithDuration: .3 animations: ^{ 
            remote.alpha = 1;
            [self.view bringSubviewToFront: remote];
        }];
    }
#endif

#ifdef iOS42   
    @try  {
        [movieController setAllowsWirelessPlayback:YES];
    }
    @catch (NSException *exception) 
#endif
    {
        movieController.allowsAirPlay = YES;
    }
    
    NSLog (@"set allows AirPlay");
    movieController.controlStyle = MPMovieControlStyleEmbedded;
        
    [movieController setFullscreen: NO animated: YES];
    movieController.view.frame = [playerLayerView bounds];
    [playerLayerView addSubview: movieController.view];
    
    if (watermark) {
        [movieController.view addSubview: stampLabel];
    }
    
    airPlayMode = YES;
    [movieController play];
}  

-(void) movieControllerDetach
{
    if (movieController) {
        [movieController.view removeFromSuperview];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                        name:MPMoviePlayerPlaybackDidFinishNotification object: movieController]; 
        
        [[NSNotificationCenter defaultCenter] removeObserver:self 
                        name:MPMoviePlayerDidExitFullscreenNotification object: movieController]; 
        
        [[NSNotificationCenter defaultCenter] removeObserver:self 
                        name:MPMoviePlayerLoadStateDidChangeNotification object: movieController];
                
        [movieController stop];
        self.movieController = nil;
    }
}

-(BOOL) nextClip
{
    DetailViewController *dc =  [ kAppDel tvc];
    
    NSLog (@"autoplay next clip");
    return [dc nextClip];
}

-(void) MPPlayerDone: (NSNotification *) aNotification {
    NSLog (@"MPPlayerDone: %i", [[aNotification.userInfo objectForKey: 
                        MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] integerValue]);
    
    if (autoPlay && [aNotification.name isEqualToString: MPMoviePlayerPlaybackDidFinishNotification]  
        && [[aNotification.userInfo objectForKey: 
             MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] integerValue] 
                    == MPMovieFinishReasonPlaybackEnded) {
            if (movieController) {
              [self movieControllerDetach];
              [self nextClip];
            }
        }
}

-(void) changeState: (NSNotification*) aNotification {
    MPMoviePlayerController *thePlayer = [aNotification object];
    
    NSLog (@"Movie player changed state: %i", thePlayer.loadState);
    
    if (thePlayer.loadState & MPMovieLoadStateUnknown) 
        NSLog (@"mpmovieplayercontroller status is unknown");
    else if (thePlayer.loadState & MPMovieLoadStatePlayable)         
        NSLog (@"mpmovieplayercontroller movie is playable");
    else if (thePlayer.loadState &  MPMovieLoadStateStalled)
        NSLog (@"mpmovieplayercontroller status is stalled");;
        
// MPMovieLoadStatePlaythroughOK:
}

-(IBAction) showNav
{
    UINavigationController  *nc = [kAppDel nc];
    nc.view.hidden = NO;
    [[kAppDel rootTvc] makeList];
}

- (IBAction)showHelp {
    HelpScreenController *help = [[HelpScreenController alloc] initWithNibName: 
            (iPHONE) ? @"HelpScreenControlleriPhone" : @"HelpScreenController" bundle: nil];
    
    help.view.backgroundColor = [UIColor clearColor];
    self.modalPresentationStyle = UIModalPresentationCurrentContext;
    help.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    [self presentModalViewController:help animated: YES];
    [help release];
}

// FullScreen support using AVPlayer

-(IBAction) fullScreen
{    
    if (!player)
        return;
    
    [self pauseIt];
    [self erase];
    
    if (! iPHONE) {
        [[UIApplication sharedApplication] setStatusBarHidden: YES 
            withAnimation: UIStatusBarAnimationFade];
        
        UINavigationController  *nc = [(VideoTreeAppDelegate *) [[UIApplication sharedApplication] delegate] nc];
        nc.view.hidden = YES;
    }
    
    [UIView animateWithDuration: .3 animations: ^{ 
        playerLayerView.frame = CGRectMake (0.0, 0.0, [UIScreen mainScreen].applicationFrame.size.height, [UIScreen mainScreen].applicationFrame.size.width);
        playerLayer.frame = playerLayerView.frame;
    }];
        
    fullScreenMode = YES;
    notes.hidden = YES;
    notePaper.hidden = YES;
    
    newNote.hidden = YES;
    theTime.hidden = YES;
    backgroundLabel.hidden = YES;
    stampLabel.hidden = YES;
    noteBar.hidden = YES;
    myVolumeView.hidden = YES;
    drawingBar.hidden = YES;
    volLabel.hidden = YES;
    
    if (watermark && !stampLabelFull) {
        CGRect stampFrame = playerLayerView.frame;
        self.stampLabelFull = [[UILabel alloc] initWithFrame: 
                CGRectMake (stampFrame.size.width - 70, stampFrame.size.height - 
                            ((iPHONE) ? 80 : 140), 50, 50)];
        stampLabelFull.text = initials;
        stampLabelFull.backgroundColor = [UIColor clearColor];
        stampLabelFull.textColor = [UIColor whiteColor];
    }
    
    [playerLayerView addSubview: stampLabelFull];
    [player play];
}

-(void) leaveFullScreen: (id) foo   // AVPlayer
{
    NSLog (@"leave full screen");
    
    [UIView animateWithDuration: .3 animations: ^{
        playerLayerView.frame = saveFrame;
        playerLayer.frame = playerLayerView.layer.bounds;
    }];
    
    if ( !iPHONE) {
        UINavigationController  *nc = 
                [(VideoTreeAppDelegate *) [[UIApplication sharedApplication] delegate] nc];
        nc.view.hidden = NO;
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation: UIStatusBarAnimationFade];
    }
    
    newNote.hidden = NO;
    theTime.hidden = NO;
    backgroundLabel.hidden = NO;
    noteBar.hidden = NO;
    myVolumeView.hidden = NO;
    drawingBar.hidden = NO;
    volLabel.hidden = NO;
    notePaper.hidden = NO;
    notes.hidden = NO;
    
    if (watermark) 
        stampLabel.hidden = NO;
    
    fullScreenMode = NO;
    
    if (player.rate > .001)
        pausePlayButton.image = pauseImage;
}

- (void) itemDidPlayToEnd:(NSNotification*) aNotification 
{
    NSLog (@"Item did play to end");
    
	seekToZeroBeforePlay = YES;
    
    if (autoPlay) {
        if (! [self nextClip] && fullScreenMode)
            [self leaveFullScreen: nil];
    }
}



- (void)startObservingTimeChanges
{
	if (!playerTimeObserver) {
        float interval = (fps < .001) ? .1 : (1/fps);
        
		playerTimeObserver = [[player addPeriodicTimeObserverForInterval: kCMTimeMakeWithSeconds(interval) queue:dispatch_get_main_queue() usingBlock:
							   ^(CMTime time) {
                                   [self updateTimeControl];
                                   [self updateTimeLabel];
							   }] retain];
	}
}

- (void)stopObservingTimeChanges
{
	if (playerTimeObserver) {
		[player removeTimeObserver:playerTimeObserver];
		[playerTimeObserver release];
		playerTimeObserver = nil;
	}
}

- (void)observeValueForKeyPath:(NSString*) path ofObject:(id) object change:(NSDictionary*)change context:(void*)context
{
 //  NSLog (@"observe value %@", context);
	if (context == VideoTreeViewControllerRateObservationContext)
	{
		dispatch_async(dispatch_get_main_queue(),
                       ^{
                           [self syncPlaybackButton];
                       });
	}
	else if (context == VideoTreeViewControllerDurationObservationContext)
	{
		dispatch_async(dispatch_get_main_queue(),
                       ^{
                           [self updateTimeControl];
                           [self syncPlaybackButton];
                       });
	}
	else if (context == VideoTreeViewControllerStatusObservationContext) {
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           [self syncPlaybackButton];
                       });
        
    }
    else if (context == VideoTreeViewControllerTimedMetadataObserverContext) {
        NSLog (@"observed timed metadata");
        [self getStartTimecode];
    }
    else if (context == VideoTreeViewControllerCommonMetadataObserverContext) {
        NSLog (@"observed common metadata");
        NSLog (@"common metadata formats = %@", player.currentItem.asset.availableMetadataFormats);
        NSLog (@"common metadata = %@", player.currentItem.asset.commonMetadata);
        
        for (NSString *meta in player.currentItem.asset.availableMetadataFormats) 
           NSLog (@"*** %@", meta, [player.currentItem.asset metadataForFormat: meta]);    
    }
    else if (context == VideoTreeViewControllerAirPlayObservationContext) {

        NSLog (@"observed AirPlay change in player, airPlayVideoActive = %i", [player airPlayVideoActive]);
        
        if ([player airPlayVideoActive])
            airPlayImageView.hidden = NO; // unhide the airplay subview and bring to front
        else
            airPlayImageView.hidden = YES; // hide the airplay subview
        
    }
    else
        [super observeValueForKeyPath:path ofObject:object change:change context:context];
}


#pragma mark -
#pragma mark Notes table


// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {    
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [noteData count];
}

- (CGFloat) tableView: (UITableView *) tableView heightForRowAtIndexPath: (NSIndexPath *) indexPath
{
    if ( !iPHONE)
        return 60.0;
    else
        return 80.0;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    Note *theNote = [noteData objectAtIndex: indexPath.row];

    if ([theNote.initials isEqualToString: initials] )    
        cell.contentView.backgroundColor = MYWHITE;
    else
        cell.contentView.backgroundColor = MYGRAY;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
        [cell.textLabel setFont:[UIFont systemFontOfSize: 8.0]]; 
        [cell.detailTextLabel setFont:[UIFont systemFontOfSize: 10.0]];
        cell.editingAccessoryType = UITableViewCellEditingStyleDelete;
        cell.textLabel.numberOfLines = 1;
        cell.detailTextLabel.numberOfLines = 3;
        cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
        cell.imageView.frame = CGRectMake (0, 0, 32, 32);
        cell.imageView.backgroundColor = MYGRAY;
        tableView.backgroundColor = [UIColor colorWithRed: .8 green: .8 blue: .9 alpha: 1];
        
 
        CGRect theFrame = cell.selectedBackgroundView.frame;
        UIView *theBG = [[UIView alloc] initWithFrame: theFrame];
        theBG.backgroundColor =  [UIColor colorWithRed: 0 green: 0 blue: 0 alpha: .7];;
        cell.selectedBackgroundView = theBG;

    }

    Note *theNote = [noteData objectAtIndex: indexPath.row];
    cell.imageView.image = [UIImage imageWithData: theNote.thumb]; 
   
    cell.detailTextLabel.text = [theNote.text stringByReplacingOccurrencesOfString: @"<CHAPTER>" withString: @""];
    
    NSString *timeFormat = (timecodeFormat) ? theNote.timeStamp :
            [self timeFormat: kCMTimeMakeWithSeconds ([self convertTimeToSecs: theNote.timeStamp] - startTimecode) ];
    cell.textLabel.text = [NSString stringWithFormat: @"%@ %@ %@", timeFormat, 
            [theNote.date length] > 3 ? 
            [theNote.date substringToIndex: [theNote.date length] - 3] : @"", theNote.initials];
    
    if ([theNote.initials isEqualToString: initials] ) {
        cell.detailTextLabel.textColor = [UIColor blackColor];  
        cell.textLabel.textColor = [UIColor redColor];
        cell.textLabel.backgroundColor = MYWHITE;
        cell.detailTextLabel.backgroundColor = MYWHITE;
    }
    else {
        cell.detailTextLabel.textColor = [UIColor blackColor]; 
        cell.textLabel.textColor = [UIColor redColor];
        cell.textLabel.backgroundColor = MYGRAY;
        cell.detailTextLabel.backgroundColor = MYGRAY;
    }
      
    return cell;
}

// #define ANIMATE_GRAPHICS_TRANSITION

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Note *theNote = [noteData objectAtIndex: indexPath.row];
    
    if (player) {
        [self pauseIt];
        [audioPlayer stop];

#ifdef ANIMATE_GRAPHICS_TRANSITION
        [CATransaction begin];
        [CATransaction disableActions];
#endif
        
        if (fps == 0.0)
            [self updateTimeControl];
            
        Float64 secs = [self convertTimeToSecs: theNote.timeStamp] - startTimecode;
        NSLog (@"Seeking to %lg (%@) for Note", secs, theNote.timeStamp);

#ifdef ANIMATE_GRAPHICS_TRANSITION
        CATransition *animation = [CATransition animation];
        [animation setType:kCATransitionFade];
        animation.duration = .3;
#endif
        
        seekToZeroBeforePlay = NO;
        [player seekToTime: kCMTimeMakeWithSeconds(secs * ((int)(fps + .50000001) / fps)) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];

#ifdef ANIMATE_GRAPHICS_TRANSITION
        [playerLayerView.layer addAnimation:animation forKey:@"frameAnimation"]; 
        [CATransaction commit];
#endif
    }

    newNote.text = [theNote.text stringByReplacingOccurrencesOfString: @"<CHAPTER>" withString: @""];
    
    if (theNote.voiceMemo) {
        NSError *error = nil;
                
        if (audioPlayer)  
            [audioPlayer release];
        
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
        [audioSession setActive: YES error: NULL];
        
        audioPlayer = [[AVAudioPlayer alloc] initWithData: theNote.voiceMemo error:&error];
    
        fprintf (stderr, "audio playback time = %lf\n", audioPlayer.duration);
        if (error) {
            int errorCode = CFSwapInt32HostToBig ([error code]); 
            NSLog(@"Playback error: %@ [%4.4s])" , [error localizedDescription], (char*)&errorCode); 
        }
        
        [audioPlayer play];
    }
        
    drawView.colors = theNote.colors;
 
#ifdef ANIMATE_GRAPHICS_TRANSITION
    [CATransaction begin];
    [CATransaction disableActions];
    CATransition *animation = [CATransition animation];
    [animation setType:kCATransitionReveal];
    animation.duration = .5;
#endif
    
    drawView.myDrawing = theNote.drawing;
    drawView.scaleWidth =  playerLayerView.frame.size.width  / theNote.frameWidth;
    drawView.scaleHeight =  playerLayerView.frame.size.height / theNote.frameHeight;
    
    if ( drawView.scaleWidth == 0.0 || drawView.scaleWidth == NAN)
        drawView.scaleWidth = drawView.scaleHeight = 1.0;
    
#ifdef ANIMATE_GRAPHICS_TRANSITION
    [[drawView layer] addAnimation:animation forKey:@"layerAnimation"];
    [CATransaction commit];
#endif

    [drawView setNeedsDisplay];
    [self updateTimeLabel];
    [self updateTimeControl];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle: (UITableViewCellEditingStyle)editingStyle forRowAtIndexPath: (NSIndexPath *)indexPath
{
    if ([((Note *)[noteData objectAtIndex: indexPath.row]).initials isEqualToString: initials]) {
        NSLog (@"Commit editing style called");
        [noteData removeObjectAtIndex: indexPath.row];
        [self storeData];
        [notes reloadData];
    }
    else 		
		[UIAlertView doAlert: @"" withMsg: 
           @"You don't have permission to delete this note" ];
}

-(IBAction) editNotesTable: (UIBarButtonItem *) button
{
    if ([button.title isEqualToString:@"Edit"]) {
        editButton.title = @"Done";
        [self.notes setEditing: YES animated: YES];
    }
    else {
        editButton.title = @"Edit";
        [self.notes setEditing: NO animated: YES];
    }
}


- (void)dealloc {
    NSLog (@"dealloc");

    [player removeObserver: self forKeyPath:@"rate"];
    [player removeObserver: self forKeyPath:@"currentItem.status"];
    [player removeObserver: self forKeyPath:@"currentItem.asset.duration"];
    [player removeObserver: self forKeyPath:@"currentItem.asset.commonMetadata"];
    
    [theTimer invalidate];
    self.theTimer = nil;
    
    [theAsset release];
    [noteData release];
    [notes release];
    [currentlyPlaying release];
    [newThumb release];
    [stampLabel release];
    [minLabel release];
    [maxLabel release];
    [newNote release];
    [movieTimeControl release];
    [stampLabelFull release];
    [drawView release];
    [player release];
    [playerItem release];
    [progressView release];
    [popoverController release];
    [activityIndicator release];
    [noteProgressView release];
    [noteActivityIndicator release];
    [audioPlayer release];
    [markers release];
    [xmlPaths release];
    [XMLURLreader release];
    
    [movieController release];
 // [fullPlayer release];
    [editButton release];
    [pausePlayButton release];
    [pauseImage release];
    [playImage release];
    [show release];
    [clip release];
    [clipPath release];
    [episode release];
    [noteBar release];
    [drawingBar release];
    [notePaths release];
    [volLabel release];
        
    [playOutButton release];
    [playerToolbar release];
    [airPlayImageView release];
    [super dealloc];
}

@end
