//
//  DetailViewController.m
//  VideoTree
//
//  Created by Steve Kochan on 9/12/10.
//  Copyright © 2010-2011 by Digital Film Tree. All rights reserved.
//

#import "DetailViewController.h"
#import "VideoTreeViewController.h"


@implementation DetailViewController

@synthesize  clipList, levelCount, showName, episode, date, tape, clip;
@synthesize currentClip, currentTape, clipCount, popoverController, moviePath;

static int retryCount;

#pragma mark -
#pragma mark View Loading

- (void)viewDidLoad {
    NSLog (@"dc view did load");
    
    [super viewDidLoad];
    VideoTreeAppDelegate *appDel = kAppDel;
    
    appDel.tvc = self;
    
    if (currentPath) {
        [self makeList];
    }
    
    self.clearsSelectionOnViewWillAppear = NO;
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

#pragma mark -
#pragma mark Activity indicator

-(void) showActivity
{
    NSLog (@"show activity");
	if (! progressView) {
        CGPoint theOrigin = {0, 0};
        CGSize  theSize = (iPHONE) ? (CGSize) {182, 250} : (CGSize) {210, 344};
        CGRect theFrame = {theOrigin, theSize};
        
        progressView = [[UIView alloc] initWithFrame: theFrame];
        progressView.alpha = 0.3;
        progressView.backgroundColor = [UIColor lightGrayColor];
        activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleWhiteLarge];
        
        CGPoint theCenter;
        
        theCenter.x = theSize.width / 2;
        theCenter.y = theSize.height / 2;
        activityIndicator.center = theCenter;
        [progressView addSubview: activityIndicator];
    }
	
	[activityIndicator startAnimating];
	[[[kAppDel viewController] view] addSubview: progressView];
}

-(void) stopActivity
{
    NSLog (@"Stop activity");
    [activityIndicator stopAnimating];
    [progressView removeFromSuperview];
}

#pragma mark -
#pragma mark New folder code

@synthesize currentPath, files, fileTypes;
@synthesize progressView, activityIndicator;

#define kDirectory  4
#define kFile       8

-(void) makeList
{
#ifdef CAMERAROLL
    if (! kFTPMode) {
        UIBarButtonItem *cRollButton = 
        [[[UIBarButtonItem alloc] initWithImage: 
                    [UIImage imageNamed: @"cameraRoll.png"]
                        style:  UIBarButtonItemStyleBordered target: self 
                        action: @selector(pickClip)] autorelease]; 
        self.navigationItem.leftBarButtonItem = cRollButton;
    }
    else
        self.navigationItem.leftBarButtonItem = nil;
#endif
    
    if (!files) {
        self.files = [NSMutableArray array];
        self.fileTypes = [NSMutableArray array];
    }
    else {
        [files removeAllObjects];
        [fileTypes removeAllObjects];
    }
    
    if (kFTPMode)
        self.title = @"Files";
    
    [self.tableView reloadData];
    
    [kAppDel makeSettings];
    
    if (!kFTPMode) {
        [self iTunesLoad];
        return;
    }
    
    if (! currentPath ) {
        self.title = @"Files";
        self.currentPath = homeDir;
    }
    
    [FTPHelper sharedInstance].delegate = self;
    [FTPHelper sharedInstance].uname = kFTPusername;
    [FTPHelper sharedInstance].pword = kFTPpassword;

    // Listing

    [self showActivity];
    
    NSLog (@"list %@",  [NSString stringWithFormat: @"ftp://%@:%@@%@%@/", kFTPusername, kFTPpassword, kFTPserver, currentPath]);
    
    [FTPHelper list: [NSString stringWithFormat: @"ftp://%@:%@@%@%@/", kFTPusername, kFTPpassword, kFTPserver, currentPath]];
}

-(void) finishLoad
{
    if (activityIndicator.isAnimating)
        [self stopActivity];
    
    if (! iPHONE) {
        self.navigationItem.rightBarButtonItem = 
        [[[UIBarButtonItem alloc] initWithImage: 
          [UIImage imageNamed: @"refresh.png"]
                    style: UIBarButtonItemStyleBordered target: self action: @selector(makeList)] autorelease];  
    }
    
#if 0
    if ([files count] == 0)         
        [UIAlertView doAlert:  @"" withMsg: @"No video clips found"];
#endif
    
    NSLog (@"Found %i files", [files count]);

    [self.tableView reloadData];
}

- (void) receivedListing: (NSArray *) listing
{
    NSLog (@"receivedListing");
    
	for (NSDictionary *dict in listing) {
        NSString *fileName = [FTPHelper textForDirectoryListing:(CFDictionaryRef) dict];
        
        int cfType = [(NSNumber *) CFDictionaryGetValue((CFDictionaryRef) dict, kCFFTPResourceType) intValue];
        
        NSLog (@"Ftp file: %@ (%i)", fileName, cfType);
        
        NSString *extension = [fileName pathExtension];
        
        if ( cfType != kDirectory && !(EQUALS (extension, @"mov")|| EQUALS (extension, @"m4v")
                        ||EQUALS (extension,  @"mp4") || EQUALS (extension,  @"m3u8")) ) {
            continue;
        }
        
        if ( cfType == kDirectory && ([fileName isEqualToString: @"Notes"]
                        || [fileName isEqualToString: @"Library"]))
            continue;
        
        [files addObject: fileName];
        [fileTypes addObject: [NSNumber numberWithInt: cfType]];
        [self.tableView reloadData];
    }
    
    [self finishLoad];
}

- (void) listingFailed
{
	NSLog (@"Listing failed.");
    
    // retry -- seems to be a problem when awakening the App
    
    if (retryCount < 3) {
        [self stopActivity];
        ++retryCount;
        NSLog (@"retry #%i listing", retryCount);
        [self showActivity];
        [FTPHelper list: [NSString stringWithFormat: @"ftp://%@:%@@%@%@/", kFTPusername, kFTPpassword, kFTPserver, homeDir]];
    }
    else {
        [UIAlertView doAlert: @"Network error" withMsg: 
          @"Couldn't connect to the server.  Check your network and server settings"];
        [self stopActivity];

        retryCount = 0;
    }
}


#pragma mark -
#pragma mark iTunes Loading

-(void) iTunesLoad
{
    // This part handles the files loaded in through iTunes
    NSArray *dirList = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDir = [dirList objectAtIndex: 0];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    [files removeAllObjects];
    [fileTypes removeAllObjects];
    
    NSArray *clips = [fm contentsOfDirectoryAtPath:docDir error:NULL];
    
    NSLog (@"Number of clips found: %i %@", [clips count], clips);
    
    for (NSString *path in clips) {
        NSString *extension = [path pathExtension];
        
        if ( ! (EQUALS (extension,  @"mov") || EQUALS (extension,  @"m4v")
                || EQUALS (extension,  @"mp4") || EQUALS (extension,   @"m3u8")) )
            continue;
         
        [files addObject: path];
        [fileTypes addObject: [NSNumber numberWithInt: kFile]];
    }
    
    self.currentPath = @"";
    [self finishLoad];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Override to allow orientations other than the default portrait orientation.
    return interfaceOrientation == UIInterfaceOrientationLandscapeRight || interfaceOrientation == UIInterfaceOrientationLandscapeLeft ;
}

#pragma mark -
#pragma mark Select video from camera roll


#ifdef CAMERAROLL
#define S (NSString *)

-(void) pickClip
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.allowsEditing = NO;
    picker.delegate = self;
    picker.mediaTypes = [NSArray arrayWithObjects:  S kUTTypeAudiovisualContent, S kUTTypeMovie, S kUTTypeQuickTimeMovie, S kUTTypeMPEG,  S kUTTypeMPEG4, S kUTTypeVideo, nil]; 
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary; /* UIImagePickerControllerSourceTypeSavedPhotosAlbum; */
    picker.modalPresentationStyle = UIModalPresentationFormSheet;
    picker.videoQuality =   UIImagePickerControllerQualityTypeHigh;
    
    VideoTreeAppDelegate *appDel = kAppDel;
    VideoTreeViewController *vc = [appDel viewController];
    
    if (iPHONE) {
        [vc presentModalViewController: picker animated:YES];
    }
    else {
        //create a popover controller for the iPad
        
        popoverController = [[UIPopoverController alloc]
                            initWithContentViewController: picker];
        
        CGRect aFrame;
        aFrame.origin.x = 20;
        aFrame.origin.y = 10;
        aFrame.size.width = 40;  aFrame.size.height = 35;

        [popoverController presentPopoverFromRect: aFrame
                        inView: vc.view permittedArrowDirections: UIPopoverArrowDirectionAny
                        animated:YES];
    }
    
    [picker release];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    if (iPHONE) {
        [[picker parentViewController] dismissModalViewControllerAnimated:YES];
    }
    else
        [popoverController dismissPopoverAnimated: YES];
    
    NSURL *moviePicked = [info objectForKey: UIImagePickerControllerMediaURL];
    NSLog (@"URL for movie %@", moviePicked);
    
    VideoTreeAppDelegate *appDel = kAppDel;
    [appDel copyURLIntoApp: moviePicked];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    if (iPHONE ) {
        [[picker parentViewController] dismissModalViewControllerAnimated:YES];
    }
    else
        [popoverController dismissPopoverAnimated: YES];
}    

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController
{
    return YES;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)thePopoverController 
{
    [popoverController release];
}
#endif  // CAMERAROLL

// Cougar Town/0201/Daiies/31G-1.m4v3
#if 0
-(NSMutableArray *) uniqueValuesForComponent: (int) component
{
    int i = 1;
    NSString  *last = nil;
    NSMutableArray *uniqueNames = [[[NSMutableArray alloc] init] autorelease];
    
    for (NSString *val in clips) {
        NSArray *pieces = [val componentsSeparatedByString: @","];
        NSString *theComp = [pieces objectAtIndex: component];
        
        if (! [last isEqualToString: theComp]) {
            if ([pieces lastObject] isEqual: theComp);
            [uniqueNames addObject: theComp];
            ++i;
            last = theComp;
        }
    }
    
    NSLog (@"%i: %@", levelCount, uniqueNames);
    return uniqueNames;
}
#endif


#pragma mark -
#pragma mark Table view data source

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (iPHONE) {
        tableView.backgroundColor = [UIColor colorWithRed: .3 green: .3 blue: .3 alpha: .4];
        tableView.separatorColor  = [UIColor grayColor];
    }
    else
        tableView.backgroundColor = [UIColor colorWithRed: 0 green: 0 blue: 0 alpha: 1];

    return 1;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section;    // fixed font style. use custom view (UILabel) if you want something different
{
     return @"";
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (iPHONE)
        return 35;
    else
        return 50;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [files count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];

        cell.textLabel.textColor = [UIColor whiteColor];
        [cell.textLabel setFont:[UIFont systemFontOfSize: 12.0]]; 
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        cell.textLabel.numberOfLines = 2;
        
        if (! kFTPMode)
            cell.editingAccessoryType = UITableViewCellEditingStyleDelete;

        if (!iPHONE) {
            CGRect theFrame = cell.selectedBackgroundView.frame;
            UIView *theBG = [[UIView alloc] initWithFrame: theFrame];
            theBG.backgroundColor =  [UIColor colorWithRed: .5 green: .5 blue: .5 alpha: .7];;
            cell.selectedBackgroundView = theBG;
        }
        else
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
    }

    int fType = [[fileTypes objectAtIndex: indexPath.row] intValue];
    
    if ( fType == kDirectory ) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.text = [files objectAtIndex: indexPath.row];
        cell.imageView.image = [UIImage imageNamed: @"folder.png"];
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.textLabel.text = [[files objectAtIndex: indexPath.row] stringByDeletingPathExtension];
        cell.imageView.image = nil;
    }
    
    return cell;
    
}

#pragma mark -
#pragma mark Table view delegate

//
// We allow deletion of clips from local storage (Documents folder).  These could be loaded from
// iTunes, from an "Open In.." dialog, or from the Camera Roll from inside the app
//

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *file = [NSString stringWithFormat: @"%@/%@", currentPath, 
                      [files objectAtIndex: indexPath.row]];
    
    NSString *hold = self.moviePath;
    [self setTheMoviePath: file];
    NSLog2 (@"remove item at path: %@", moviePath);

    if (! [[NSFileManager defaultManager] removeItemAtPath: moviePath error: NULL]) 
        [UIAlertView doAlert:  @"" withMsg: @"The file couldn't be deleted!"];
    else
        [self makeList];
    
    self.moviePath = hold;
    
}

-(BOOL) nextClip
{
    while (++currentClip < [files count]) {
        int fileType = [[fileTypes objectAtIndex: currentClip] intValue];
    
        if (fileType != kDirectory) {
            @try  {
                NSIndexPath *indexP = [NSIndexPath indexPathForRow: currentClip inSection:0];
                [self tableView: nil didSelectRowAtIndexPath: indexP];
                [self.tableView selectRowAtIndexPath: indexP animated: YES scrollPosition: UITableViewScrollPositionTop];
            }
            @catch (NSException *exception) {
                NSLog (@"Couldn't select next clip!");
                return NO;
            }

            return YES;
        }
    }
    
    return NO;
}

           
-(void) setTheMoviePath: (NSString *) theMovie
{
    if ( kFTPMode ) {
        // self.moviePath = [NSString stringWithFormat: @"https://documations.net/VideoTree/%@", fileName];
        self.moviePath = [NSString stringWithFormat: @"%@%@%@", kHTTPserver, userDir, theMovie];
        
        self.moviePath = [[self.moviePath stringByReplacingOccurrencesOfString:@"/Sites/" withString: @"/"]
                       stringByReplacingOccurrencesOfString:@" " withString: @"%20"];
        NSLog (@"moviePath = %@", moviePath);
    }
    else {
        NSArray *dirList = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *docDir = [dirList objectAtIndex: 0];
        self.moviePath = [docDir stringByAppendingPathComponent: theMovie];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    VideoTreeAppDelegate *appDel = kAppDel;
    VideoTreeViewController *vc = [appDel viewController];
    appDel.tvc = self;
    
    NSLog (@"=== Selected row %i (levelcount %i) with freemem = %.2f MB", indexPath.row, 
           levelCount, [appDel freemem] / (1024. * 1024.));
  
    currentClip = indexPath.row;
    
    int fileType = [[fileTypes objectAtIndex: indexPath.row] intValue];
    
    if (fileType == kDirectory) {
        DetailViewController *detailViewController = [[DetailViewController alloc] init];        
        detailViewController.title = [files objectAtIndex: indexPath.row];
        detailViewController.currentPath = [[NSString stringWithFormat: @"%@/%@", 
                currentPath, [files objectAtIndex: indexPath.row]] stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
        NSLog (@"currentPath is %@", detailViewController.currentPath); 
        
        [self.navigationController pushViewController: detailViewController animated:YES];
        [detailViewController release];
    }
    else {        
        if (vc.runAllMode) {
            [vc airPlay];
            vc.runAllMode = NO;
        }
        
         NSString *theMovie;
         
         theMovie = [NSString stringWithFormat: @"%@/%@", currentPath, 
                     [files objectAtIndex: indexPath.row]];
         
        NSLog (@"The movie = %@", theMovie);
         
        [self setTheMoviePath: theMovie];
        
        vc.clip =  theMovie;
        vc.clipPath = theMovie;
        [vc loadMovie: moviePath];
    }
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    
    [super didReceiveMemoryWarning];
    if (progressView && ![activityIndicator isAnimating]) {
        [progressView release];
        progressView = nil;
        [activityIndicator release];
        activityIndicator = nil;
    }
    
    NSLog (@"*** detail view controller did receive memory warning");
    // Relinquish ownership of any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}

- (void)dealloc {
    NSLog (@"dealloc of Detail View Controller");
    [episode release];
    [date release];
    [tape release];
    [clipList release];
    [showName release];
    [moviePath release];
    
    [currentPath release];
    self.files = nil;
    self.fileTypes = nil;
    
    self.tableView.dataSource = nil;
    self.tableView.delegate = nil;

    [super dealloc];
}


@end

