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
#import <Endian.h>
#import "VoiceMemo.h"

@interface UIImage (TPAdditions)
- (UIImage*)imageScaledToSize:(CGSize)size;
@end

@implementation UIImage (TPAdditions)
- (UIImage *)imageScaledToSize:(CGSize)size {
    UIGraphicsBeginImageContext(size);
    [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}
@end

// Both of these map to the value of "rotate".  The first array maps before the rotation, the second after 
// (just has to do with the way the rotate ivar is incremented)

static int rotatePositions [] = { UIImageOrientationLeft, UIImageOrientationDown,  UIImageOrientationRight, UIImageOrientationUp };
static float rotAngles [] = { 0, 90, 180, 270};

typedef enum _transitionEffects
{
    TransitionEffectFade, // represents fade image transition effect
    TransitionEffectSlide // represents slide image transition effect
} TransitionEffect;

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
@synthesize stillView;
@synthesize airPlayImageView;
@synthesize playerToolbar;
@synthesize playOutButton;
@synthesize allStills;

@synthesize showName, newNote, fullScreenMode, drawView, movieTimeControl, notes, newThumb, noteBar, drawingBar;
@synthesize player, seekToZeroBeforePlay, movieURL, playerLayerView, theTime, maxLabel, minLabel, noteData, currentlyPlaying, isSaving, markers;
@synthesize pausePlayButton, pauseImage, playImage, recImage, isRecordingImage, clip, clipPath, show, tape, filmDate, playerLayer, 
editButton, initials, episode, playerItem, slideshowTimer, theTimer, noteTableSelected;
;
@synthesize progressView, activityIndicator, notePaths, xmlPaths, txtPaths, noteProgressView, noteActivityIndicator, volLabel, curInitials, movieController;
@synthesize  stampLabel, stampLabelFull, theAsset, startTimecode, download, clipLabel, runAllMode;
@synthesize rewindToStartButton, frameBackButton, frameForwardButton, forwardToEndButton, fullScreenButton, rewindButton, fastForwardButton, airPlayMode, remote;
@synthesize allClips, clipNumber, autoPlay, watermark, episodeLabel, dateLabel, tapeLabel, voiceMemo, mediaPath;
@synthesize recordButton, recording, skipForwardButton, skipBackButton, isPrinting, notePaper, uploadActivityIndicator, uploadActivityIndicatorView, uploadCount, keyboardShows, madeRecording, backgroundLabel, skipValue, uploadIndicator, FCPImage, AvidImage, FCPChapterImage, XMLURLreader, saveFilename, filenameView, stillShows, stillImage, timeCode;

#pragma mark -
#pragma mark view loading/unloading

- (BOOL)canBecomeFirstResponder {
    NSLog (@"Yes, I can become first responder");
    return YES;
}

// Do additional setup after loading the view

- (void) viewDidLoad {
    NSLog (@"view controller view did load");
    
    [super viewDidLoad];
    
    CGPoint theOrigin = {0, 0};
    CGSize theSize;
    CGRect theFrame;
    
    if (iPHONE) {
        newNote.font = [UIFont fontWithName: @"Helvetica" size: 10];
        self.editButton = nil;
    }
    
    NSLog (@"Allocating drawView frame");
    self.drawView = [[[DrawView alloc] initWithFrame: 
                      playerLayerView.layer.bounds] autorelease];
    drawView.userInteractionEnabled = YES;
    drawView.backgroundColor = [UIColor clearColor];
    drawView.scaleWidth = drawView.scaleHeight = 1;
    drawView.color = RED;
            
    drawViewFrame = drawView.frame;
    
    // Add a volume control for Airplay; Add a Route Button if >= iOS5
 
    if (! iPHONE)  {
        CGRect volFrame = { 580, 165, 300, 50 };
    
        myVolumeView = [[MPVolumeView alloc] initWithFrame: volFrame];
        
        if (! kRunningOS5OrGreater)
            myVolumeView.showsRouteButton = NO;
        
        [self.view addSubview: myVolumeView];
    }
    
#if 0
    // remove the playout button from the toolbar if iOS 5 or greater
    
    if (kRunningOS5OrGreater) {
        NSMutableArray    *items = [[playerToolbar.items mutableCopy] autorelease];
        [items removeObject: playOutButton];
        playerToolbar.items = items;
    }
#endif
    
    playOutButton.image = [UIImage imageNamed: @"rotate.png"];
    
    // Make sure the upload indicator is off
    
    [self uploadActivityIndicator: NO];
    
    // Makes the note border look a little nicer
    
    newNote.layer.borderWidth = 2;
	newNote.layer.borderColor = [[UIColor grayColor] CGColor];
    
    if (iPHONE)
        newNote.layer.cornerRadius = 8;

    // Add the TableView for the Notes (don't know why I didn't
    // lay this out in the interface (!)
    
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
    
    // Hide the remote control view (currently not used)
    
    remote.alpha = 0;

    [self.view addSubview: notes]; 
    [notes release];
    
    // Red is the default markup color
    
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
    noteTableSelected = NO;
    
    fps = 0.0;
    pausePlayButton.enabled = NO;
    self.pauseImage = [UIImage imageNamed: @"pause2.png"];
    self.playImage = [UIImage imageNamed: @"play.png"];

    seekToZeroBeforePlay = YES;     // Only when we start playing or reached the end
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
                    
    // We show a red microphone during recording
                    
    [recordButton setImage: recImage forState: UIControlStateNormal];
    [recordButton setImage: isRecordingImage forState: UIControlStateHighlighted];  
                    
    playerLayerView.backgroundColor = [UIColor blackColor];
    
    // Tables of paths to notes, FCP XML files, Avid locator files
                    
    self.notePaths = [NSMutableArray array];
    self.xmlPaths = [NSMutableArray array];
    self.txtPaths = [NSMutableArray array];
                    
    // The table of notes used to populate the note table
                    
    self.noteData = [NSMutableArray array];
                    
    voiceMemo = [[VoiceMemo alloc] init];
    recording.hidden = YES;
                    
    // Images used in the Notes table for FCP markers and Avid locator records
    
    self.FCPImage = [UIImage imageNamed: @"fcp.png"];
    self.FCPChapterImage = [UIImage imageNamed: @"fcpChapter.png"];
    self.AvidImage = [UIImage imageNamed: @"avid.png"];
                    
    // Respond to the scrubber events by connecting three methods to the slider

    [movieTimeControl addTarget:self action:@selector(sliderDragBeganAction) forControlEvents:UIControlEventTouchDown];
    [movieTimeControl addTarget:self action:@selector(sliderDragEndedAction) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
    [movieTimeControl addTarget:self action:@selector(sliderValueChange) forControlEvents:UIControlEventValueChanged];	
    
    // We put a custom red color behined the scrubber cause it looks purdy!
                    
    movieTimeControl.backgroundColor = [UIColor clearColor];	
    UIImage *stetchLeftTrack = [[UIImage imageNamed:@"redhi.png"] stretchableImageWithLeftCapWidth:10.0 topCapHeight:0.0];
    [movieTimeControl setMinimumTrackImage:stetchLeftTrack forState: UIControlStateNormal];
    
    // This is for the dialog for an "Open in.." or the camera roll
    // We laid it out in IB, but we don't want to show it until we're ready

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
 
    // We shouldn't be uploading any data right now
                    
    if (uploadCount)
        [uploadActivityIndicator stopAnimating];
    
    uploadCount = 0;
    
    [stampLabel removeFromSuperview];  // Don't like the way IB places this
}

- (void) viewDidAppear: (BOOL) animated {
    
    [super viewDidAppear: animated];
    
    // So you can use the headphones to pause/start playback...
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
}

// Only observe time changes when the view controller's view is visible.

- (void)viewWillAppear:(BOOL)animated
{    
	[super viewWillAppear:animated];
    
    // registers the notifications for the keyboard 
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(keyboardDidShow:) 
                                                 name:UIKeyboardDidShowNotification 
                                               object:self.view.window]; 
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidHide:)
                                                 name:UIKeyboardDidHideNotification
                                               object:nil];
    
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
    
    // This app only runs in landscape mode
    
    return interfaceOrientation == UIInterfaceOrientationLandscapeLeft || 
                    interfaceOrientation == UIInterfaceOrientationLandscapeRight;
}

- (void) didReceiveMemoryWarning {
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
}

- (void)viewDidUnload {
    NSLog (@"Viewcontroller view did unload");
    [self setStillView:nil];
    [self setAirPlayImageView:nil];
    [self setPlayerToolbar:nil];
    [self setPlayOutButton:nil];
    self.newNote = nil;
    self.theTime = nil;
    self.movieTimeControl = nil;
    self.drawView = nil;
    self.playerLayerView = nil;
    self.maxLabel = nil;
}

#pragma mark -
#pragma mark Still support
  
-(void) dumpRect: (CGRect) r title: (NSString *) title
{
    NSLog (@"%@: origin = (%g, %g), size = (%g, %g)", title, r.origin.x, r.origin.y,
           r.size.width, r.size.height);
}

// called when the image transition animation finishes

- (void)transitionFinished:(NSString *)animationId finished:(BOOL)finished
                   context:(UIImageView *) context
{
    [context removeFromSuperview];   // remove the old image
    stillView.userInteractionEnabled = YES;
    [context release];
} 

//
//  Load in a still image given its address
//

-(void) loadStill: (NSString *) link 
{
    self.movieURL = [self getTheURL: link];
    self.mediaPath = link;
    
    NSData *imageData = [NSData dataWithContentsOfURL: movieURL];
    
    if (!imageData) {
        [UIAlertView doAlert: @"Still Image" 
                     withMsg: @"I couldn't read the image!"];
        return;
    }
    
    playOutButton.image = [UIImage imageNamed: @"rotate.png"];
    playOutButton.enabled = YES;

    // On the iPhone, hide the clip table
    
    if (iPHONE) {
        UINavigationController  *nc = [(VideoTreeAppDelegate *) [[UIApplication sharedApplication] delegate] nc];
        nc.view.hidden = YES;
    }
    
    // Invalidate any timer that might still be running
    
    if (slideshowTimer) {
        [slideshowTimer invalidate];
        self.slideshowTimer = nil;
    }
        
    // Are we currently showing a still or a video player?
    // If we selected the still from the notes table, we don't want to do any cleanup work here
    // If we selected the still from the clip table (or it's being autoplayed) we do want to
    // load the notes
    
    if (! noteTableSelected) {
        if (player)
            [self cleanup];
        
        [self erase];
        [self clearAnyNotes];
        newNote.text = @"";
        
        // Load the notes table
        
        if (kBonjourMode) {
            [self getAllHTTPNotes];
        } else {
            [self loadData: initials];
        }
    }
    
    drawView.frame = drawViewFrame;

    // No current rotation
    
    rotate = 0;
    self.clip = [link lastPathComponent];
    
    UIImageView *currentView = nil;
    
    if (stillShows)
        currentView = [stillView retain];

    // Load the image
    
    if (stillImage) 
        [stillImage release];
    
    stillImage = [[UIImage alloc] initWithData: imageData];
    stillView = [[[UIImageView alloc] initWithImage: stillImage] autorelease];
    
    if (fullScreenMode)
        drawView.frame = stillView.frame = playerLayerView.frame;
    
    NSLog (@"Stillview.image size = (%g, %g)", stillView.image.size.width, stillView.image.size.height);
    [self dumpRect: drawView.frame title: @"drawView.frame"];
    
    //set contentMode to scale aspect to fit
    
    stillView.contentMode = UIViewContentModeScaleAspectFit;
    
    // Compute a scale factor so we can adjust the size of the drawing frame
    
    CGFloat curWid = drawView.frame.size.width, curHt = drawView.frame.size.height;
    CGFloat scale, scaleX, scaleY;
    CGRect newFrame = drawView.frame;
    
    scaleX = drawView.frame.size.width / stillView.image.size.width;
    scaleY = drawView.frame.size.height / stillView.image.size.height;
    
    NSLog (@"scaleX = %g, scaleY = %g", scaleX, scaleY);
    
    if (scaleX < scaleY)
        scale = scaleX;
    else
        scale = scaleY;
    
    newFrame.size.width = stillView.image.size.width * scale;
    newFrame.size.height = stillView.image.size.height * scale;
    newFrame.origin.x += (curWid - newFrame.size.width) / 2;
    newFrame.origin.y += (curHt - newFrame.size.height) / 2;
    
    stillView.frame = drawView.frame; 
    drawView.frame = newFrame;
        
    [self dumpRect: drawView.layer.frame title: @"new drawView.layer.frame"];
    [self dumpRect: drawView.layer.bounds title: @"new drawView.layer.bounds"];
    
    // Show the still now and add the drawing frame on top
    
    drawView.hidden = NO;
    stillView.userInteractionEnabled = YES;
    [playerLayerView addSubview: stillView];
    [stillView addSubview: drawView];

    if (stillShows) {
        stillView.alpha = 0;

        [UIView beginAnimations:nil context: currentView];
        [UIView setAnimationDuration: (noteTableSelected) ? .25 : 2.0]; // set the animation length
        [UIView setAnimationDelegate:self]; // set the animation delegate
        
        // call the given method when the animation ends
        [UIView setAnimationDidStopSelector: @selector(transitionFinished:finished:context:)];
        
        // make the next image appear with the chosen effect
        
        TransitionEffect theEffect =  TransitionEffectFade;
        
        switch (theEffect)
        {
            case TransitionEffectFade: // the user chose the fade effect
                [stillView setAlpha: 1.0]; // fade in the next image
                [currentView setAlpha: 0.0]; // fade out the old image
                break;
                
            case TransitionEffectSlide: // the user chose the slide effect
                // frame.origin.x -= frame.size.width; // slide new image left
                // nextImageView.frame = frame; // apply the repositioned frame
                // CGRect currentImageFrame = currentImageView.frame;
                
                // slide the old image to the left
                // currentImageFrame.origin.x -= currentImageFrame.size.width;
                // currentImageView.frame = currentImageFrame; // apply frame
                break;
        } 
        
        [UIView commitAnimations]; // end animation block
    }

    // hide buttons that don't apply
    
    theTime.hidden = YES;
    backgroundLabel.hidden = YES;
    movieTimeControl.hidden = YES;
    maxLabel.hidden = YES;
    minLabel.hidden = YES;
    rewindToStartButton.enabled = NO; 
    frameBackButton.enabled = NO; 
    frameForwardButton.enabled = NO; 
    forwardToEndButton.enabled = NO; 
    rewindButton.enabled = NO;
    fastForwardButton.enabled = NO;
    myVolumeView.hidden = YES;


    if (autoPlay) {
        pausePlayButton.image = pauseImage;
        pausePlayButton.enabled = YES;
    }
    else
        pausePlayButton.enabled = NO;
    
    skipForwardButton.enabled = NO;
    skipBackButton.enabled = NO;
    skipForwardButton.title = @"";
    skipBackButton.title = @"";
    stillShows = YES;
    
    if (autoPlay && ! noteTableSelected)
        self.slideshowTimer = [NSTimer scheduledTimerWithTimeInterval: slideshowTime target:self 
               selector:@selector(stillDidTimeOut:) userInfo:nil repeats: NO]; 
    
    if (watermark) {
        [stillView addSubview: stampLabel];
        stampLabel.hidden = NO;
    }
    
    recordButton.enabled = YES; // Allow to record a voice memo too.
}

- (void) rotateStill {
    // Yucch!  We'll need to rotate the markups as well? -- no, we'll just clear them--it's easier that way!
    
    if (!noteTableSelected)
        [self erase];
            
    // Compute a scale factor so we can adjust the size of the drawing frame
    // This is ugly due to the rotation--uggh
    
    CGRect newFrame = drawView.frame;
    
    CGFloat widDiff = newFrame.size.width - stillView.image.size.height;
    CGFloat htDiff =  newFrame.size.height - stillView.image.size.width;
    CGFloat scale;
    
    // Adjust the frame to keep the markups inside the still (or close to it)
    
    CGFloat curWid = drawView.frame.size.width, curHt = drawView.frame.size.height;
    
    NSLog (@"drawView wid, ht before rotation = (%g, %g)", curWid, curHt);
    float scaleX, scaleY;
    
    scaleX = newFrame.size.height / stillView.image.size.width;
    scaleY = newFrame.size.width / stillView.image.size.height;
    
    NSLog (@"scaleX = %g, scaleY = %g", scaleX, scaleY);
    
    if (scaleX * stillView.image.size.height > drawViewFrame.size.width)
        scale = scaleY;
    else
        scale = scaleX;
    
    newFrame.size.width = stillView.image.size.height * scale;
    newFrame.size.height = stillView.image.size.width * scale;
    newFrame.origin.x += (curWid - newFrame.size.width) / 2;
    newFrame.origin.y += (curHt - newFrame.size.height) / 2;

    // Now rotate the image
    
    CGImageRef imageRef = [stillImage CGImage];
    stillView.image =  [UIImage imageWithCGImage: imageRef scale: 1
                                     orientation: rotatePositions [rotate % 4]];
    
    ++rotate;
    
    NSLog (@"image wid, ht after rotation = (%g, %g)", stillView.image.size.width, stillView.image.size.height);    
    NSLog (@"widDiff = %g, htDiff = %g, scale = %g", widDiff, htDiff, scale);
    
    [self dumpRect: newFrame title: @"newFrame"];
    drawView.frame = newFrame;
}

#pragma mark -
#pragma mark remote control (e.g. headphones)

//                    
// This method is called when a button is pressed on the headphones
// We allow the play/pause and ff/rew
//

-(void)remoteControlReceivedWithEvent:(UIEvent *)event {
    NSLog (@"Remote control event received");
    
    // This is if we're using a movieController (won't need this after iOS 5.0)
    
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
    
    // This is if we're using AVPlayer to play the movie
    
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

//
// This creates the overlay view with an activity indicator
// The activity indicator is animated while a movie is being loaded 
// for playback
//
                    
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

//
// This creates the overlay view with an activity indicator
// The activity indicator is animated while the Notes 
// table is being loaded

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
        mySleep (1000);   // allows time for things to settle
        
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

//
// This creates a view on the toolbar that displays an activity indicator
// This indicator is animated whenever content (e.g., Notes, HTML) is being
// uploaded to the server
//

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
                    
// These are delefate routines that will allow us to dismiss the keyboard

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

//
// This method is used for setting up default settings (that come from the Settings app)
//
                    
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
    // I had to invert this since DefaultValue doesn't seem to work
    
    timecodeFormat =  !(BOOL) [[defaults objectForKey: @"Timecode"] integerValue];
    
    // Display time for slide show
    
    slideshowTime = [[defaults objectForKey: @"slideTime"] floatValue];
    
    if (slideshowTime == 0)
        slideshowTime = 5;
    
    NSLog (@"Setting slide show time interval to %g", slideshowTime);   
    
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

//
//  The color selection button, which is a segmented control
//  Make sure when one color is selected, that a highlighted image is
//  shown for that color and the others are set to normal
//

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

//
// The erase button
//
// Erase all current markups

-(IBAction) erase
{
    NSLog2 (@"Erase");
    [drawView cancelDrawing];
    [audioPlayer stop];
}

//
// The microphone button
//
// Record an audio note
// Stop recording if we're currently recording a note (and save the note)
//

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

//
// The Undo Button
//
// Undo the last drawn line segment

-(IBAction) unDo
{
    NSLog (@"Undo");
    [drawView unDo];
}

#pragma mark -
#pragma mark Playback Control

// The single frame playback button

-(IBAction) backFrame
{
    [self erase];
    goingForward = NO;
    [self singleFrame];
}  
 
// The rewind button

-(IBAction) rewind
{
    [self erase];
    
    if (!player)
        return;
    else
        pausePlayButton.image = pauseImage;
    
    // progressive rewind: 1.75x => 5.25xx => 15.75x => 1x
    
    if (player.rate >= 0.0)
        player.rate = -1.75;
    else if (player.rate < -13.0)
        player.rate = 1.0;
    else
        player.rate *= 3.0;

}

// The seek to start button

-(IBAction) rewindToStart
{
    [self erase];
    [player seekToTime: kCMTimeZero];
}

// The pause/play button
                    
- (IBAction)playPauseButtonPressed:(id)sender
{    
    // If the slideshowTimer is running, we're in slide show playback mode
    // Pause the playback (i.e., kill the timer)
    
    if (slideshowTimer) {
        [slideshowTimer invalidate];
        self.slideshowTimer = nil;
        pausePlayButton.image = playImage;

        return;
    }
    
    //
    //  If a still is showing and we're in autoPlay mode, resume playback
    //
    
    if (stillShows && autoPlay) {
        self.slideshowTimer = [NSTimer scheduledTimerWithTimeInterval: slideshowTime target:self 
                        selector:@selector(stillDidTimeOut:) userInfo:nil repeats: NO]; 
        pausePlayButton.image = pauseImage;
        return;
    }
        
    
    // If a timer's running we're in single frame playback
    // In that case, we'll pause playback below
    
    if (theTimer) 
        player.rate = 1.0;
    
	if (player.rate == 0.0) {
            // if we are at the end of the movie we must seek to the beginning first before starting playback
            
            if (YES == seekToZeroBeforePlay) {
                seekToZeroBeforePlay = NO;
                [player seekToTime: kCMTimeZero];
            }
        
            newNote.text = @"";       // Clear any note or markups
            [self erase];
            player.rate = 1.0;        // Start playback and set the play/pause button to pause icon
            pausePlayButton.image = pauseImage;
	} else {
            [self pauseIt];
	}
}

// The fast forward button
                    
-(IBAction) fastForward
{
    [self erase];
    
    if (!player)
        return;
    else
        pausePlayButton.image = pauseImage;
    
    // progressive fast forward:  1.75x => 5.25x => 15.75x => 1x
    
    if (player.rate <= 1.0)
        player.rate = 1.75;
    else if (player.rate > 13)
        player.rate = 1;
    else
        player.rate *= 3;
}

//
// Advance the playback head forward or back (if arg is negative)
// by a specified number of seconds
//

-(void) advance: (int) secs;
{
    if (!player || !pausePlayButton.enabled) 
        return;
    
    [self pauseIt];
    CMTime spot = CMTimeAdd ([player currentTime], kCMTimeMakeWithSeconds (secs));
    [player seekToTime: spot toleranceBefore: kCMTimeZero toleranceAfter: kCMTimeZero];
    [self playPauseButtonPressed: nil];
}

// 
// The programmable skip back button
// Skip back by the programmed number of seconds (specified in the Settings)
//
    
-(IBAction) skipBack
{
    [self advance: -skipValue];
}

// 
// The programmable skip forward button
// Skip back by the programmed number of seconds (specified in the Settings)
//

-(IBAction) skipForward
{
    [self advance: skipValue];
}

//
//  This method gets called every time the time fires to 
//  move playback forward or back by a single frame
//  The method supports the single frame forward and back playback buttons
//

-(void) nextFrame: (NSTimer *) timer 
{
    if (goingForward)
        [player.currentItem stepByCount: 1];
    else
        [player.currentItem stepByCount: -1];
}

//
// Method to support single frame play back
// We set a timer to fire every .25 seconds.
// When the timers fires, we call the nextFrame: method
// to move forward or back by a single frame
//

-(void) singleFrame
{
    if (!player)
        return;
    
    // If there's already a timer firing, and the single frame forward/back
    // button was pressed a second time, let's pause the playback here
    
    if (theTimer) {
        [self pauseIt];
        return;
    }   
    
    // Erase any pending markups or notes
    
    newNote.text = @"";
    [self erase];
    
    pausePlayButton.image = pauseImage;
    
    // Schedule the timer now
    
    self.theTimer = [NSTimer scheduledTimerWithTimeInterval: .25 target:self 
                        selector:@selector(nextFrame:) userInfo:nil repeats:YES]; 
}

// The single frame forward playback button

-(IBAction) forwardFrame
{
    [self erase];
    goingForward = YES;
    [self singleFrame];
}

// The seek to end button

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
   
// Pause playback.  If there's a timer running, get rid of it

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
#pragma mark Saving a note

// The first set of methods will only work if we can get an accurate screen grab 
// (available as of iOS 5.0)
//
// The second set uses UIGetScreenImage (), which is a private API and will not 
// get through the app store


//
// Once we grab the frame, we have to draw the markups (line segments) onto the frame
// This is the purpose of this method.  On input it gets a reference to a bitmap
// context to render into, along with the width and height of the captured frame
//

-(void) drawMarkups: (CGContextRef) ctx { 
//    CGContextTranslateCTM (ctx, 0, ht);
//    CGContextScaleCTM (ctx, (wid / drawView.bounds.size.width), -(ht / drawView.bounds.size.height)); 
    
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
                
                CGContextBeginPath (ctx);
                CGContextMoveToPoint (ctx, thisX, thisY);
                
                for (int j = 2; j < [thisArray count] ; j += 2) {
                    thisX = [[thisArray objectAtIndex: j] floatValue];
                    thisY = [[thisArray objectAtIndex: j + 1] floatValue];
                    
                    CGContextAddLineToPoint (ctx, thisX, thisY);
                }
                CGContextStrokePath(ctx);
            }
        }
    }
}

//
// Scale the captured still for the thumbnail
//

-(UIImage *) scaleImage: (CGImageRef) image  andRotate: (float) angle
{
    // We grabbed the frame, let's make it smaller

    CGImageAlphaInfo	alphaInfo = CGImageGetAlphaInfo(image);

    if (alphaInfo == kCGImageAlphaNone)
    alphaInfo = kCGImageAlphaNoneSkipLast;
    
    int wid, ht;
    
    wid = CGImageGetWidth (image);
    ht =  CGImageGetHeight (image);  
    
    NSLog (@"image width,height = (%i, %i)", wid, ht);

    ht =  (200. / wid) * ht;
    ht = ht + ht % 8;
    wid = 200;
    
    NSLog (@"image width,height = (%i, %i)", wid, ht);

    CGRect thumbRect = { 
        {0.0f, 0.0f}, 
        {(float) wid, (float) ht}
    };

    NSLog (@"bits per component = %i, color space = %i",  CGImageGetBitsPerComponent(image), CGImageGetColorSpace(image));
    
    CGFloat angleInRadians = angle * (M_PI / 180);

    CGAffineTransform transform = CGAffineTransformMakeRotation(angleInRadians);
    thumbRect = CGRectApplyAffineTransform(thumbRect, transform);

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
    
    CGContextTranslateCTM(bitmap, +(thumbRect.size.width/2), +(thumbRect.size.height/2));
    CGContextRotateCTM(bitmap, angleInRadians);
    
    // Draw into the context, this scales the image

    CGContextDrawImage(bitmap, CGRectMake(-wid/2, -ht/2, wid, ht), image);
    CGContextRotateCTM(bitmap, -angleInRadians);
    CGContextTranslateCTM(bitmap, -(thumbRect.size.width/2), -(thumbRect.size.height/2));
    
    if (angle == 90 || angle == 270) {
        CGContextTranslateCTM (bitmap, 0, wid);
        CGContextScaleCTM (bitmap, (ht / drawView.bounds.size.width), -(wid / drawView.bounds.size.height)); 
    }
    else {
        CGContextTranslateCTM (bitmap, 0, ht);
        CGContextScaleCTM (bitmap, (wid / drawView.bounds.size.width), -(ht / drawView.bounds.size.height)); 
    }
        
    [self drawMarkups: bitmap];

    // Get an image from the context and create a UIImage

    CGImageRef	ref = CGBitmapContextCreateImage(bitmap);
    
    UIImage *resultImage = [UIImage imageWithCGImage:ref];
    
    NSLog (@"saved image size = %f x %f", resultImage.size.width, resultImage.size.height);

    // Clean up

    CGContextRelease (bitmap);	
    CGImageRelease (ref);
    
    return resultImage;
}

#ifdef APPSTORE

//
// This method will capture the paused video frame so we can save the 
// frame into the notes table.   The method will ask the AVAssetImageGenerator class
// to capture the frame for us at the currentTime.  Then, we'll draw the markups
// onto the current captured frame and save it to our notes table
//

-(void) frameDraw
{    
    AVAssetImageGenerator *imageGen = [[AVAssetImageGenerator alloc] initWithAsset: 
                    [[player currentItem] asset]];
 
    if (!imageGen) {
        NSLog (@"AVAssetImageGenerator failed!");  // Hopefully this never happens
        return;
    }
    
    //  [imageGen setMaximumSize: CGSizeMake (320, 196)];
    [imageGen setVideoComposition:[[player currentItem] videoComposition]];
    [imageGen setAppliesPreferredTrackTransform:YES];
    
    // Yay!  iOS 5.0 lets us set the tolerance for the frame we want to capture
    // Prior to iOS 5.0 we're only going to get the nearest key frame
    // Still waiting for support for any of this from streaming media....
    
    // Late breaking news:  This seems to work for iOS 4.3 as well (documentation 
    // just says iOS 5.0 or later??)
    
    if ([imageGen respondsToSelector: @selector (setRequestedTimeToleranceAfter:)]) {
        [imageGen setRequestedTimeToleranceAfter: kCMTimeZero];
        [imageGen setRequestedTimeToleranceBefore: kCMTimeZero];
   }

    // Create the request to get the frame using the copyCGImageAtTime:actualTime:error: method
    
    NSError *error = nil;
    CMTime actual;
    CMTime request = [player currentTime];   // kCMTimeMakeWithSeconds (kCVTime([player currentTime]));

    CGImageRef image = [imageGen copyCGImageAtTime: request actualTime: &actual error: &error];
    NSLog (@"Request for frame at %@, actual = %@ (fps = %f)", [self timeFormat: request], [self timeFormat: actual], fps);
    
    if (error)  {   // Oops!  We couldn't grab the frame
        NSLog (@"Error trying to capture image: %@ at time: %@", [error localizedDescription], [self timeFormat: request]);
        return;
    }
    
    // Asynchronous frame capture -- we really don't need this; the video is paused anyway
   
#ifdef ASYNC  
    NSArray *requestedTimes = [NSArray arrayWithObject: [NSValue valueWithCMTime: request]];
    
    [imageGen generateCGImagesAsynchronouslyForTimes: requestedTimes completionHandler:
        ^(CMTime requestedTime, CGImageRef image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error) {
            if (error) 
                NSLog (@"Error trying to capture image: %@ at time: %@", [error localizedDescription], [self timeFormat: requestedTime]);
            
            NSLog (@"Async Request for frame at %@, actual = %@ (fps = %f)", [self timeFormat: requestedTime], [self timeFormat: actualTime], fps);
        }];
#endif
    
    self.newThumb = [self scaleImage: image andRotate: 0.0];
    [imageGen release];
}

#else

//
// Code to rotate an image
// We need this because we run in landscape mode and UIGetScreenImage will
// give us an image that we'll need to rotate
//

- (CGImageRef) CGImageRotatedByAngle:(CGImageRef)imgRef angle:(CGFloat)angle
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

//
// This method is a no-no for Apple
// It uses the on-again off-again private UIGetScreenImage function to grab what's on the screen
// Nice thing about it is we don't have to redraw the markups and it's of course precise
// (although iOS 5.0 has thankfully resolved the latter problem for us)
//

-(void) frameDraw
{
    CGImageRef UIGetScreenImage ();
    CGImageRef rotatedScreen = UIGetScreenImage ();
    
    CGRect thumbRect = playerLayerView.frame; 
   
    //
    // These are kludged numbers in here to adjust the stupid bitmap to the right orientation
    // I absolutely hate the math here and couldn't explain if I tried!
    //
    
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

//
// The Save button
// This method is also called internally to save a note (e.g., when the keyboard is dismissed)
//

-(IBAction) save
{
    // Dismiss the keyboard if it's showing
    
    if (keyboardShows)  {
        [newNote resignFirstResponder];
        pendingSave = YES;
        return;
    }
    
    // Stop recording if that's what we're doing
    
    if ([voiceMemo audioRecorder].isRecording)  { 
        [self recordNote];
        return;
    }
    
    // If there's no video player, or we're playing and there's no still showing--ignore this save
    
    if ((!player || player.rate != 0.0) && !stillShows)
        return;

    // We're here, so we really want to save a note
    // Create a new note object
    
    Note *aNewNote = [[Note alloc] init];
    
    // Capture the frame and draw the markups on it
    
    if ( !stillShows )
        [self frameDraw];
    else {
        self.newThumb = [self scaleImage: [stillImage CGImage] andRotate: rotAngles [rotate % 4]];     // markups drawn on top by the method
    }
    
    // Capture any text typed into the note pad area
    
    aNewNote.text = newNote.text;
    CMTime curTime;
    
    if ( !stillShows ) {
        curTime =  kCMTimeMakeWithSeconds (kCVTime ([player currentTime]) + startTimecode);
    
        // Always store the time in timecode format
        
        BOOL saveFormat = timecodeFormat;
        timecodeFormat = YES;
        aNewNote.timeStamp = [self timeFormat: curTime];
        timecodeFormat = saveFormat;
        
        // We use this to scale the markups as needed so it
        // works on both the iPhone and iPad
        
        aNewNote.frameWidth = playerLayerView.frame.size.width;
        aNewNote.frameHeight = playerLayerView.frame.size.height;
        aNewNote.imageName = nil;
        aNewNote.rotation = 0;
    }
    else {
        aNewNote.frameWidth = drawView.frame.size.width;
        aNewNote.frameHeight = drawView.frame.size.height;
        
        aNewNote.timeStamp = @"";
        aNewNote.imageName = clip;
        aNewNote.rotation = rotate % 4;     // Save the current orientation of the still
    }
    
    // Save the markups
    
    aNewNote.drawing = [drawView myDrawing];
    aNewNote.colors = [drawView colors];
    
    // Save the date this note was made, and who made it
    
    aNewNote.date = [self formatDate: NO];
    aNewNote.initials = initials;

    // If we made an audio note, save it as NSData
    
    if (madeRecording)
        aNewNote.voiceMemo = [NSData dataWithContentsOfURL:[voiceMemo memoURL]];
    else
        aNewNote.voiceMemo = nil;

    // Let's compress the frame we grabbed and store it as NSData
    
    isSaving = YES;
    aNewNote.thumb = UIImageJPEGRepresentation(newThumb, 0.9f);
//  assert (aNewNote.thumb);
    
    // Love this part.  Animate the frame and note going into the notes table

    [self animateSave];
    
    int     row = 0;
    
    if ( !stillShows ) {
        // Find where to put the note in the table (sorted in timecode order)
        
        Float64 now = CMTimeGetSeconds(curTime);
                                             
        row = 0;
        for (Note *theNote in noteData) {
            if ([self convertTimeToSecs: theNote.timeStamp] > now)
                break;
            ++row;
        }
    }
        
    // Insert the note into the array and table
    
    NSIndexPath *indexP = [NSIndexPath indexPathForRow: row inSection:0];
    NSArray *indexPaths = [[NSArray alloc] initWithObjects: indexP, nil];
    
    [noteData insertObject: aNewNote atIndex: row];
    [aNewNote release];

    [notes insertRowsAtIndexPaths:(NSArray *)indexPaths 
                     withRowAnimation:(UITableViewRowAnimation)UITableViewRowAnimationLeft];

    // Sometimes this crashes, so we'll do this in an @try block
    
    @try 
    {
        [notes scrollToRowAtIndexPath: indexP 
                     atScrollPosition: UITableViewScrollPositionBottom animated: YES];
    }
    @catch (NSException * e)
    {
        //do nothing
        NSLog (@"Race condition with notes table exception: %@", [e reason]);
    }
    
    [indexPaths release];

    // Clear the note
    
    newNote.text = @"";
    [self erase];
    madeRecording = NO;
    [self storeData];
    
    pendingSave = NO;
}

// 

-(void) animateSave {
    // animate frame save
    
    // This part will animate the movement of the playback frame into the table
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, playerLayerView.layer.frame.origin.x + 
                      playerLayerView.layer.bounds.size.width / 2,
                      playerLayerView.frame.origin.y + playerLayerView.layer.bounds.size.height / 2);
    
    // We want to animate along a curve
    
    if ( !iPHONE)
        CGPathAddQuadCurveToPoint(path, NULL, 350, playerLayerView.layer.frame.origin.y, 0, 600);
    else
        CGPathAddQuadCurveToPoint(path, NULL, 350, playerLayerView.layer.frame.origin.y, 0, 300);
    
    CAKeyframeAnimation *pathAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    pathAnimation.path = path;
    pathAnimation.duration = 1.0;
    
    // Make the image shrink and fade as it moves
    
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
    
    // This part will does the same thing as the previous block of code
    // except now we're animating the note into the notes table, also along a curve
    
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
    animationGroup2.animations = [NSArray arrayWithObjects:pathAnimation2, 
                                  scaleAnimation2, alphaAnimation2, nil];
    animationGroup2.timingFunction = [CAMediaTimingFunction functionWithName:
                                            kCAMediaTimingFunctionEaseInEaseOut];
    animationGroup2.duration = 1;
    
    [newNote.layer addAnimation:animationGroup2 forKey:nil];
    
    CFRelease(path);
}

#pragma mark -
#pragma mark make file paths

// Text files used for Avid locator import and export

-(NSString *) txtFilePath
{
	NSArray *dirList = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *docDir = [dirList objectAtIndex: 0];
    
    NSString *fileName = [NSString stringWithFormat: @"%@.txt", [clip stringByDeletingPathExtension]];
    NSLog (@"Archive file name = %@", fileName);
	return [docDir stringByAppendingPathComponent: fileName];
}

// Path to a local file.  Notes are locally stored here

-(NSString *) archiveFilePath
{
    NSLog(@"Getting archive file path... ");
	NSArray *dirList = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *docDir = [dirList objectAtIndex: 0];

    NSString *fileName = [NSString stringWithFormat: @"%@.%@", 
            [clipPath stringByReplacingOccurrencesOfString: @"/" withString: kNoteDelimiter], initials];
    NSLog(@"clippath: %@", clipPath);    
    NSLog (@"Archive file name = %@", fileName);
	return [docDir stringByAppendingPathComponent: fileName];
}

// Archiving methods for our data

-(void) loadData: (NSString *) fileInfo  {
    download = kNotes;
    NSString *downloadPath = [NSString stringWithFormat: @"Notes/%@", fileInfo];
    
    NSLog (@"*** Download path = %@", downloadPath);
    
    if (!kBonjourMode) {
        // Local mode
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
}


-(void) directlySetStartTimecode: (NSString *) timeCodeStr {
    NSLog(@"Called directlySetStartTimecode with timeCodeStr being: %@", timeCodeStr);
    startTimecode = 0.0;
    if (timeCodeStr) {
        startTimecode = [self convertTimeToSecs:timeCodeStr];
        durationSet = NO;
        maxLabelSet = NO;
        [self updateTimeControl];
        [self updateTimeLabel];
        NSLog(@"Successfully set timecode directly to: %@", timeCodeStr);
    } else
        NSLog(@"Could not set timecode directly. String was: %@", timeCodeStr);
}


//  Download the notes archive from the bonjour py server
// So I just want to say that the way the notes is being done is terrible for collaboration.
// When someone creates a note, an entire archive gets sent up the wire of what they currently have.
// This means that if someone has just added a note (and it was uploaded) it would be overwritten by an old
// archive with that person's note and old list of previous notes. terrible terrible.
-(void) getAllHTTPNotes
{
    NSLog(@"Retrieving notes archive.");
    NSError *error = nil;
    NSURLResponse *response;
    NSString *archivePath = [self archiveFilePath];
    NSString *noteNameForURL = [[archivePath lastPathComponent] stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/note/%@", kHTTPserver, noteNameForURL]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:60.0];
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if (error != nil)
        NSLog(@"%@", error.localizedDescription);
    NSLog(@"Got back this much data: %d", [data length]);
    if ([notePaths count])
        [notePaths removeAllObjects];
    [data writeToFile:archivePath atomically:YES];
    NSLog(@"Downloaded the note archive, attempting to restore...");
    NSFileManager *fm = [NSFileManager defaultManager];
    [self noteShowActivity];
    if ([fm fileExistsAtPath: archivePath] && ([data length] > 50)) {
        NSArray *noteArray = [NSKeyedUnarchiver unarchiveObjectWithFile: archivePath];
        [noteData release];
        noteData = [noteArray mutableCopy];
        NSLog (@"Restored %i downloaded", [noteData count]);
    } else {
        [noteData removeAllObjects];
        [self.notes setEditing: NO];            
        NSLog (@"No notes to restore");
    }
    [self noteStopActivity];
    [notes reloadData];
}
#define CONTAINS(x,y) ([x rangeOfString: y].location != NSNotFound)

#pragma mark -
#pragma mark XML import

// 
//  The XML parsing of the FCP markers file is done
//  Lets load the markers as notes into the notes table
//

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
        
        // Make sure we get the timecode right
        
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

// Parse FCP XML marker file
-(void) getXML: (NSString *) file
{
    NSLog (@"processing XML file %@", file);
    
    file = [file stringByReplacingOccurrencesOfString: @" " withString:@"%20"];
    
    if (!XMLURLreader)
		XMLURLreader = [[XMLURL alloc] init];

    NSString *url;
    if (kBonjourMode) {
        url = [NSString stringWithFormat: @"/xml/%@", kHTTPserver, file];
    }

    NSLog(@"Getting FCP XML marker file at: %@", url);
    // This is the guy that will parse the XML.  The XMLDone: method will get called when
    // the parsing has been completed
	
	[XMLURLreader parseXMLURL: url atEndDoSelector: @selector (XMLDone:) withObject: self];
}

// Look at all the notes in the noteData array and just get mine to archive and upload
// to the server or store locally

-(NSMutableArray *) getMyNotes
{
    NSMutableArray *myNotes = [[NSMutableArray alloc] init];
    
    for (Note *aNote in noteData) 
        if (allStills) {
            if ([aNote.imageName isEqualToString: clip] && [aNote.initials isEqualToString: initials])
                [myNotes addObject: aNote];
        }
        else if ([aNote.initials isEqualToString: initials]) 
            [myNotes addObject: aNote];
    
    return myNotes;
}

// Store my notes on the server or locally (if no server connection)

-(void) storeData  {
    NSMutableArray *myNotes = [self getMyNotes];
    NSString *archivePath = [self archiveFilePath];
        
    // Write the notes to a local archive file first
    if ([NSKeyedArchiver archiveRootObject: myNotes toFile: archivePath] == NO) {
        [myNotes release];
        [UIAlertView doAlert: @"Notes" 
                     withMsg: @"Couldn't save your notes locally!"];
        NSLog (@"Save failed");
    } else if (kBonjourMode) { // Upload the notes with HTTP
        [myNotes release];
        NSString *remotePath = [NSString stringWithFormat:@"%@/note/%@", kHTTPserver, [archivePath lastPathComponent]];
        [self uploadFile:archivePath to:remotePath];
    }
}


-(void) clearAnyNotes
{
    [noteData removeAllObjects];
    [self.notes setEditing: NO];
    [notes reloadData];
}


#pragma mark -
#pragma mark FCPPro export

// 
// Export the notes in XML format
// This is for FCP support
// The XML file is created locally and will be attached to any emails
// sent for this clip
//

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
    <name>Scribbeo #%i</name>\n\
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
    
    // Write the XML out to a local file - Note that we should do this to the same file each
    // time (or at least to a tmp file) so that the local file systems doesn't fill up with old files
    
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
}


#pragma mark -
#pragma mark Avid Locator import/export

//
// Write the notes into a Locator file
// The file will be added as an attachment to any emails
// (If the appropriate option is selected)
//
                                   

-(NSString *) exportAvid
{
    if ( ! AvidExport || ! [noteData count])
        return nil;
        
    NSMutableString *LocatorString = [NSMutableString string]; 
    
    int marker = 1;
    
    for (Note *aNote in noteData) {
        [LocatorString appendString: 
        [NSString stringWithFormat: @"Scribbeo #%i\t%i\tred\t%@\n", marker, 
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

// 
// Parse the downloaded Avid markers file
// Note we do this one line at a time
// Fields are tab-delimited
//


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
        // Create a new note to store the parsed data
        
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
            // Put the note into the table in the correct order
            
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
            
            // Insert the note into the array (and table)
            
            [noteData insertObject: AvidNote atIndex: row];
        }
            
        [AvidNote release];
    }
    
    // Remove downloaded file
    
    [[NSFileManager defaultManager] removeItemAtPath: [self txtFilePath] error: NULL];
    
    [notes reloadData];
    return locators;
}

//
// We have a txt file, presumably with Avid markers
// We'll download the file and then parse it in the previous method
// (Doesn't look like this is actually called anywhere... Did we stop supporting this halfway?)
-(void) getAvid: (NSString *) file
{
    NSLog (@"processing Avid import file %@", file);
    NSString *remotePath = [NSString stringWithFormat:@"%@/avid/%@", kHTTPserver, file];
    // Make sure we don't need to URI-encode... Can't test right now since nobody is calling this method.
    NSURL *remoteURL = [NSURL URLWithString:remotePath];
    NSString *avidTxtFile = [NSString stringWithContentsOfURL:remoteURL encoding:NSUTF8StringEncoding error:nil];    
    [avidTxtFile writeToFile:[self txtFilePath] atomically:YES encoding:NSUTF8StringEncoding error:nil];
    // remember to get rid of error:nil & do real checks
    NSLog (@"Avid txt download returned...in process");  
}


#pragma mark -
#pragma mark PDF, email and printing

//
// The print button
//

// This method handles printing the notes to an AirPrint printer
// We first generate the notes in PDF format
// before dispatching to a printer

-(IBAction) printNotes
{
    if (! [noteData count])   // make sure there's something to print!
        return;
    
    isPrinting = YES;
    
    // Generate the PDF file for printing
    
    [self saveToPDF];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *saveDirectory = [paths objectAtIndex:0];
    NSString *saveFileName = @"Notes.pdf";
    NSString *newFilePath = [saveDirectory stringByAppendingPathComponent:saveFileName];
    
    // Convert the PDF file to NSData
    
    NSData *myData = [NSData dataWithContentsOfFile: newFilePath];
    
    // Create and present a printer interface dialog
    
    UIPrintInteractionController *pic = [UIPrintInteractionController sharedPrintController];
    
    if ( pic && [UIPrintInteractionController canPrintData: myData] ) {
        pic.delegate = self;
        
        // Set up various options for printing
        
        UIPrintInfo *printInfo = [UIPrintInfo printInfo];
        printInfo.outputType = UIPrintInfoOutputGeneral;
        printInfo.jobName = @"Scribbeo Notes";
        printInfo.duplex = UIPrintInfoDuplexLongEdge;
        pic.printInfo = printInfo;
        pic.showsPageRange = YES;
        pic.printingItem = myData;
        
        // Define the completion handler block
        
        void (^completionHandler)(UIPrintInteractionController *, BOOL, NSError *) = ^(UIPrintInteractionController *pic, BOOL completed, NSError *error) {
            //self.content = nil;
            if (!completed && error) {
                [UIAlertView doAlert: @"Printing" 
                             withMsg: @"An error occurred while trying to print"];
                NSLog(@"Failed due to error in domain %@ with error code %u", error.domain, error.code);
            } 
        };
        
        // Take it away...
        
        [pic presentAnimated:YES completionHandler: completionHandler];
    }
	
    isPrinting = NO;
}

#pragma mark -
#pragma mark Email related

-(BOOL) canEmail
{
    NSLog(@"Checking if user has an email account set up...");
    if (! [MFMailComposeViewController canSendMail]) {
        [UIAlertView doAlert: @"Email" 
                     withMsg: @"You need to setup an email account"];
        NSLog(@"Nope. Displayed alert to user");
        return NO;
    } else {
        NSLog(@"Yes, proceeding with email process");
        return YES;
    }
}

// 5 touches to pull up logfile emailer
- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event 
{
    // Here we can check the number of taps
    int taps = [[touches anyObject] tapCount];
    // Look at the start of the method to interpret the tap count
    if (taps == 5) {
        NSLog(@"5 taps, erasing view, launching logfile emailer");
        [[kAppDel viewController] erase];
        if ([self canEmail]) [self emailLogfile];
        return;
    }
}

- (void) emailLogfile
{
    NSLog(@"Want to email the log file. Where is the log file?");
    NSArray *paths = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *saveDirectory = [paths objectAtIndex:0];
    NSString *logFilePath = [NSString stringWithFormat: @"%@/logfile.%@.txt", saveDirectory, [[UIDevice currentDevice] uniqueIdentifier]];
    // Located the log file, now let's send it if it truly exists, else do nothing.
    if (![[NSFileManager defaultManager] fileExistsAtPath:logFilePath]) {
        NSLog(@"Log file does not exist where expected (%@) Will not continue with email.", logFilePath);
        return;
    }
	MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
	picker.mailComposeDelegate = self;
    [picker setSubject:@"Bug Report"];
    NSArray *toRecipients = [NSArray arrayWithObject:@"keyvan@digitalfilmtree.com"]; // needs to be changed to support@scribbeo.com or something official
    [picker setToRecipients:toRecipients];
    NSData *myData = [NSData dataWithContentsOfFile: logFilePath];
    [picker addAttachmentData: myData mimeType: @"text/plain" 
                     fileName: [logFilePath lastPathComponent]];
    [picker setMessageBody:@"Please give as much information as possible below so that we can locate and resolve any issue you are experiencing with the app. A debug log will also be sent with this email.\n\n" isHTML:NO];
    [self presentModalViewController: picker animated:YES];
    [picker release];
}


// So previously, when the server was a static install, we were uploading the email HTML to the server so as to provide a link
// But now the bonjour server can be on some local machine, not static, change ip/port on a whim. We can't create a link for it.
// So we won't upload it or anything--we need to send the entire note package at once with all relevant info, no links.
// -------- However, for now we don't have a good solution yet, so we'll use HTTP to upload in the old way for now...
-(IBAction) emailNotes
{
    if (! [self canEmail]) return;
    
    NSString *emailBody;
    
    if (emailPDF) 
        [self saveToPDF];
 
	MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
	picker.mailComposeDelegate = self;
    
    // set the subject line for the email
	
    NSString *noteName;
    
    if (! allStills) 
        noteName = [[clip stringByReplacingOccurrencesOfString: @"%20" withString:@" "]
                    stringByDeletingPathExtension];
    else
        noteName = [NSString stringWithFormat: @"Album %@", [[[clipPath stringByReplacingOccurrencesOfString: @"%20" withString:@" "] stringByDeletingLastPathComponent] lastPathComponent]];
         
	[picker setSubject: [NSString stringWithFormat: @"Notes for %@ %@ %@", noteName,  (FCPXML) ? @"(FCP XML attached)" : @"", 
                         (AvidExport) ? @"(Avid Locator file attached)" : @""]];
    
	// Set up recipients
    
	//NSArray *toRecipients = [NSArray arrayWithObject: @"keyvan@digitalfilmtree.com"];  // testing
	NSArray *ccRecipients = [NSArray array];
	NSArray *bccRecipients = [NSArray array];
	
	//[picker setToRecipients: toRecipients];
	[picker setCcRecipients: ccRecipients];	   // empty here
	[picker setBccRecipients: bccRecipients];  // ditto
    
    // Attach FCP XML if option is selected
    
    if (FCPXML) {
        NSString *file = [self exportXML];
        
        if (file) {
            NSData *myData = [[NSData alloc] initWithContentsOfFile: file];
            [picker addAttachmentData: myData mimeType: @"text/xml" 
                             fileName: [file lastPathComponent]];
            [myData release];
        }
    }
	
    // Attach Avid Locator file if option is selected
    
    if (AvidExport) {
        NSString *file = [self exportAvid];
        
        if (file) {
            NSData *myData = [[NSData alloc] initWithContentsOfFile: file];
            [picker addAttachmentData: myData mimeType: @"text/plain" 
                             fileName: [file lastPathComponent]];
            [myData release];
        }
    }
    
    // Send the notes in either PDF or HTML format
        
    if (emailPDF) {
        // Attach the PDF file to the email
        
        NSArray  *paths = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *saveDirectory = [paths objectAtIndex:0];
        NSString *saveFileName = @"Notes.pdf";
        NSString *newFilePath = [saveDirectory stringByAppendingPathComponent:saveFileName];
        
        NSData *myData = [[NSData alloc] initWithContentsOfFile: newFilePath];
        [picker addAttachmentData:myData mimeType:@"application/pdf" fileName:@"Notes.pdf"];
        [myData release];

        // Fill out the email body text
        
        emailBody = [NSString stringWithFormat: @"Sent from Scribbeo™ for %@", (iPHONE ? @"iPhone" : @"iPad")];
        
        [picker setMessageBody:emailBody isHTML:NO];
    }
    else  {
        NSString *theTitle = @"";
        
        //  NSString *theTitle = [
        //    [clip stringByReplacingOccurrencesOfString: @"_" withString: @" : "]
        //    stringByReplacingOccurrencesOfString: @"%20" withString:@" "];
        
        NSString *saveFileName = [NSString stringWithFormat: @"%@_%lu.html", initials, (long) [NSDate timeIntervalSinceReferenceDate]];
        
        NSString *remotePath = [NSString stringWithFormat: @"%@/email/%@", kHTTPserver, saveFileName]; 
        
        emailBody =  [NSString stringWithFormat: 
                      @"<html>Sent from Scribbeo™ (v%@.%@), \u00A9 2011-2012 by DigitalFilm Tree<br><p>",                         
                      [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"],  
                      [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]];
        
        // Upload the HTML file to the server (as long as we use ftp and http from the same place)
        // And place a hyperlink in the emailed HTML
        
        emailBody = [emailBody stringByAppendingString: 
                         [NSString stringWithFormat: @"<a href=\"%@\">Click here to view this page in your browser.</a><p>%@</p>", remotePath, theTitle]];
        
        emailBody = [emailBody stringByAppendingString: [self saveToHTML]];
        [picker setMessageBody:emailBody isHTML:YES];
        
        [self uploadHTML: emailBody file: saveFileName];

    }
	
	[self presentModalViewController: picker animated:YES];
    [picker release];
}

// Dismisses the email composition interface when users tap Cancel or Send. Proceed to update the message field with the result of the operation.

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
    
    // display message to user here (note: we're not doing that!)
    
	[self dismissModalViewControllerAnimated:YES];
}

-(NSString *) hexFromData:(NSData *)data
{
    NSString *result = [[data description] stringByReplacingOccurrencesOfString:@" " withString:@""];
    result = [result substringWithRange:NSMakeRange(1, [result length] - 2)];
    return result;
}

//
// We need to encode the images in base64 for inclusion directly in the HTML
//

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
            NSData *encodedData = [NSData dataWithBytes:base64Encoded length:base64EncodedLength];
            NSString *base64EncodedString = [[NSString alloc] initWithData:encodedData encoding:NSUTF8StringEncoding];
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
   NSString *result = [NSString stringWithFormat: @"<center><img height=175 src=\"data:image/jpeg;base64,%@\"></center>", 
                       [self base64EncodedString: theNote.thumb ]];
    return result;
}   

// Save the notes in HTML format                     
-(NSMutableString *) saveToHTML {
        NSMutableString *emailBody = [NSMutableString string];
        [emailBody appendString: @"<table border=2 cellpadding=10 cellspacing=10>"];
        
        noteNumber = 1;
        NSLog (@"emailing %lu notes", [noteData count]);

        for (Note *theNote in noteData) {
            [emailBody appendString: [self noteToHTML: theNote]];
            ++noteNumber;
        }
        
       [emailBody appendString: [NSString stringWithFormat: @"</table><p>Sent from Scribbeo™ for %@",
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
    
    comment = [comment stringByReplacingOccurrencesOfString: @"<<<Audio Note>>>" withString: @""];
    
    comment = [[comment stringByReplacingOccurrencesOfString:  @"<" withString: @"&lt;"] stringByReplacingOccurrencesOfString: @">" withString: @"&gt;"];
    
    // output the note
    
    if (! theNote.imageName ) {
        NSString *timeFormat = (timecodeFormat) ? theNote.timeStamp :
        [self timeFormat: kCMTimeMakeWithSeconds ([self convertTimeToSecs: theNote.timeStamp] - startTimecode) ];
        
        [emailBody appendString: [NSString stringWithFormat: @"<td valign=top>%@&nbsp;&nbsp;&nbsp;%@&nbsp;&nbsp;&nbsp;%@&nbsp;&nbsp;&nbsp;<p></p>%@", 
                    timeFormat, theNote.date, theNote.initials, comment]];
    }
    else {
        NSString *image = [[theNote.imageName lastPathComponent] stringByDeletingPathExtension];
        
        [emailBody appendString: [NSString stringWithFormat: @"<td valign=top><b>%@</b><br>%@&nbsp;&nbsp;&nbsp;%@&nbsp;&nbsp;&nbsp;&nbsp;<p></p>%@", 
                                 image, theNote.initials, theNote.date, comment]];
    }
        
    
    // audio -- upload to server and embed in HTML
    
    if (theNote.voiceMemo && kBonjourMode) {
        NSString *addr = [self uploadAudio: theNote];
        
        [emailBody appendString: [NSString stringWithFormat: @"<br><br><br><center><object type=\"audio/mpeg\" data=\"%@\"\
             width=\"175\" height=\"25\" alt=\"Audio link\" autoplay=false></object></center>", addr]];  
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
        text = "Created by Scribbeo™ iPhone App.  Copyright \251 2010-2012 by DigitalFilm Tree.";
    else
        text = "Created by Scribbeo™ iPad App.  Copyright \251 2010-2012 by DigitalFilm Tree.";

    CGContextShowTextAtPoint (pdfContext, 25 + CGImageGetWidth (ref) / 5 + 15, .65 inches, text, strlen(text));
//  text = "VideoTree is a trademark of DFT Software.";
//  CGContextShowTextAtPoint (pdfContext, 25 + CGImageGetWidth (ref) / 5 + 15, .65 inches - 10, text, strlen(text));
}

// Reusable HTTP Upload via POST
-(NSString *) uploadFile: (NSString *) localPath to: (NSString *) remotePath
{
    NSLog(@"uploadFile is POSTing data from: %@ to server: %@", localPath, remotePath);
    NSString *remoteURL = [remotePath stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    NSURL *url = [NSURL URLWithString:remoteURL];
    NSData *postData = [NSData dataWithContentsOfFile:localPath];
    NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-gzip" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];
    [NSURLConnection connectionWithRequest:request delegate:self];
    [request release];
    return remoteURL;
}

//
// Uploads the full HTML Notes to the server
//
-(void) uploadHTML: (NSString *) theHTML file: (NSString *) fileName
{
    NSLog(@"uploadHTML, filename: %@", fileName);
    // Save the audio file and upload to the server
    NSArray *dirList = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDir = [dirList objectAtIndex: 0];
    
    NSString *HTMLPath = [docDir stringByAppendingPathComponent: fileName];
    
    if (! [theHTML writeToFile: HTMLPath atomically: NO encoding: NSUTF8StringEncoding error: NULL]) 
        NSLog (@"Save of HTML file failed!");
    
    [self uploadFile:HTMLPath to:[NSString stringWithFormat:@"%@/email/%@", kHTTPserver, fileName]];
    NSLog(@"HTML Uploaded");
}

//
// Upolaoads an audio note to the server as an aac file for playback from the HTML or PDF notes
//
-(NSString *) uploadAudio: (Note *) aNote
{
    // Save the audio file and upload to the server
    NSArray *dirList = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *docDir = [dirList objectAtIndex: 0];
    
    // If the audio link is in a PDF file, we need to use the .mov.aac extension for proper playback
    // We'll write the audio clip to a local file first before uploading
    
    NSString *fileName = [NSString stringWithFormat: @"%@_%i_%@.%@", [clip stringByDeletingPathExtension], noteNumber, initials, emailPDF ? @"mov.aac" : @"aac"];  // DUH!
    NSLog (@"Audio file name = %@", fileName);
    NSString *audioPath = [docDir stringByAppendingPathComponent: fileName];
    
    if (! [aNote.voiceMemo writeToFile: audioPath atomically: NO]) 
        NSLog (@"Save of audio file failed!");

    NSString *remotePath = [NSString stringWithFormat:@"%@/email/%@", kHTTPserver, fileName];
    return [self uploadFile:audioPath to:remotePath]; 
}


//
// Converts a single note to PDF format -- used pdfContext for the drawing context
//

-(void) noteToPDF: (Note *) aNote {
    const char *noteText = [[aNote.text stringByReplacingOccurrencesOfString: @"<CHAPTER>" withString: @""] UTF8String];
    
    NSString *timeFormat = (timecodeFormat) ? aNote.timeStamp :
        [self timeFormat: 
           kCMTimeMakeWithSeconds ([self convertTimeToSecs: aNote.timeStamp] - startTimecode) ];
    
    const char *noteTime = [timeFormat UTF8String];
    char date [100];
    const char *who = [aNote.initials UTF8String];

    strcpy (date, [aNote.date UTF8String]);
    
    // We'll use the thumbnail for the note image....the quality is acceptable
    
    UIImage *theImage = [UIImage imageWithData: aNote.thumb];
    float wid = theImage.size.width;
    float ht = theImage.size.height;
    
    wid =  (150 / ht) * wid;
    ht = 150;
    
    CGContextDrawImage (pdfContext, CGRectMake (40, currentY - 155, wid, ht), theImage.CGImage);

    // Fill in the usual suspects for the note info: date/time stamp, initials, note text
    
    if (! aNote.imageName) {
        CGContextSelectFont (pdfContext, "Helvetica-Bold", 12, kCGEncodingMacRoman);
        CGContextSetRGBFillColor (pdfContext, 1, 0, 0, 1);
        CGContextShowTextAtPoint (pdfContext, 330, currentY - 20, noteTime, strlen(noteTime));
    }
    else {
        const char *image = [[[aNote.imageName lastPathComponent] stringByDeletingPathExtension] UTF8String];
        CGContextSelectFont (pdfContext, "Helvetica-Bold", 12, kCGEncodingMacRoman);
        CGContextSetRGBFillColor (pdfContext, 1, 0, 0, 1);
        CGContextShowTextAtPoint (pdfContext, 330, currentY - 20, image, strlen(image));
    }
    
    CGContextSelectFont (pdfContext, "Helvetica", 12, kCGEncodingMacRoman);
    CGContextSetRGBFillColor (pdfContext, 0, 0, 1, 1);
 
    char *dateInitials = strcat (strcat (date, "   "), who);
    CGContextShowTextAtPoint (pdfContext, 490, currentY - 20, dateInitials, strlen(dateInitials));
    CGContextSetRGBFillColor (pdfContext, 0, 0, 0, 1);
    
    // I think there's an easier way to do the line wrapping for the note.... I chose the hard way!
 
    CGContextShowMultilineText (pdfContext, noteText, currentY - 40);
    
    // If there's an audio note, upload the note and insert the hyperlink....but note if we're printing!
    
    if (aNote.voiceMemo && kBonjourMode && !isPrinting) {
        NSURL *addr = [NSURL URLWithString: [self uploadAudio: aNote]];
                       
        CGPDFContextSetURLForRect (pdfContext, (CFURLRef) addr, CGRectMake (330, currentY - 140, 100.0, 20.0));
        CGContextSetRGBFillColor (pdfContext, 0, 0, 1, 1);
        CGContextShowTextAtPoint (pdfContext, 330, currentY - 140, "Click to Hear Note", strlen("Click to Hear Note"));
    }
    
    // Time for a new page?

    if (noteNumber % 4) {
        // Draws a line separator for the note
        CGContextMoveToPoint (pdfContext, 25, currentY - 165);
        CGContextAddLineToPoint (pdfContext, pageRect.size.width - 25, currentY - 165);
        CGContextStrokePath (pdfContext);
    }
    
    currentY -= 170;
}

// All done generating the PDF
     
-(void) closePDFFile
{     
     // We are done with our context now, so we release it
    CGContextRelease (pdfContext);
}

//
// This is my brute force approach to word wrapping the text....uggh, there's gotta be a better way!
//

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
    
    // Word wrap code... enuf said
    
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
         
        // How far to the right are we going?
        
        CGContextSetTextDrawingMode (pdfContext, kCGTextInvisible);
        CGContextShowText (pdfContext, &noteText [saveI], wordSize);
        whereTo = CGContextGetTextPosition (pdfContext);
        
        // Do we need to wrap the line?
        
        if (whereTo.x > rightMargin) {
            currentPoint.x = leftMargin;
            currentPoint.y -= 15;

            while (isspace (noteText[saveI])) 
                ++saveI;
        }
        
        wordSize = i - saveI;
        
        // Draw the text on the current line or at the beginning of the next line
        
        CGContextSetTextPosition (pdfContext, currentPoint.x, currentPoint.y);
        CGContextSetTextDrawingMode (pdfContext, kCGTextFill);
        CGContextShowText (pdfContext, &noteText [saveI], wordSize);
        currentPoint = CGContextGetTextPosition (pdfContext);
    }
}    

         
#pragma mark -
#pragma mark scrubber

// Format the time either in timecode or absolute frame number format

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
        long frames  =  secs * theFPS + .4999;   // round up?
                        
        if (frames <= 0)
            time1 = @"0";
        else {
            time1 = [NSString stringWithFormat: @"%li", frames];
            // 1NSLog (@"time = %g, frame = %@, fps = %i", secs, time1, theFPS);
        }
    }
    
    return time1;
}

// Take an NSString in xx:xx:xx:xx format and convert it to a floating
// point number

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

// Format the current date.  The argument says whether to include
// the time in the format as well

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

// Scrubbing started

- (void)sliderDragBeganAction
{
	isSeeking = YES;
    saveRate = player.rate;

    player.rate = 0;
    seekToZeroBeforePlay = NO;
    newNote.text = @"";
    [self erase];
}

// Scrubbing ended

- (void)sliderDragEndedAction
{
	isSeeking = NO;
    player.rate = saveRate;
    
    if (player.rate != 0)
        pausePlayButton.image = pauseImage;
    else
        pausePlayButton.image = pauseImage;
}

// Scrubbing in-process.  Seek to the time indicated by the scrubber's relative position from 0 to 1.

- (void)sliderValueChange
{
    Float64 playerTime = movieTimeControl.value * kCVTime ([[[player currentItem] asset] duration]); 
    
 	[player seekToTime: kCMTimeMakeWithSeconds(playerTime)];
}

//
// Update the displayed time as a timecode or frame number
// Note that there's a lot of first time things that happen
// in this method (should probably be moved elsewhere)
//

- (void) updateTimeControl
{
    AVAsset *asset = [[player currentItem] asset];

    if (!asset)
		return;
    
    // If we never set the frame rate, then let's initialize some stuff
    // If it's a local file, let's try to get the star timecode
    // (doesn't work for any non-local media files)
    
    if (fps < 0.001) {
        NSArray *tracks = [asset tracks];
        
        NSLog2 (@"[tracks count] == %i, %@", [tracks count], tracks);

        if ([tracks count] > 0) {
            NSArray *tracks = [asset tracksWithMediaType: AVMediaTypeVideo];
            
            if ([tracks count] > 0) {
                fps = [[tracks objectAtIndex: 0] nominalFrameRate];

                if (fps > 0.0) 
                    NSLog (@"nominal frame rate fps = %f", fps);
            }
         }
        
        //
        // We've had to kludge the timecode for nonlocal files since
        // we can't seem to get it out of the timecode track.  The 
        // solution was to create a separate .tc file
        // Update: Timecode is now being sent along with the list of files from the HTTP server.
        //
        
        if (! kBonjourMode) { // Only local mode can do this since we're using AVAssetReader
            NSLog (@"trying to read start time code");
            startTimecode = [self getStartTimecode]; // AVAssetReader, local only
        }
        
        // If we haven't set the frame rate by now, something has gone
        // horribly wrong
        
        if (fps == 0) {
            // FIXME something might be weird here, where is fps getting set?
            [self cleanup];
            [UIAlertView doAlert:  @"Error" withMsg:
                 @"Trouble playing the movie--you may not have permission"];
        
            return;
        }
	}

    // Set the clips duration
    
    double duration = 0.0;
        
    if (! durationSet) {
        endOfVid = player.currentItem.asset.duration; // [asset duration];
	    duration = kCVTime (endOfVid);
        
        Float64 theEnd = duration;
        
        if (timecodeFormat)
            duration += startTimecode;

        NSLog(@"UpdateTimeControl has incremented the duration (%f) by the startTimecode (%f)", theEnd, startTimecode);
        
        // If we have a meaningful duration set, set the min/max times at the ends of the scrubber
        
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
    
    // Set the scrubber to the current time as a percentage of the duration
    
    if (! isfinite (duration))
        duration = 0;
    else
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

//
// This method will look for a timecode track in the current video clip
// If it finds one, it will attempt to read and decode the timecode
// This is done with AVAssetReader
// Note that AVAssetReader does not work with streams or even non-local video files
// (bug report has been filed with Apple but never addressed)
//

-(Float64) getStartTimecode
{
    if (!player)
        return 0.0;
    
    // Look for the timecode track
            
    NSArray *tcTracks = [player.currentItem.asset tracksWithMediaType:AVMediaTypeTimecode]; 
    
    if (![tcTracks count]) {
        NSLog (@"no timecode track");
        return 0.0;
    }
    
    // Set up a reader to read the track
        
    NSError *error;

    AVAssetReader *assetReader = [[AVAssetReader alloc] initWithAsset: player.currentItem.asset error: &error];
    
    if (error) {
        NSLog (@"error initializing AVAssetReader: %@", error);
        [assetReader release];
        return 0.0;
    }
    
    // Set up the output for the track
 
    AVAssetTrack *tcTrack = [tcTracks objectAtIndex: 0];
    AVAssetReaderTrackOutput *assetReaderOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack: 
                                                   tcTrack outputSettings: nil];
  
    // We're going to read in the Sample Buufer
    
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
    
    //
    // This loop is setup to read the entire Sample Buffer.  
    // However the first read is really good enough for us
    //
    
    while ( [assetReader status] == AVAssetReaderStatusReading || 
           [assetReader status] == AVAssetReaderStatusUnknown ) {
        buffer = [assetReaderOutput copyNextSampleBuffer];
        
        long out;
        
        // If we read the data, we need to decode the starting timeocde and we're done!
        
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
    
    // Sorry, it didn't work
    
     NSLog (@"getStartTimecode returning 0.0");
    [assetReader cancelReading];
    [assetReader release];
    [assetReaderOutput release];
    return 0.0;
}

//
// Debugging aid; not call is currently commented out
//

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

// 
// This method is used to put the app back to a "sane" state
// We don't do anything unless we have an active video clip or a still showing
// For a still, we'll remove its display, and clear any markups and notes
// If the sideshow timer is running, we'll stop it
// For a video, we'll pause it, remove the clip from playback, remove any observers, stop any activity indicators
// We'll also leave fullScreen or airPlay modes if active
//

-(void) cleanup
{
    NSLog (@"cleaning up");

    noteTableSelected = NO;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                        name:AVPlayerItemDidPlayToEndTimeNotification  object:nil];
    
    if (watermark)
        [stampLabel removeFromSuperview];

    if (stillShows) {
        if (slideshowTimer) {
            [slideshowTimer invalidate];
            self.slideshowTimer = nil;
        }
        
        [stillView removeFromSuperview];
        stillShows = NO;
        drawView.frame = drawViewFrame;
        [self erase];
        [self clearAnyNotes];
        newNote.text = @"";
        
        // hide buttons that don't apply
        
        theTime.hidden = NO;
        myVolumeView.hidden = NO;
        backgroundLabel.hidden = NO;
        movieTimeControl.hidden = NO;
        maxLabel.hidden = NO;
        minLabel.hidden = NO;
        rewindToStartButton.enabled = YES; 
        frameBackButton.enabled = YES; 
        frameForwardButton.enabled = YES; 
        forwardToEndButton.enabled = YES; 
        rewindButton.enabled = YES;
        fastForwardButton.enabled = YES;
        //  pausePlayButton.enabled = NO;
        
        skipForwardButton.enabled = YES;
        skipBackButton.enabled = YES;
        skipForwardButton.title = [NSString stringWithFormat: @"+%i", skipValue];
        skipBackButton.title = [NSString stringWithFormat: @"-%i", skipValue];;
        
        return;
    }
    
    if (!player)
        return;
    
    newNote.text = @"";
    [self stopObservingTimeChanges];

    [player removeObserver: self forKeyPath:@"rate"];
    [player removeObserver: self forKeyPath:@"currentItem.status"];
    [player removeObserver: self forKeyPath:@"currentItem.asset.duration"];
    [player removeObserver: self forKeyPath:@"currentItem.asset.commonMetadata"];
    
    if (kRunningOS5OrGreater) 
        [player removeObserver: self forKeyPath:@"airPlayVideoActive"];

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

    // Clear any current note or markup

    [self clearAnyNotes];
    [self erase];
    [drawView setNeedsDisplay];

    // Get rid of our player

    self.playerLayer.player = nil; // this is the trick !
    [self.playerLayer removeFromSuperlayer];
    self.playerLayer = nil;
    self.currentlyPlaying = nil;
    player = nil;

    // We shouldn't be recording

    if ([voiceMemo audioRecorder].isRecording)            
        [voiceMemo stopRecording];

    recording.hidden = YES;

    // Reset various vars to sane values

    fps = 0;
    isPrinting = NO;
    movieTimeControl.value = 0;
    durationSet = NO;
    theTime.text = [self timeFormat: kCMTimeZero];
    maxLabelSet = NO;  
    startTimecode = 0.0;
    maxLabel.text = [self timeFormat: kCMTimeZero];
    minLabel.text = [self timeFormat: kCMTimeZero];
}

-(NSURL *) getTheURL: (NSString *) thePath
{
    thePath = [thePath stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    NSURL  *theURL = (NSURL *) thePath;
    
    // Generate an NSURL object from the argument if it's a string 
    // (Otherwise assume it's already an NSURL)

    if ([thePath isKindOfClass: [NSString class]]) {
        NSRange network = [thePath rangeOfString: @"http:"];
        
        if (network.location == NSNotFound)
            network = [thePath rangeOfString: @"https:"];
        if (network.location == NSNotFound)
            network = [thePath rangeOfString: @"file:"];
        
        if (network.location == NSNotFound) {
            NSLog (@"Loading movie/still %@", thePath);
            
            if ([thePath rangeOfString: @"Simulator"].location != NSNotFound)
                theURL = [[NSURL alloc] initFileURLWithPath: [[NSBundle mainBundle] pathForResource: @"31-1A" ofType:@"m4v"]];
            else
                theURL = [[NSURL alloc] initFileURLWithPath: thePath];
        }
        else {
            NSLog (@"Loading movie/still %@ from Internet or camera roll", thePath);
            theURL = [NSURL URLWithString: thePath];
        }
    }

    return theURL;
}

//
// This is the method responsible for initiating playback of a video clip
// We use the AVPlayer class for this
//

- (void)loadMovie: (id) theMovie
{
    
    
    editButton.title = @"Edit";

    if (player || stillShows) {
        NSLog(@"Player or still shows -- cleanup");
        [self cleanup];
    } else
        [self erase];
    
    if (iPHONE) {
        UINavigationController  *nc = [(VideoTreeAppDelegate *) [[UIApplication sharedApplication] delegate] nc];
        nc.view.hidden = YES;
    }
    
    if (kRunningOS5OrGreater) {
        playOutButton.enabled = NO;
    }
    else {
        playOutButton.image = [UIImage imageNamed: @"playout.png"];
        playOutButton.enabled = YES;
    }

    self.currentlyPlaying = [theMovie retain];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                name:AVPlayerItemDidPlayToEndTimeNotification  object:nil];

   
    self.movieURL = [self getTheURL: theMovie];
    self.mediaPath = theMovie;
    
#if 0
    // This never worked!
    
    NSError *error;
    
    if ([movieURL checkResourceIsReachableAndReturnError: &error] == NO) 
        NSLog (@"Can't load from the URL: %@", error);  // Display an alert here
#endif
    
    if (! movieURL) 
        return;

    self.clip = [theMovie lastPathComponent];
    NSLog(@"loadMovie sees self.clip as %@", self.clip);
    [self showActivity];        // Get the spinner going while we load the movie

    if (kBonjourMode) {
        [self getAllHTTPNotes];
    } else { 
        if (!allStills)
            [self loadData: [NSString stringWithFormat: @"%@.%@", 
                    [clipPath stringByReplacingOccurrencesOfString: @"/" withString: kNoteDelimiter], initials]];   
        else
            ;  //  Need to get the local notes for all images in the album here
    }
    
    // Create the movie asset and get the tracks keys
    NSLog(@"We will load the AVURLAsset with this movieURL: %@", movieURL);
    NSMutableDictionary *optionsDict = [NSMutableDictionary dictionaryWithObjectsAndKeys: 
            [NSNumber numberWithBool: YES], AVURLAssetPreferPreciseDurationAndTimingKey, nil];
    self.theAsset = [AVURLAsset URLAssetWithURL: movieURL options: optionsDict];
    NSString *tracksKey = @"tracks";
    
    // We need some keys; we get them asynchronously
    
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
         
        // Do we have a player now and something to play?

        if (player && playerItem)
        {
            NSLog(@"player and playerItem exist");
            // Tell us if we reach the end
            
            [[NSNotificationCenter defaultCenter]
                 addObserver:self
                 selector:@selector(itemDidPlayToEnd:)
                 name:AVPlayerItemDidPlayToEndTimeNotification
                 object:playerItem];
            
            seekToZeroBeforePlay = NO;
            
            // Yeah, we want airPlay enabled
            
            if (kRunningOS5OrGreater)
                [player setAllowsAirPlayVideo: YES];
            
            // Tell us when the playback rate changes
            
            [player addObserver:self forKeyPath:@"rate" options: NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context: VideoTreeViewControllerRateObservationContext];
            
            if (kRunningOS5OrGreater) {
                [player addObserver:self forKeyPath:@"airPlayVideoActive" options: NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context: VideoTreeViewControllerAirPlayObservationContext];
            }
            
            // Tell us about changes in any of the following keys
            
            [player addObserver:self forKeyPath:@"currentItem.status" options: NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context: VideoTreeViewControllerStatusObservationContext];
            [player addObserver:self forKeyPath:@"currentItem.asset.duration" options: NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context: VideoTreeViewControllerDurationObservationContext];
            [player addObserver:self forKeyPath:@"currentItem.asset.commonMetadata" options: NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context: VideoTreeViewControllerCommonMetadataObserverContext];           

            // Set up the playerLayer for playback
            
            self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:player]; 
            [player release];

            playerLayerView.hidden = NO;
            playerLayer.frame = playerLayerView.layer.bounds;
            [playerLayerView.layer addSublayer:playerLayer];
            playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;  // maintain aspect ratio
            
            // Let's add the drawView and make sure it's on top

            drawView.frame = playerLayer.frame;
            [playerLayerView addSubview: drawView];
            [self.view bringSubviewToFront: drawView];
            
            if (kRunningOS5OrGreater) {
                NSLog (@"setting up player, airPlayVideoActive = %i", [player isAirPlayVideoActive]);
            
                if ([player isAirPlayVideoActive])
                    airPlayImageView.hidden = NO;
                else
                    airPlayImageView.hidden = YES;
            }
            
            // If we're watermarking, make our view visible
            
            if (watermark) {
                [playerLayerView addSubview: stampLabel];
                [playerLayerView bringSubviewToFront: stampLabel];
                self.stampLabel.hidden = NO;
            }
            else
                self.stampLabel.hidden = YES;
        }
        else
            NSLog (@"Failed to initiliaze the movie player!");
 
#if 0
         // Lots of cool info about the video clip
         
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
         NSLog2 (@"reverse playback end time = %@", [self timeFormat: player.currentItem.reversePlaybackEndTime]); 
         NSLog2 (@"forward playback end time = %@", [self timeFormat: player.currentItem.forwardPlaybackEndTime]);
         NSLog2 (@"timed metadata = %@", player.currentItem.timedMetadata); 
#endif

         NSLog (@"playbackLikelyToKeepUp = %i", player.currentItem.isPlaybackLikelyToKeepUp);

         NSLog(@"loadMovie calling directlySetStartTimecode for timecode: %@", [self timeCode]);
         [self directlySetStartTimecode: [self timeCode]];
         
         if (airPlayMode) 
             [self airPlayWork];
    } ];
}

// Make sure the play/pause button matches the current state of playback

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

//
// The airPlay (play ouy) button
// This button is only needed pre-iOS 5.0
// because AVPlayer class did not support airPlay
//
// Note that this button changes to the rotate button
// when showing stills
//

-(IBAction) airPlay
{
    if (stillShows) { 
        [self rotateStill];
        return;
    }
    
    // Remove the "DVD Remote" if it shows
    
    [UIView animateWithDuration: .3 animations: ^{ 
        remote.alpha = 0;
    }];

    runAllMode = NO;
    
    // airPlayWork will do all the work to enable airPlay mode
    
    if (! airPlayMode)  {   // Turn on airPlay mode if off
        [self airPlayWork];
        return;
    }

    // Turn off airPlay mode and return to normal screen
    // Reenable all the disabled buttons and show all the
    // stuff we've hidden
    
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

//
// We need to set up a new MPMoviePlayerController pre iOS 5.0
// in order to support airPlay
//

-(void) airPlayWork
{
    NSLog (@"airPlayWork: airPlayMode = %i", airPlayMode);
    
    [self pauseIt];
    [self movieControllerDetach];
    
    // Create our movie player and register for notifications
    
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
    
    // Hide and disable things on the screen while in this special mode

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

#ifdef iOS42   // This was the hidden API
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

// This will detach the separate movie controller we needed to support
// airPlay (pre iOS 5.0).   Remove the observers, stop the movie and 
// destroy the player

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

// If in autoPlay mode, automatically play the next clip in the table
// Note: this just uses the nextClip method from the DetailViewController class
// to do the work

-(BOOL) nextClip
{
    DetailViewController *dc =  [kAppDel tvc];
    
    NSLog (@"autoplay next clip");
    return [dc nextClip];
}

// Notiication that a clip is done playing (MPMoviePlayer class)
// Play the next clip if in autoPlay mode

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

// This is another notification sent when the MPMoviePlayerController
// changes state

-(void) changeState: (NSNotification*) aNotification {
    MPMoviePlayerController *thePlayer = [aNotification object];
    
    NSLog (@"Movie player changed state: %i", thePlayer.loadState);
    
    if (thePlayer.loadState & MPMovieLoadStateUnknown) 
        NSLog (@"mpmovieplayercontroller status is unknown");
    else if (thePlayer.loadState & MPMovieLoadStatePlayable)         
        NSLog (@"mpmovieplayercontroller movie is playable");
    else if (thePlayer.loadState &  MPMovieLoadStateStalled)
        NSLog (@"mpmovieplayercontroller status is stalled");;
}

//
// Show the navigation controller
// refresh the clip list
//


-(IBAction) showNav
{
    UINavigationController  *nc = [kAppDel nc];
    nc.view.hidden = NO;
    [[kAppDel rootTvc] makeList];
}

//
// The help button (marked ?)
// Display the help screen overlay as a modal view
//

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
    if (!player && !stillShows)
        return;
    
    if (! iPHONE) {
        [[UIApplication sharedApplication] setStatusBarHidden: YES 
                                                withAnimation: UIStatusBarAnimationFade];
        
        UINavigationController  *nc = [(VideoTreeAppDelegate *) [[UIApplication sharedApplication] delegate] nc];
        nc.view.hidden = YES;
    }
    
    if (player) 
        [self pauseIt];
     
    [self erase];

    [UIView animateWithDuration: .3 animations: ^{ 
        playerLayerView.frame = CGRectMake (0.0, 0.0, [UIScreen mainScreen].applicationFrame.size.height, [UIScreen mainScreen].applicationFrame.size.width);
        playerLayer.frame = playerLayerView.frame;
        
        if (stillShows) {
            saveFrame2 = stillView.frame;
            stillView.frame = playerLayerView.frame;
        }
    }];
        
    // We have to hide everything so full screen playback looks nice
    
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
    
    // Put the watermark on the full screen playback if the option is selected
    
    if (watermark && !stampLabelFull) {
        CGRect stampFrame = playerLayerView.frame;
        self.stampLabelFull = [[UILabel alloc] initWithFrame: 
                CGRectMake (stampFrame.size.width - 70, stampFrame.size.height - 
                            ((iPHONE) ? 80 : 140), 50, 50)];
        stampLabelFull.text = initials;
        stampLabelFull.backgroundColor = [UIColor clearColor];
        stampLabelFull.textColor = [UIColor whiteColor];
    }
    
    if (watermark)
        [playerLayerView addSubview: stampLabelFull];
    
    if (player)
        [player play];
}

// Leave full screen playback 

-(void) leaveFullScreen: (id) foo   // AVPlayer
{
    NSLog (@"leave full screen");
    
    [UIView animateWithDuration: .3 animations: ^{
        playerLayerView.frame = saveFrame;
        playerLayer.frame = playerLayerView.layer.bounds;
        
        if (stillShows)
            stillView.frame = saveFrame2;
    }];
    
    // We hid the navgation controlller on the iPad (on the iPhone, it's a drop down)
    
    if ( !iPHONE) {
        UINavigationController  *nc = 
                [(VideoTreeAppDelegate *) [[UIApplication sharedApplication] delegate] nc];
        nc.view.hidden = NO;
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation: UIStatusBarAnimationFade];
    }
    
    // reshow everything we hid before
    
    newNote.hidden = NO;
    
    if (! stillShows)
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

// 
// Leave full screen for still autoplay
//

-(void) leaveFullScreenStill
{
}

//
// Notification when player reaches the end of playback
//

- (void) itemDidPlayToEnd:(NSNotification*) aNotification 
{
    NSLog (@"Item did play to end");
    
    seekToZeroBeforePlay = YES;
    
    if (autoPlay) {
        if (! [self nextClip] && fullScreenMode)
            [self leaveFullScreen: nil];
    }
}

//
// Notification when still has been displayed for slideTime secs
//

-(void) stillDidTimeOut: (NSTimer *) theTimer
{
    NSLog (@"Still did time out autoplay");
    
    if ([[[self voiceMemo] audioRecorder] isRecording] || [self keyboardShows]) {
        NSLog(@"We're currently recording or typing, ignore timeout");
        return;
    }
    
    [slideshowTimer invalidate];
    self.slideshowTimer = nil;
    
    BOOL next = [self nextClip];   // This will actually select the next clip/still from the table
    
    if (!next)
        pausePlayButton.enabled = NO;
}

//
// Update our counter (and scrub bar) every frame
//


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

//
//  Kill our playback timer
//

- (void)stopObservingTimeChanges
{
	if (playerTimeObserver) {
		[player removeTimeObserver:playerTimeObserver];
		[playerTimeObserver release];
		playerTimeObserver = nil;
	}
}

//
// Observe various changes in playback, such as rate, duration, and status
//

- (void)observeValueForKeyPath:(NSString*) path ofObject:(id) object change:(NSDictionary*)change context:(void*)context
{
    NSLog (@"observe value %@", context);
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

        NSLog (@"observed AirPlay change in player, airPlayVideoActive = %i", [player isAirPlayVideoActive]);
        
        if ([player isAirPlayVideoActive])
            airPlayImageView.hidden = NO; // unhide the airplay subview and bring to front
        else
            airPlayImageView.hidden = YES; // hide the airplay subview
        
    }
    else
        [super observeValueForKeyPath:path ofObject:object change:change context:context];
}


#pragma mark -
#pragma mark Notes table


// The number of sections in the table view.

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {    
    return 1;
}


// The number of rows in the table view.

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [noteData count];
}

// The height of each row in the table

- (CGFloat) tableView: (UITableView *) tableView heightForRowAtIndexPath: (NSIndexPath *) indexPath
{
    if ( !iPHONE)
        return 65.0;
    else
        return 80.0;
}

// The background color for each row depends on whether it's my note or someone else's

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
        [cell.textLabel setFont:[UIFont systemFontOfSize: 14.0]]; 
        [cell.detailTextLabel setFont:[UIFont systemFontOfSize: 12.0]];
        cell.editingAccessoryType = UITableViewCellEditingStyleDelete;
        cell.textLabel.numberOfLines = 2;
        cell.detailTextLabel.numberOfLines = 1;
        cell.imageView.backgroundColor = MYGRAY;
        tableView.backgroundColor = [UIColor colorWithRed: .8 green: .8 blue: .9 alpha: 1];
        
        CGRect theFrame = cell.selectedBackgroundView.frame;
        UIView *theBG = [[UIView alloc] initWithFrame: theFrame];
        theBG.backgroundColor =  [UIColor colorWithRed: 0 green: 0 blue: 0 alpha: .7];;
        cell.selectedBackgroundView = theBG;
        cell.imageView.layer.masksToBounds = YES;
    }

    // Fill in the cell with data from the note stored in noteData
    
    Note *theNote = [noteData objectAtIndex: indexPath.row];
    
    // The marked up frame thumbnail
 
#if 0
    UIImage *thumbnail = [UIImage imageWithData: theNote.thumb];
    float width = 200;
    float ht = (width / thumbnail.size.width) * thumbnail.size.height;
    
    cell.imageView.image = [[UIImage imageWithData: theNote.thumb] imageScaledToSize: CGSizeMake(width, ht)];
#endif
    
    UIImage *thumbnail = [UIImage imageWithData: theNote.thumb];
    cell.imageView.image = thumbnail;
    
//  [self dumpRect: cell.imageView.frame title: @"cell.imageView.frame"];
//  [self dumpRect: cell.imageView.bounds title: @"cell.imageView.bounds"];
//   NSLog (@"cell imageView image size = (%g, %g)", cell.imageView.image.size.width, 
//                    cell.imageView.image.size.height);
 
    // The typed note 
   
    cell.detailTextLabel.text = [theNote.text stringByReplacingOccurrencesOfString: @"<CHAPTER>" withString: @""];
    
    if (! theNote.imageName)  { // means it's a video 
        // The time in either timecode or frame number format
        
        NSString *timeFormat = (timecodeFormat) ? theNote.timeStamp :
                [self timeFormat: kCMTimeMakeWithSeconds ([self convertTimeToSecs: theNote.timeStamp] - startTimecode) ];
        
        // The time, the date of the note, and the initials of the user that made the note
        
        cell.textLabel.text = [NSString stringWithFormat: @"%@\n%@ %@", timeFormat, 
                [theNote.date length] > 3 ? 
                [theNote.date substringToIndex: [theNote.date length] - 3] : @"", theNote.initials];
    }
    else
        cell.textLabel.text = [NSString stringWithFormat: @"%@ %@", [[theNote.imageName lastPathComponent] stringByDeletingPathExtension], theNote.initials];
    
    // My notes look different in the table than everyone else's
    
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

// Handle selection of a note from the notes table

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Note *theNote = [noteData objectAtIndex: indexPath.row];
    
    // See if we currently have a clip playing
    
    if (player) {
        [self pauseIt];
        [audioPlayer stop];
  
        if (fps == 0.0)
            [self updateTimeControl];
        
        // Seek to the frame indicated by the note
            
        Float64 secs = [self convertTimeToSecs: theNote.timeStamp] - startTimecode;
        NSLog (@"Seeking to %lg (%@) for Note", secs, theNote.timeStamp);
        
        seekToZeroBeforePlay = NO;
        [player seekToTime: kCMTimeMakeWithSeconds(secs * ((int)(fps + .50000001) / fps)) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    }

    newNote.text = [theNote.text stringByReplacingOccurrencesOfString: @"<CHAPTER>" withString: @""];
    
    // If there's an audio note, play it now
    
    if (theNote.voiceMemo) {
        NSError *error = nil;
                
        if (audioPlayer)  
            [audioPlayer release];
        
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
        [audioSession setActive: YES error: NULL];
        
        audioPlayer = [[AVAudioPlayer alloc] initWithData: theNote.voiceMemo error:&error];
    
        if (error) {
            int errorCode = CFSwapInt32HostToBig ([error code]); 
            NSLog(@"Playback error: %@ [%4.4s])" , [error localizedDescription], (char*)&errorCode); 
        }
        
        [audioPlayer play];
    }
    
    drawView.colors = theNote.colors;
    drawView.myDrawing = theNote.drawing;
    
    if (theNote.imageName)  {  // Load in the still
        noteTableSelected = YES;
        
        [self loadStill:  [[mediaPath stringByDeletingLastPathComponent] stringByAppendingPathComponent: theNote.imageName]];
        
        for (int i = 0; i < theNote.rotation; ++i)   // get the still in the right orientation---maybe not the most elegant solution here
            [self rotateStill];
                
        drawView.scaleWidth =  drawView.frame.size.width  / theNote.frameWidth;
        drawView.scaleHeight =  drawView.frame.size.height / theNote.frameHeight;
        
        NSLog (@"framewidth = %g, frameheight = %g", theNote.frameWidth, theNote.frameHeight);
        [self dumpRect: drawView.frame title: @"drawView.frame"];
        noteTableSelected = NO;
    }
    else {
        // We want to draw the markups onto the frame
        // Set up the data in the drawView object and then have the markups drawn

        drawView.scaleWidth =  drawView.frame.size.width  / theNote.frameWidth;
        drawView.scaleHeight =  drawView.frame.size.height / theNote.frameHeight;
    
        if ( drawView.scaleWidth == 0.0 || drawView.scaleWidth == NAN )
            drawView.scaleWidth = drawView.scaleHeight = 1.0;
    }

    [drawView setNeedsDisplay];   // Draw the markups
    
    [self updateTimeLabel];
    [self updateTimeControl];
}

//
// Allow or disable deletion of a note
// Permission is granted if the initials on the note match the user's
//

- (void)tableView:(UITableView *)tableView commitEditingStyle: (UITableViewCellEditingStyle)editingStyle forRowAtIndexPath: (NSIndexPath *)indexPath
{
    if ([((Note *)[noteData objectAtIndex: indexPath.row]).initials isEqualToString: initials]) {
        NSLog (@"Commit editing style called");
        [noteData removeObjectAtIndex: indexPath.row];  // remove the note from the table
        [self storeData];                               // update local storage (and the server)
        [notes reloadData];
    }
    else 		
		[UIAlertView doAlert: @"" withMsg: 
           @"You don't have permission to delete this note" ];
}

// 
// The Edit button in the notes table
// Once Edit mode has started, we change the button's title to "Done"
//

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
    if (kRunningOS5OrGreater) 
        [player removeObserver: self forKeyPath:@"airPlayVideoActive"];
    
    [theTimer invalidate];
    self.theTimer = nil;
    
    [slideshowTimer invalidate];
    self.slideshowTimer = nil;
    [stillImage release];
    
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
