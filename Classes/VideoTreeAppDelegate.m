//
//  VideoTreeAppDelegate.m
//  VideoTree
//
//  Steven Kochan & Keyvan Fatehi
//  Copyright © 2011-2012 by Digital Film Tree. All rights reserved.
//

#import "VideoTreeAppDelegate.h"
#import "VideoTreeViewController.h"
#import "DetailViewController.h"
#import "Clip.h"

int gIOSMajorVersion;

// #define RELEASEMEM

#define kFileDelimiterString   @"_"

@implementation VideoTreeAppDelegate

@synthesize window, demoView;
@synthesize tvc, nc, clipList, rootTvc;
@synthesize iPhone, viewController, BonjourMode;
@synthesize serverBrowser, server, bonjour, theURL, theExtension, HTTPserver, serverBase, outputFilename;

static int tryOne = 0;


#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {   
    NSLog (@"****** Begin execution of VideoTree v%@.%@ (free mem = %.2f MB)", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],  
           [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"], ([self freemem]/ (1024. * 1024.)));
    
    gIOSMajorVersion = [[[UIDevice currentDevice] systemVersion] characterAtIndex: 0];
    NSLog (@"Running %@ version (IOS version %c) ", iPhone ? @"iPhone" : @"iPad", gIOSMajorVersion);

    iPhone = [[UIScreen mainScreen] applicationFrame].size.height < 1000;
    
    if (iPhone) {
        self.viewController =  [[VideoTreeViewController alloc] 
                initWithNibName: @"iPhoneVideoTreeViewController" bundle:[NSBundle mainBundle]];
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:NO];
        [window addSubview: viewController.view];
    }
    else {
        [window addSubview: viewController.view];
    }
    
    [self makeDetailTableViewController];
    [viewController.view addSubview: nc.view];
    
#ifdef kMakeLogFile
    removeLogFile ();
    newLogFile ();
#endif
    
    [window makeKeyAndVisible];

    return YES;
}

// If we're moving into the background, let's stop video playback; however, let's
// record where we are so we can resume playback when we become active again

- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. 
     Games should use this method to pause the game.
     */
    
    if (viewController.player) {
        NSLog (@"stopping player");
        theTime = viewController.player.currentTime;
        theRate = viewController.player.rate;
        
        if (viewController.player.rate)
            [viewController playPauseButtonPressed: nil];
    }
    
#ifdef kMakeLogFile
    uploadLogFile ();
#endif
    
    NSLog (@"app will resign active");
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    
    NSLog (@"app did become active");
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    [viewController uploadActivityIndicator: NO];
    
    // NSLog (@"player = %@, moviePath = %@", viewController.player, tvc.moviePath);
    
    // Restart playback as appropriate
    
    if ([viewController player] && tvc.moviePath) {
        NSLog (@"setting playback rate to %g", theRate);
        if (theRate)
            [viewController playPauseButtonPressed: nil];
        
        return;
    }
    
    // We've never selected a clip, let's get the app's settings
    
    if (! tvc.currentPath) {
        NSLog(@"Never selected a clip, get new settings");
        [self makeSettings];
        [viewController makeSettings];  
        if (BonjourMode) {
            [self doBonjour];            
        }
        
    }
    
    // We're either loading clips locally or over the network 
    // (but not via Bonjour)  Load the clip table (if we're not in the process of loading it)
    
    if (!kBonjourMode) {
        if (!iPHONE) {
            if (! [rootTvc.activityIndicator isAnimating]) {
                [rootTvc makeList];
            }
        }
    } else
        [viewController showNav];
    
    [self releasemem];
}

- (void)applicationWillTerminate:(UIApplication *)application {
#ifdef kMakeLogFile
    uploadLogFile ();
#endif
}


#pragma mark -
#pragma mark Handle "Open in" and Camera Roll support


// This method is called to open a file from another application (that is, it handles "Open In...")
// The clip will be copied into the local file system's sandbox.  We force the app into "local" mode
// here so there are no conflicts related to server mode vs. local mode.


- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    NSLog (@"Request to open URL from %@ (file is %@)", sourceApplication, [url filePathURL]);
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // Force the server into local mode; as we don't want to deal with
    // where to store the notes or where to play the clips from
    
    [defaults setBool: NO forKey: @"BonjourMode"];
    BonjourMode = NO;
    
    [defaults synchronize];
    
    // Update the clip list to reflect the switch to local mode
    
    [tvc makeList];
    
    [self copyVideoOrImageIntoApp: url];
    return YES;
}

//
// Drop down animation for the dialog box to allow the local clip to be named
//

-(void) animateTransition: (BOOL) start
{
	CATransition *transition = [CATransition animation];

	transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];

    if (start) {
        transition.type = kCATransitionMoveIn;
        transition.duration = 0.75;
    }
    else {
        transition.type = kCATransitionFade;
        transition.duration = 0.3;
    }

    transition.subtype =  kCATransitionFromBottom;

	[viewController.filenameView.layer addAnimation:transition forKey:nil];
}

// Copy a clip or image selected by "Open In..." or from the camera roll into the app's
// local storage.  Give the user the option to rename the clip/image
// Note that an image comes in as a UIImage reference, so in that case we already have the data
     
-(void) copyVideoOrImageIntoApp: (id) urlOrNil
{    
    if (! [urlOrNil isKindOfClass: [UIImage class]])  {    // nil if it's an image
        NSURL *url = (NSURL *) urlOrNil;
        
        self.outputFilename = [NSString stringWithFormat: @"%@", 
                    [[url filePathURL] lastPathComponent]];
        
        self.theURL = url;
        self.theExtension = [[outputFilename pathExtension] lowercaseString];
    }
    else  {
        self.theExtension = @"jpg";
        self.outputFilename = @"myImage.jpg";
        imageReference = (UIImage *) urlOrNil;
    }
        
    viewController.saveFilename.text = [outputFilename stringByDeletingPathExtension];
    
    [self animateTransition: YES];
    viewController.filenameView.hidden = NO;
     
    [viewController.view bringSubviewToFront: viewController.filenameView];
    [viewController.saveFilename becomeFirstResponder];
}

// A file name has been entered for local clip storage.  Make sure the file
// doesn't already exists.  If it does, give the user the option to overwrite or rename


-(void) saveFileNameEntered
{    
    [self animateTransition: NO];
    viewController.filenameView.hidden = YES;
    
    NSArray *dirList = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDir = [dirList objectAtIndex: 0];
    
    self.outputFilename =  [NSString stringWithFormat: @"%@.%@", 
        [docDir stringByAppendingPathComponent: viewController.saveFilename.text], theExtension];
    NSLog2 (@"Output file name = %@", outputFilename);
    
    NSURL *toURL = [NSURL fileURLWithPath: outputFilename];
    
    // Check if file name already exists
    
    if ([[NSFileManager defaultManager] fileExistsAtPath: outputFilename]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Error" 
                message: @"The file already exists, overwrite?"  delegate:self 
                cancelButtonTitle: @"Yes" otherButtonTitles: @"No", nil];
        
        [alert show];
        [alert release];
        return;
    }
        
    // Now copy the file into the user's Documents folder -- first try to move it (may be in the Inbox)
    // If it's a UIImage, write the data to the file
    
    if ([theExtension isEqualToString: @"jpg"]) {
        NSLog (@"%@", imageReference);
        NSData *imageData = UIImageJPEGRepresentation(imageReference, 1.0f);
        [imageReference release];
        
        if (! [imageData writeToFile: outputFilename atomically: NO] ) {
               [UIAlertView doAlert:  @"Error" 
                             withMsg: @"Couldn't copy the imported file!"];
                
                return;
        }
    }
    else if (! [[NSFileManager defaultManager] moveItemAtURL: theURL toURL: toURL error: NULL] && 
        ! [[NSFileManager defaultManager] copyItemAtURL: theURL toURL: toURL error: NULL] ) {
        [UIAlertView doAlert:  @"Error" 
                withMsg: @"Couldn't copy the imported file!"];
        
        return;
    }
    
    [tvc makeList];

    viewController.clip  =  outputFilename;
    viewController.clipPath  =  outputFilename;

    [viewController.saveFilename resignFirstResponder];
    
    if ([theExtension isEqualToString: @"jpg"]) {
        viewController.noteTableSelected = NO;
        [viewController loadStill: outputFilename];
    }
    else
        [viewController loadMovie:  viewController.clip];
}

// Handle alert if save file already exists

- (void) alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger) buttonIndex {
	
	// Save the image to the photos album if the OK button was pressed
	
	if (buttonIndex == 0)  { // overwrite the file
        NSLog (@"Overwriting file");
        if ( ! [[NSFileManager defaultManager] removeItemAtPath: outputFilename error: NULL]) {
            [UIAlertView doAlert:  @"Error" 
                         withMsg: @"Couldn't overwrite the file"];
            
            return;
        }
        [self saveFileNameEntered];
    }
	else if (buttonIndex == 1)          // try again
		[self copyVideoOrImageIntoApp: theURL]; // display the file save dialog again
}

// See how much free memory is available

-(natural_t) freemem 
{
    // get free memory avaiable
    
    mach_port_t host_port;
    mach_msg_type_number_t host_size;
    vm_size_t pagesize;
    
    host_port = mach_host_self();
    host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    host_page_size(host_port, &pagesize);
    
    vm_statistics_data_t vm_stat;
    natural_t mem_free = 0;
    
    if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS) {
        NSLog(@"Failed to fetch vm statistics");
        return mem_free;
    }
    else 
        mem_free = vm_stat.free_count * pagesize;
    
    // This code somehow consolidates the free memory
    
#ifdef RELEASEMEM
        size_t size = mem_free - (2*1024*1024);
        void *allocation = malloc (size);
        bzero (allocation, size);
        free (allocation);
#endif

    if (host_statistics(host_port, HOST_VM_INFO, (host_info_t) &vm_stat, &host_size) != KERN_SUCCESS)  {
        NSLog(@"Failed to fetch vm statistics");
        return mem_free;
    }
    else 
        mem_free = vm_stat.free_count * pagesize;
    
    return mem_free;
}

-(void) releasemem
{
    /* Allocate the remaining amount of free memory, minus 2 megs */
#ifdef RELEASEMEM
     size_t size = [self freemem] - (2*1024*1024);
     
         void *allocation = malloc (size);
         bzero (allocation, size);
         free (allocation);
#endif
}

        
#pragma mark -
#pragma mark Bonjour

// Part of Bonjour server support; connect to a discovered Scribbeo server
- (void)updateServerList {
    NSLog(@"updateServerList called");
    
    if (serverBrowser.servers.count == 0) {
        NSLog (@"Scribbeo Server disconnected!");
        [rootTvc showActivity];
        return;
    }
    // else...
    self.server = [serverBrowser.servers objectAtIndex: 0];
    NSLog (@"Connecting to Scribbeo server");
    
    if (bonjour)
        self.bonjour = nil;
    
    bonjour = [[BonjourConnection alloc] initWithNetService: server];

    
    // If it is animating, it is likely we are coming back from a disconnect.
    if ( [[rootTvc activityIndicator] isAnimating]) {
        HTTPserver = nil; // Clear our http server, the ip and port may change.
        [self addObserver: self forKeyPath: @"HTTPserver" options: NSKeyValueObservingOptionNew context: nil];
        if (! [bonjour connect])  // ~connect updates the HTTPserver address
            NSLog (@"Couldn't reconnect to Scribbeo server");
        
    }
}

#pragma mark -
#pragma mark settings

// When we receive the IP address from the Bonjour server, it will be stored
// in the HTTPServer variable.  We're observing that variable so we are alerted
// when it changes

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSLog (@"Observe value change for HTTPserver: %@", HTTPserver);
    
    if ([[change objectForKey: NSKeyValueChangeKindKey] integerValue] !=  NSKeyValueChangeSetting) {
        NSLog (@"Key value did not change: %i", [change objectForKey: NSKeyValueChangeKindKey]);
        return;
    }
    
    if (! HTTPserver)
        return;
    
    [self removeObserver: self forKeyPath: @"HTTPserver"];
           
    if (! iPhone) {
        NSLog(@"Now we need to make the list of files");
        [rootTvc makeList];
    }
    else
        [viewController showNav];
}

// Start looking for Bonjour services

-(void) doBonjour
{
    static int once;
    
    if (once)
        return;
    else
        once = 1;
    
    NSLog (@"Get Bonjour server info");
    
    if (! BonjourMode )
        return;
  
    tryOne = 0;
        
    // restart server browser if already running
    
    if (serverBrowser) 
        [serverBrowser stop];
    else {
        self.serverBrowser = [[ServerBrowser alloc] init];
        serverBrowser.delegate = self;
    }

    [serverBrowser start];
    
    [self addObserver: self forKeyPath: @"HTTPserver" options: NSKeyValueObservingOptionNew context: nil];
    
    NSLog (@"**** UDID is %@", [[UIDevice currentDevice] uniqueIdentifier]);
}

// This method looks at the user defaults and sets up various parameters

-(void) makeSettings
{
    static int count = 1;
    NSLog (@"makeSettings: %i", count++);
    
    // Load the user settings
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
   
    // Bonjour support
    
    BonjourMode = [defaults boolForKey: @"Bonjour"];
    
    if (!BonjourMode) 
        BonjourMode = NO;

    // show finger presses (good for demos)
    
    demoView = [defaults boolForKey: @"showPresses"]; 

    if (BonjourMode) {
        [self doBonjour]; // Initiate the search for our py http server using bonjour
        NSLog(@"Running in Bonjour Mode");
    } else
        NSLog (@"Running in iTunes Document sharing mode");
}

// Create our DetailViewController, which manages clip selection

-(void) makeDetailTableViewController
{ 
    [viewController cleanup];

    if (rootTvc) {
        [nc.view removeFromSuperview];
        [nc release];
        
        nc = nil;
    }
        
    CGSize theSize;
    CGPoint theOrigin;
    
    if (! iPhone) {
        theOrigin = (CGPoint) {0, 0};
        theSize = (CGSize) {206, 344};
    }
    else {
        theOrigin =  (CGPoint) {0, 7};
        theSize = (CGSize) {170, 250}; 
    }
    
    CGRect theFrame = {theOrigin, theSize};
    
    // custom TableViewController
    
    rootTvc = tvc = [[DetailViewController alloc] init];

    // NavigationController

    nc = [[UINavigationController alloc] initWithRootViewController:  rootTvc]; 
    
    nc.view.frame = theFrame;
    nc.view.autoresizingMask =  UIViewAutoresizingNone;
    nc.toolbar.barStyle = UIBarStyleBlack;
    nc.toolbar.translucent = YES;
}


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    NSLog (@"Application did receive memory warning");
    
    [self freemem];
}

-(void) finishLoad
{

}

#pragma mark Log File

#ifdef NOTNOW
-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult) result error:(NSError *)error
{
    if (result ==  MFMailComposeResultSent)
        removeLogFile ();
}
#endif

#ifdef kMakeLogFile

- (void) dataUploadFinished: (NSNumber *) bytes;
{
    [viewController uploadActivityIndicator: NO];
}

- (void) dataUploadFailed: (NSString *) reason
{
    [viewController uploadActivityIndicator: NO];

}
#endif

- (void)dealloc {
    [viewController release];
    [tvc release];
    [nc release];
    [window release];
    [clipList release];
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [super dealloc];
}

@end
