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

@synthesize currentClip, popoverController, moviePath;
@synthesize currentPath, files, fileTypes, assetURLs, timeCodes;
@synthesize progressView, activityIndicator;

#pragma mark -
#pragma mark View Loading

- (void)viewDidLoad {
    NSLog (@"dc view did load");
    
    [super viewDidLoad];
    VideoTreeAppDelegate *appDel = kAppDel;
    
    appDel.tvc = self;
    
    // If we've been here before, update the clip list
    
    if (currentPath) {
        [self makeList];
    }
    
    // Various things related to the navigation bar and table view
    
    self.clearsSelectionOnViewWillAppear = NO;
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
}

#pragma mark -
#pragma mark Connection status indicator

-(void) showDisconnected
{
    if (!kBonjourMode) return;
    NSLog(@"Showing the disconnected png");
    CGSize  theSize = (iPHONE) ? (CGSize) {182, 250} : (CGSize) {210, 344};  
    // hard-coded #'s--uggh! :(
    UIImageView *imgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Disconnected.png"]];
    imgView.frame = CGRectMake((theSize.width / 2)-32, (theSize.height / 2)-72, 64, 64);
    imgView.tag = 75;
    [[self view] addSubview:imgView];
    [imgView release];
}

-(void) hideDisconnected
{
    NSLog(@"Hiding the disconnected png");
    UIView *imgView = [self.view viewWithTag:75];
    if (imgView)
        [imgView removeFromSuperview];
}
#pragma mark -
#pragma mark Activity indicator

//
//  Show activity when the clip table is being loaded
//

-(void) showActivity
{
    NSLog (@"show activity");
    
    // Create the semi-transparent view to hold the activity indicator
    
	if (! progressView) {
        CGPoint theOrigin = {0, 0};
        CGSize  theSize = (iPHONE) ? (CGSize) {182, 250} : (CGSize) {210, 344};  // hard-coded #'s--uggh!
        CGRect  theFrame = {theOrigin, theSize};
        
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
	
    // Start spinning and show it
    
	[activityIndicator startAnimating];
	[[[kAppDel viewController] view] addSubview: progressView];
}

//
// Stop activity when the clip table has loaded
//

-(void) stopActivity
{
    NSLog (@"Stop activity");
    [activityIndicator stopAnimating];
    [self hideDisconnected]; // Remove the 'disconnected' indicator
    [progressView removeFromSuperview];
}

#pragma mark -
#pragma mark New folder code

#define kDirectory  4
#define kFile       8

//
// Create the clip list for the table
// Show the camera roll icon if we're in local mode
//

-(void) makeList
{
    NSLog(@"DetailView::makeList called");
    if (!kBonjourMode) {
        UIBarButtonItem *cRollButton = 
        [[[UIBarButtonItem alloc] initWithImage: 
                    [UIImage imageNamed: @"cameraRoll.png"]
                        style:  UIBarButtonItemStyleBordered target: self 
                        action: @selector(pickClip)] autorelease]; 
        self.navigationItem.leftBarButtonItem = cRollButton;
    }
    else {
        self.navigationItem.leftBarButtonItem = nil;
        self.navigationItem.rightBarButtonItem = nil;

        if (! iPHONE) {
            UIBarButtonItem *refresh =  [[[UIBarButtonItem alloc] initWithImage: 
          [UIImage imageNamed: @"Refresh.png"]
                  style: UIBarButtonItemStylePlain target: self action: @selector(makeList)] autorelease];  
            self.navigationItem.rightBarButtonItem = refresh;
        }
    }
    
    // Create our clip list arrays, or clear if already created
    
    if (!files) {
        self.files = [NSMutableArray array];
        self.fileTypes = [NSMutableArray array];
        self.assetURLs = [NSMutableArray array];
        self.timeCodes = [NSMutableArray array];
    }
    else {
        [files removeAllObjects];
        [fileTypes removeAllObjects];
        [assetURLs removeAllObjects];
        [timeCodes removeAllObjects];
    }
    
    if (kBonjourMode) { 
        if (currentPath) {
            NSString *theFolder = [currentPath lastPathComponent];
            if ([theFolder isEqualToString:@"list"])
                self.title = @"Files";
            else
                self.title = [theFolder stringByReplacingOccurrencesOfString:@"%20" withString:@" "];
        }
        else 
            self.title = @"Files";
    } else
        self.title = @""; // No title needed in local mode
    
    [self.tableView reloadData];        // Refresh the table
    
    // Get the current settings
    
    // [kAppDel makeSettings]; No need... we do this at launch always.
    
    // If running in local mode, populate the clip table
    // with local video files
    
    if (!kBonjourMode) {
        NSLog(@"makeList knows we're not in bonjour mode... calling iTunesLoad to serve local files");
        [self iTunesLoad];
        return;
    }
    
    // If this is the first time populating the table...
    
    if ((! currentPath) || ([currentPath length] == 0)) {
        self.title = @"Files";
        self.currentPath = @"/list"; // this is root in the py server
    }
    NSLog(@"Current path is set to: %@", self.currentPath);
    
    [self showActivity];
    
   
    if (kBonjourMode && kHTTPserver) {
        // Send a list request to our HTTPServer
        NSString *urlstr = [NSString stringWithFormat:@"%@%@", [kAppDel HTTPserver], currentPath];
        NSLog(@"Making list for BonjourMode. Querying: %@", urlstr);
        NSURL *url = [NSURL URLWithString:urlstr];
        NSString *list = [NSString stringWithContentsOfURL:url encoding:NSASCIIStringEncoding error:nil];
        if (!list) {
            NSLog(@"Could not get data from the URL");
            return;
        }
        NSLog(@"Got data... Filling the file list");
        [self hideDisconnected]; // Remove the 'disconnected' indicator if it's there.
        NSDictionary *fileDict = [list objectFromJSONString];
        // Now we need to populate the files array using our nice JSON list
        [self filesFromJSONFileListing:fileDict];       
    } else if (kBonjourMode && (!kHTTPserver)) {
        NSLog(@"In bonjour mode, but the http server has not been set yet.");
        [[kAppDel serverBrowser] stop];
        [[kAppDel serverBrowser] start];
    }
    
}


// This method will fill the files array from the JSON received from the py bonjour webserver
- (void) filesFromJSONFileListing: (NSDictionary *) listing
{
    [[[kAppDel viewController] noteURLs] removeAllObjects];
    NSLog (@"filesFromJSONFileListing");
    allStills = YES; // For album mode. This will become NO if there's non-stills here.
    
    NSArray *fileList = [listing objectForKey:@"files"];
    NSArray *folderList = [listing objectForKey:@"folders"];

    // Folders at the top, files below    
    for (NSDictionary *dict in folderList) {
        NSString *folderName = [dict objectForKey:@"name"];
        NSLog(@"See a folder called: %@", folderName);
        [files addObject:folderName];
        [fileTypes addObject:[NSNumber numberWithInt: kDirectory]];
        NSString *listURL = [dict objectForKey:@"list_url"]; // URL by which to retreive this asset
        [assetURLs addObject:listURL]; // Dir has no asset retrieval URL, instead use assetURL for traversal
        [timeCodes addObject:@""]; // Empty
        [[[kAppDel viewController] noteURLs] addObject:[NSArray array]]; // Empty
    }
    // Now the files...
    for (NSDictionary *dict in fileList) {
        NSString *fileName = [dict objectForKey:@"name"];
        NSString *fileExt = [dict objectForKey:@"ext"];
        NSString *assetURL = [dict objectForKey:@"asset_url"]; // URL by which to retreive this asset
        NSLog(@"See a file named: %@", fileName);
        NSLog(@"Asset located at: %@", assetURL);
        [files addObject:fileName];
        [fileTypes addObject:[NSNumber numberWithInt: 8]];
        [assetURLs addObject:assetURL];
        [timeCodes addObject:@""]; // gets populated elsewhere
        [[[kAppDel viewController] noteURLs] addObject:[NSArray array]]; // gets populated elsewhere.
        // If we have any clips, this folder isn't all stills.
        if kIsMovie(fileExt) allStills = NO;
    }
    NSLog(@"from with JSON File Listing... AssetURLs has %d items", [assetURLs count] );

    [self.tableView reloadData]; // reloads file listing
    [self finishLoad]; // reloads file listing... again...
}

// This method will fill the noteURLs array. Called when you select a clip.
// Then loadMovie or loadStill will call the getAllHTTPNotes method that actually fills the noteData array. 
// Oh and also timecode...
- (void) setNotesAndTimecodeForAsset: (NSString *) assetURL atIndex:(NSInteger) index
{
    NSLog(@"Updating notes & timecode for asset %@ at index: %d from %@", assetURL, index, [kAppDel HTTPserver]);

    // Prep the urls
    NSString *notesFetchURLstr = [[NSString stringWithFormat:@"%@/notes%@", [kAppDel HTTPserver], assetURL] stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    NSString *tcFetchURLstr = [[NSString stringWithFormat:@"%@/timecode%@", [kAppDel HTTPserver], assetURL] stringByReplacingOccurrencesOfString:@" " withString:@"%20"];

    // Fetch the notes
    NSURL *notesFetchURL = [NSURL URLWithString:notesFetchURLstr];
    NSString *noteURLjsonString = [NSString stringWithContentsOfURL:notesFetchURL encoding:NSASCIIStringEncoding error:nil];
    if (!noteURLjsonString) {
        NSLog(@"Could not get data from the URL");
        return;
    }
    [[[kAppDel viewController] noteURLs] replaceObjectAtIndex:(NSUInteger)index withObject:[noteURLjsonString objectFromJSONString]];
    
    // Fetch the timecode
    NSURL *tcFetchURL = [NSURL URLWithString:tcFetchURLstr];
    NSString *tc = [NSString stringWithContentsOfURL:tcFetchURL encoding:NSASCIIStringEncoding error:nil];
    if (!tc) {
        NSLog(@"Could not get data from the URL");
        [[kAppDel viewController] setTimeCode:@"00:00:00:00"];
        return;
    }
    [[kAppDel viewController] setTimeCode:tc];
}


//
// Finished downloading the file listing--the files array should
// be filled with the listing of clips
//

-(void) finishLoad
{
    if (activityIndicator.isAnimating)
        [self stopActivity];
    
#if 0
    if ([files count] == 0)         
        [UIAlertView doAlert:  @"" withMsg: @"No video clips found"];
#endif
    
    NSLog (@"Found %i files", [files count]);

    [self.tableView reloadData];

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
        
        if ( ! (kIsMovie (extension) || kIsStill (extension)) )
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

#define S (NSString *)

//
// This method provides the control logic for allowing the user to
// pick a video clip from the camera roll/photo library
// On the iPad, this is done with a popover controller.
//


-(void) pickClip
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.allowsEditing = NO;
    picker.delegate = self;
    picker.mediaTypes = [NSArray arrayWithObjects:  S kUTTypeImage, S kUTTypeAudiovisualContent, S kUTTypeMovie, S kUTTypeQuickTimeMovie, S kUTTypeMPEG,  S kUTTypeMPEG4, S kUTTypeVideo, nil]; 
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

//
// This method gets called after a choice is made from the image picker (e.g., a video clip or still is selected)
//

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    if (iPHONE) {
        [[picker parentViewController] dismissModalViewControllerAnimated:YES];
    }
    else
        [popoverController dismissPopoverAnimated: YES];
    
    UIImage *thePhoto = [info objectForKey: UIImagePickerControllerOriginalImage];
    
    if (thePhoto)  {  // picked an image
        NSLog (@"UIImagePickerControllerOriginalImage has data (%@)!", thePhoto);
        [kAppDel copyVideoOrImageIntoApp: [thePhoto retain]];       // Works like an "Open In..."
    }
    else  {
        NSURL *moviePicked = [info objectForKey: UIImagePickerControllerMediaURL];
        [kAppDel copyVideoOrImageIntoApp: moviePicked]; 
    }
}

//
// Image selection cancelled....dismiss the controller
//

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
#pragma mark Table view data source delegate methods

// Customize the section in the table view.

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
        
        if (! kBonjourMode)  // We only allow clip deletion when in local mode
            cell.editingAccessoryType = UITableViewCellEditingStyleDelete;

        if (!iPHONE) {
            CGRect theFrame = cell.selectedBackgroundView.frame;
            UIView *theBG = [[UIView alloc] initWithFrame: theFrame];
            theBG.backgroundColor =  [UIColor colorWithRed: .5 green: .5 blue: .5 alpha: .7];
            cell.selectedBackgroundView = theBG;
        }
        else
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
    }

    int fType = [[fileTypes objectAtIndex: indexPath.row] intValue];
    
    if ( fType == kDirectory ) {  
        // Directories get shown with the folder image
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.text = [files objectAtIndex: indexPath.row];
        cell.imageView.image = [UIImage imageNamed: @"folder.png"];
    }
    else {
        NSString *path = [files objectAtIndex: indexPath.row];
        
        NSString *extension = [path pathExtension];
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.textLabel.text = [path stringByDeletingPathExtension];
        
        if ( kIsMovie (extension))
            cell.imageView.image = [UIImage imageNamed: @"movies.png"];
        else if ( kIsStill (extension) )
            cell.imageView.image = [UIImage imageNamed: @"camera.png"];
        else
            cell.imageView.image = nil;
    }
    
    return cell;
    
}

#pragma mark -
#pragma mark Table view delegate methods

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

// 
// Select the next (non-Directory) clip from the current clip table for playback
// Note that we do this by effectively simulating manual selection of the row
//

-(BOOL) nextClip
{
    if (!kBonjourMode) {
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
                    break;
                }

                return YES;
            }
        }
        
        return NO;
    } else {

        VideoTreeViewController *vc = [kAppDel viewController];
        
        int nextIndex = [vc curFileIndex] + 1;        
        if ([[vc curAssetURLs] count] <= nextIndex)
            return NO; // we're at the end.

        NSLog(@"Doing table selection...");
        NSIndexPath *indexP = [NSIndexPath indexPathForRow: nextIndex inSection:0];
        UITableView *tv = [[[[self navigationController] viewControllers] lastObject] tableView]; // really. I know... shh
        [tv selectRowAtIndexPath:indexP animated:YES scrollPosition:UITableViewScrollPositionTop];
            // Looks like that was only cosmetic--actually play the damn thing now:
        
        NSLog(@"Done table selection!");        
        
        [vc setCurFileIndex:nextIndex];
        NSString *theMedia = [[vc curAssetURLs] objectAtIndex:nextIndex];
        [self setNotesAndTimecodeForAsset:theMedia atIndex:nextIndex];
        [[vc notes] reloadData];      
        [self playAsset:theMedia];
        return YES;
    }

}

//
// Get the corerct path to the video clip for playback
//
           
-(void) setTheMoviePath: (NSString *) theMovie
{
    NSLog(@"setTheMoviePath");
    NSLog(@"setTheMoviePath sees theMovie at %@", theMovie);
    if (kBonjourMode) {
        NSString *thePath = [NSString stringWithFormat:@"%@%@", [kAppDel HTTPserver], theMovie];
        NSLog(thePath);
        self.moviePath = thePath;
    } else {
        NSArray *dirList = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *docDir = [dirList objectAtIndex: 0];
        self.moviePath = [docDir stringByAppendingPathComponent: theMovie];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (kBonjourMode) ? NO : YES;
}

#pragma mark -
#pragma clip/still/asset selection

// 
// A row was selected from the table
// If it's a directory, we want to drill down
// Otherwise, it must be a movie clip so we'll go ahead and play it
//

- (void)rowSelected:(int)row {
    VideoTreeViewController *vc = [kAppDel viewController];

    currentClip = row; // old shite
    
    int fileType = [[fileTypes objectAtIndex: row] intValue];
    
    // If a folder gets selected, we need to drill down
    
    if (fileType == kDirectory) {
        //
        // Create another controller to display the contents of the selected folder
        // Note we push the same controller type here (i.e., we stay in this code)
        //
        DetailViewController *detailViewController = [[DetailViewController alloc] init];        
        detailViewController.title = [files objectAtIndex: row];
        detailViewController.currentPath = [[NSString stringWithFormat: @"%@/%@", 
                                             currentPath, [files objectAtIndex: row]] stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
        NSLog (@"currentPath is %@", detailViewController.currentPath); 
        
        [self.navigationController pushViewController: detailViewController animated:YES];
        [detailViewController release];
    }
    else {   
        // Play the selected movie or display the selected still
        
        if (vc.runAllMode) {
            [vc airPlay];
            vc.runAllMode = NO;
        }
        
        NSString *theMedia;
        
        if (kBonjourMode) {
            [vc setCurAssetURLs:assetURLs]; // need to do this so the list persists for use in nextClip (autoplay)
            NSLog(@"ViewController's AssetURLs = %@", [vc curAssetURLs]);
            theMedia = [assetURLs objectAtIndex:row];
            NSLog(@"theMedia = %@", theMedia);
            [vc setCurFileIndex:row];
            [self setNotesAndTimecodeForAsset:theMedia atIndex:row];
            NSLog(@"User tapped, loading the movie, the timecode is: %@ It will be converted to float and set in loadMovie shortly.", vc.timeCode);
        }
        else
            theMedia = [NSString stringWithFormat: @"%@/%@", currentPath, 
                        [files objectAtIndex: row]];

        [self playAsset:theMedia];
        
    }
}

- (void) playAsset: (NSString *)theMedia {
    VideoTreeViewController *vc = [kAppDel viewController];

    NSLog (@"The movie/still = %@", theMedia);
    
    [self setTheMoviePath: theMedia];  // Get the correct path to the selected movie
    
    vc.clip =  theMedia;
    vc.clipPath = theMedia;
    vc.allStills = allStills;
    
    NSString *extension = [theMedia pathExtension];
    
    vc.noteTableSelected = NO;
    
    NSLog(@"Now will try loading the movie or still at: %@", moviePath);
    
    if ( kIsMovie (extension) )
        [vc loadMovie: moviePath];
    else
        [vc loadStill: moviePath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"didSelectRowAtIndexPath!");
    [self rowSelected:indexPath.row];
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
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}

- (void)dealloc {
    NSLog (@"dealloc of Detail View Controller");
    [[[kAppDel viewController] curAssetURLs] removeAllObjects]; // this will stop the autoplay too
    [moviePath release];
    
    [currentPath release];
    self.files = nil;
    self.fileTypes = nil;
    
    self.tableView.dataSource = nil;
    self.tableView.delegate = nil;

    [super dealloc];
}


@end

