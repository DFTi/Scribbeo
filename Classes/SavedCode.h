/*
 *  SavedCode.h
 *  VideoTree
 *
 *  Created by Steve Kochan on 10/30/10.
 *  Copyright 2010-2011 by DFT Software. All rights reserved.
 *
 */

#if 0

#ifdef  kOSXServer
#define homeDir @"/Sites/VideoTree"
#define userDir @"~VideoTree/VideoTree"  // for http access with OS X
#endif


@implementation UIImageView (Scaling) // extensions to UIImageView

// scale the view to fill the given bounds without distorting
- (void)expandToFill:(CGRect)bounds
{
    UIImage *image = self.image; // get the image of this view
    CGRect frame = self.frame; // get the frame of this view
    
    // check if the image is bound by its height
    if (image.size.height / image.size.width >
        bounds.size.height / bounds.size.width)
    {
        // expand the new height to fill the entire view
        frame.size.height = bounds.size.height;
        
        // calculate the new width so the image isn't distorted
        frame.size.width = image.size.width * bounds.size.height /
        image.size.height;
        
        // add to the x and y coordinates so the view remains centered
        frame.origin.y += (self.frame.size.height - frame.size.height) / 2;
        frame.origin.x += (self.frame.size.width - frame.size.width) / 2;
    } // end if
    else // the image is bound by its width
    {
        // expand the new width to fill the entire view
        frame.size.width = bounds.size.width;
        
        // calculate the new height so the image isn't distorted
        frame.size.height = image.size.height * bounds.size.width /
        image.size.width;
        
        // add to the x and y coordinates so the view remains centered
        frame.origin.y += (self.frame.size.height - frame.size.height) / 2;
        frame.origin.x += (self.frame.size.width - frame.size.width) / 2;
    } // end else
    
    self.frame = frame; // assign the new frame
} 
@end 

// This creates a "picker" style gradient appearance
// Prepare colors

CGFloat alphaValues[] = {0.9, 0.6, 0.35, 0.2, 0.1, 0.01, 0.0, 0.01, 0.1, 0.2, 0.35, 0.6, 0.9};
NSUInteger numberOfValues = sizeof(alphaValues) / sizeof(*alphaValues);
NSMutableArray *cgColors = [NSMutableArray arrayWithCapacity: numberOfValues];

for (NSUInteger i = 0; i < numberOfValues; ++i ) {
    CGColorRef color = [[UIColor colorWithWhite:0.0 alpha: alphaValues[i]] CGColor];
    [cgColors addObject: (id)color];
}

// Gradient layer

CAGradientLayer *gradientLayer = [CAGradientLayer layer];
gradientLayer.colors = cgColors;
gradientLayer.zPosition = 10.0f;
CGRect layerFrame = self.tableView.layer.frame;
gradientLayer.frame = layerFrame;
[self.tableView.layer addSublayer: gradientLayer];


UIImage* UIImageFromLayer(CGLayerRef layer)
{
    // Create the bitmap context
    CGContextRef    bitmapContext = NULL;
    void *          bitmapData;
    int             bitmapByteCount;
    int             bitmapBytesPerRow;
    CGSize          size = CGLayerGetSize(layer);
    
    // Declare the number of bytes per row. Each pixel in the bitmap in this
    // example is represented by 4 bytes; 8 bits each of red, green, blue, and
    // alpha.
    bitmapBytesPerRow   = (size.width * 4);
    bitmapByteCount     = (bitmapBytesPerRow * size.height);
    
    // Allocate memory for image data. This is the destination in memory
    // where any drawing to the bitmap context will be rendered.
    bitmapData = malloc( bitmapByteCount );
    if (bitmapData == NULL)
    {
        return nil;
    }
    
    // Create the bitmap context. We want pre-multiplied ARGB, 8-bits
    // per component. Regardless of what the source image format is
    // (CMYK, Grayscale, and so on) it will be converted over to the format
    // specified here by CGBitmapContextCreate.
    bitmapContext = CGBitmapContextCreate (bitmapData, size.width, size.height,8,bitmapBytesPerRow,
                                           CGColorSpaceCreateDeviceRGB(),kCGImageAlphaNoneSkipFirst);
    
    if (bitmapContext == NULL)
        // error creating context
        return nil;
    
    CGContextScaleCTM(bitmapContext, 1, -1);
    CGContextTranslateCTM(bitmapContext, 0, -size.height);
    
    // Draw the image to the bitmap context. Once we draw, the memory
    // allocated for the context for rendering will then contain the
    // raw image data in the specified color space.
    CGContextDrawLayerAtPoint(bitmapContext, CGPointZero, layer);
    CGImageRef   img = CGBitmapContextCreateImage(bitmapContext);
    UIImage*     ui_img = [UIImage imageWithCGImage: img];
    
    CGImageRelease(img);
    CGContextRelease(bitmapContext);
    free(bitmapData);
    
    return ui_img;
    
}

-(void) frameDraw
{
    id obj = [playerLayer getObjectForKey: @"contents"];
    NSLog (@"obj = %@", obj);
    
    self.newThumb = [self UIImageFromLayer: playerLayer];
}

///////////

#ifdef ANOTHERWAY
/// somewhere else we are called for the image
-(void) frameDraw
{
    UIDeviceOrientation useOrientation = [[UIDevice currentDevice] orientation];
    CGImageRef screen = UIGetScreenImage();
    self.newThumb = [UIImage imageWithCGImage:screen];
    CGImageRelease(screen);
    
    UIGraphicsBeginImageContext(CGSizeMake(1024.0f, 768.0f));
    CGContextRef context = UIGraphicsGetCurrentContext();
    if ( useOrientation == UIDeviceOrientationLandscapeRight )
    {
        CGContextRotateCTM (context, M_PI/2.0f);
        [newThumb drawAtPoint:CGPointMake(0.0f, -1024.0f)];
    } else {
        CGContextRotateCTM (context, -M_PI/2.0f);
        [newThumb drawAtPoint:CGPointMake (768.0f, 0.0f)];
    }
    self.newThumb  = UIGraphicsGetImageFromCurrentImageContext();
}
#endif
////////////////////////////////

- (void)screenshot 
{
    // Create a graphics context with the target size
    
    CGSize imageSize = [[UIScreen mainScreen] bounds].size;
    
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Iterate over every window from back to front
    for (UIWindow *window in [[UIApplication sharedApplication] windows]) 
    {
        if (![window respondsToSelector:@selector(screen)] || [window screen] == [UIScreen mainScreen])
        {
            // -renderInContext: renders in the coordinate space of the layer,
            // so we must first apply the layer's geometry to the graphics context
            CGContextSaveGState(context);
            // Center the context around the window's anchor point
            CGContextTranslateCTM(context, [window center].x, [window center].y);
            // Apply the window's transform about the anchor point
            CGContextConcatCTM(context, [window transform]);
            // Offset by the portion of the bounds left of and above the anchor point
            CGContextTranslateCTM(context,
                                  -[window bounds].size.width * [[window layer] anchorPoint].x,
                                  -[window bounds].size.height * [[window layer] anchorPoint].y);
            
            // Render the layer hierarchy to the current context
            [[window layer] renderInContext:context];
            
            // Restore the context
            CGContextRestoreGState(context);
        }
    }
    
    // Retrieve the screenshot image
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    UIImageWriteToSavedPhotosAlbum(image, self, nil, nil);
    NSLog (@"wrote image to photo album");
}
////////////////////////////////
#if 0

- (void)extractFrame:(int)frame atTime:(double)time{
    CMTime timeStruct, timeStart, timeDuration;
    __block ExtractedFrames *theExtractedFrameObject = self.extractedFrames;
    
    timeStruct.value = (int)(0);
    timeStruct.timescale = 30;
    timeStruct.flags = kCMTimeFlags_Valid;
    timeStruct.epoch = 0;
    
    timeStart.value = (int)(time*600);
    timeStart.timescale = 600;
    timeStart.flags = kCMTimeFlags_Valid;
    timeStart.epoch = 0;
    
    timeDuration.value = (int)(1);
    timeDuration.timescale = 30;
    timeDuration.flags = kCMTimeFlags_Valid;
    timeDuration.epoch = 0;
    
    CMTimeRange extractTimeRange;
    extractTimeRange.start = timeStart;
    extractTimeRange.duration = timeDuration;
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:self.videoData.avAsset 
                                                                           presetName:AVAssetExportPresetHighestQuality];
    //Now define an output URL
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *tmpVideoFilePath = [docDir stringByAppendingPathComponent:[NSString stringWithFormat:@"video%i.mov",frame]];
    //see if the file exists, if so delete
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:tmpVideoFilePath]) {
        NSError *error = nil;
        [fileManager removeItemAtPath:tmpVideoFilePath error:&error];
        if (error !=nil) {
            NSLog(@"FrameExtractor: ERROR temp video file could not be deleted");
        }          
    }
    //The output directory is clean now start the export
    NSURL *tmpVideoFileURL = [[NSURL alloc] initFileURLWithPath:tmpVideoFilePath];
    exportSession.outputURL = tmpVideoFileURL;
    [exportSession setOutputFileType: AVFileTypeQuickTimeMovie];
    [tmpVideoFileURL release];
    exportSession.timeRange = extractTimeRange;
    
    [exportSession exportAsynchronouslyWithCompletionHandler: ^
     {
         if(exportSession.error)
         {
             // Export session failed
             NSLog(@"error = %@", exportSession.error);
         }
         else
         {
             // successful export
             CMTime actualTime;
             NSError *error = nil;
             
             //now load the new movie
             NSMutableDictionary *options = [NSMutableDictionary dictionary];
             BOOL yes = YES;
             NSValue *value = [NSValue valueWithBytes:&yes objCType:@encode(BOOL)];
             [options setObject:value forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
             AVURLAsset *movie = [AVURLAsset URLAssetWithURL:tmpVideoFileURL options:nil];
             AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc]
                                                      initWithAsset:movie];
             imageGenerator.appliesPreferredTrackTransform = YES;
             CGImageRef cgImage = [imageGenerator copyCGImageAtTime:timeStruct
                                                         actualTime:&actualTime 
                                                              error:&error];
             if (error) {
                 NSLog(@"FrameExtractor: ERROR extracting image from video at time %f, error - %@\n",timeStruct.value, [error localizedDescription]);
             }
             //now we will put the extracted frame into the ExtractedFrames object and call the delegate
             NSMutableDictionary *theExtractedFrames = [[NSMutableDictionary alloc] initWithDictionary:theExtractedFrameObject.extractedFrameDictionary];
             NSString *extractedFrameKey = [[NSString alloc] initWithFormat:@"Frame%iKey", frame];
             [theExtractedFrames setObject:[UIImage imageWithCGImage:cgImage] forKey:extractedFrameKey];
             extractedFrames.extractedFrameDictionary = theExtractedFrames;
             [theExtractedFrames release];
             theExtractedFrameObject.numberOfFramesExtracted = [NSNumber numberWithInt:[theExtractedFrameObject.numberOfFramesExtracted intValue] +1];
             [extractedFrameKey release];
             [self.delegate frameExtractor:self didExtractFrame:frame savedIn:self.extractedFrames];
         }
         
         [exportSession release];
     }
     ];
}



-(void) frameDraw
{
    CGRect theFrame = playerLayerView.layer.frame;
    UIWebView *myView = [[UIView alloc] initWithFrame: theFrame];
    UIWindow *offscreenWindow = [[UIWindow alloc] initWithFrame:theFrame];
    [offscreenWindow addSubview: myView];
    // Now take the screenshot
    UIGraphicsBeginImageContext(playerLayerView.layer.bounds.size);
    [playerLayer renderInContext:UIGraphicsGetCurrentContext()];
    self.newThumb = UIGraphicsGetImageFromCurrentImageContext();
    //UIImageWriteToSavedPhotosAlbum(viewImage, nil, nil, nil);
    UIGraphicsEndImageContext();
}
#endif
#endif


float hfactor = value.bounds.size.width / screenRect.size.width;
float vfactor = value.bounds.size.height / screenRect.size.height;

float factor = max(hfactor, vfactor);

// Divide the size by the greater of the vertical or horizontal shrinkage factor
float newWidth = value.bounds.size.width / factor;
float newHeight = value.bounds.size.height / factor;

// Then figure out if you need to offset it to center vertically or horizontally
float leftOffset = (screenRect.size.width - newWidth) / 2;
float topOffset = (screenRect.size.height - newHeight) / 2;

CGRect newRect = CGRectMake(leftOffset, topOffset, newWidth, newHeight);
////////////////////////////
// Image resize

CGSize newSize = (CGSize) {imageR.size.width / 16; imageR.size.height / 16 };

UIGraphicsBeginImageContext(newSize);
[imageR drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
self.newThumb = UIGraphicsGetImageFromCurrentImageContext();
UIGraphicsEndImageContext();

///////////////////
tracks = [asset tracksWithMediaType: AVMediaTypeTimecode];

if ([tracks count] > 0) {
    NSLog (@"Found a timecode track, type = %@", [[tracks objectAtIndex: 0] mediaType]);
    NSArray *segments = [[tracks objectAtIndex: 0] segments];
    
    for (int i = 0; i < [segments count]; ++i)  {
        AVAssetTrackSegment *seg = [segments objectAtIndex: i];
        
        if ([seg isEmpty])
            NSLog (@"\tsegment %i is empty", i);
            else {
                CMTimeMapping cmtMap = [seg timeMapping];
                
                NSLog (@"\tsegment %i: source: (%lx, %lx)", i,
                       cmtMap.source, cmtMap.target);
                //          cmtMap.target.start, cmtMap.target.duration);
            }
        
    }
}
////////
#if 0
NSArray *mdArray = [player.currentItem timedMetadata];

if (! mdArray) {
    NSLog (@"No metadata found");
    return kCMTimeZero;
}
NSLog (@"Available metadata formats: %@",  [player.currentItem.asset availableMetadataFormats]);
NSArray *mdArray =  [player.currentItem.asset commonMetadata];

if ([mdArray count] > 0) {    
    AVMetadataItem *mdItem = [mdArray objectAtIndex: 0];
    
    NSLog (@"Found metadatItem: key = %@, value = %@", [mdItem key], (NSString *) [mdItem value]);
}
else
NSLog (@"No common metadata");

//////////// playing from a URL requiring credentials

NSURLCredential *credential = [[NSURLCredential alloc]
                               initWithUser: @"userName"
                               password: @"password"
                               persistence: NSURLCredentialPersistenceForSession];

self.credential = credential;
[credential release];

// In addition, create an appropriate NSURLProtectionSpace object, as shown here. Make appropriate modifications for the realm you are accessing:

NSURLProtectionSpace *protectionSpace = [[NSURLProtectionSpace alloc]
             initWithHost: "streams.mydomain.com"
             port: 80
             protocol: @"http"
             realm: @"mydomain.com"
             authenticationMethod: NSURLAuthenticationMethodDefault];

self.protectionSpace = protectionSpace;
[protectionSpace release];

// Add the URL credential and the protection space to the Singleton NSURLCredentialStorage object. Do this by calling, for example, the setCredential:forProtectionSpace: method, as shown here:

[[NSURLCredentialStorage sharedCredentialStorage]
 setDefaultCredential: credential
 forProtectionSpace: protectionSpace];

// With the credential and protection space information in place, you can then play the protected stream.

#endif
//////////
#ifdef kFULLSCREENMPMOVIEPLAYERCONTROLLER

// Fullscreen support using MPMoviePlayerController for AirPlay

-(IBAction) fullScreen
{    
    [self pauseIt];
    
    if (!movieController) {
        movieController = [[MPMoviePlayerController alloc] initWithContentURL: movieURL];
    }
    
    [movieController setAllowsWirelessPlayback:YES];
    NSLog (@"set allows wireless playback");
    movieController.controlStyle = MPMovieControlStyleFullscreen;
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(leaveFullScreen:)                                                 
                                                 name:MPMoviePlayerPlaybackDidFinishNotification object: movieController];    
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(leaveFullScreen:) 
                                                 name:MPMoviePlayerDidExitFullscreenNotification object: movieController];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(changeState:) 
                                                 name:MPMoviePlayerLoadStateDidChangeNotification object: movieController];
    
    [movieController setFullscreen: YES animated: YES];
    [movieController setInitialPlaybackTime: CMTimeGetSeconds([player currentTime])];
    movieController.view.frame = [self.view bounds];
    
    if (stampVideo) {
        CGRect stampFrame = movieController.view.frame;
        self.stampLabelFull = [[UILabel alloc] initWithFrame: 
                               CGRectMake (stampFrame.size.width - 70, stampFrame.size.height - 135, 50, 50)];
        stampLabelFull.text = initials;
        stampLabelFull.backgroundColor = [UIColor clearColor];
        stampLabelFull.textColor = [UIColor whiteColor];
        [movieController.view addSubview: stampLabelFull];
        [stampLabelFull release];
    }
    
    [self.view addSubview: movieController.view];
    fullScreenMode = YES;
}


-(void) leaveFullScreen: (NSNotification *) aNotification {
    MPMoviePlayerController *thePlayer = [aNotification object];
    
    if (autoPlay && [aNotification.name isEqualToString: MPMoviePlayerPlaybackDidFinishNotification]  
        && [[aNotification.userInfo objectForKey: 
             MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] integerValue] 
        == MPMovieFinishReasonPlaybackEnded) {
        
        if (selectedNextClip) {
            selectedNextClip = NO;
            return;
        }
        
        VideoTreeAppDelegate *app =  [[UIApplication sharedApplication] delegate];
        selectedNextClip = YES;
        
        NSLog (@"autoplay next clip in fullscreen mode");
        NSIndexPath *indexP = [NSIndexPath indexPathForRow: [app.tvc currentClip] inSection:0];
        
        @try  {
            [app.tvc tableView: nil didSelectRowAtIndexPath: indexP];
            [app.tvc.tableView selectRowAtIndexPath: indexP animated: YES scrollPosition: UITableViewScrollPositionBottom];
        }
        @catch (NSException *exception) {
            NSLog (@"End of clips!");
        }
        
        return;
    }
    
    NSLog (@"Leaving full screen mode");
    selectedNextClip = NO;
    fullScreenMode = NO;
    
    [thePlayer.view removeFromSuperview];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MPMoviePlayerPlaybackDidFinishNotification object: thePlayer]; 
    
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:MPMoviePlayerDidExitFullscreenNotification object: thePlayer]; 
    
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:MPMoviePlayerLoadStateDidChangeNotification object: thePlayer];
}
///////////////////////////////
#pragma mark -
#pragma mark Clips

#ifdef OLDSTUFF

-(NSArray *) shows
{
    NSMutableArray *results = nil;
    NSString *lastShow = nil;
    
    for (Clip *aClip in clipList)
        if (! [aClip.show isEqualToString: lastShow]) {
            if (! results)
                results = [NSMutableArray array];
                lastShow = aClip.show;
                [results addObject: aClip.show];
        }
    return results;
}

-(NSArray *) episodesForShow: (NSString *) theShow {
    NSMutableArray *results = nil;
    NSString *lastEpisode = nil;
    
    for (Clip *aClip in clipList)
        if ([aClip.show isEqualToString: theShow] && ![aClip.episode isEqualToString: lastEpisode]) {
            if (! results)
                results = [NSMutableArray array];
                lastEpisode = aClip.episode;
                [results addObject: aClip.episode];
        }
    return results;
}

-(NSArray *) datesForShow: (NSString *) theShow episode: (NSString *) theEpisode {
    NSMutableArray *results = nil;
    NSString *lastDate = nil;
    
    for (Clip *aClip in clipList)
        if ([aClip.show isEqualToString: theShow] && [aClip.episode isEqualToString: theEpisode]
            && ![aClip.date isEqualToString: lastDate]) {
            if (! results)
                results = [NSMutableArray array];
                lastDate = aClip.date;
                [results addObject: aClip.date];
        }
    return results;
}

-(NSArray *) tapesForShow: (NSString *) theShow episode: (NSString *) theEpisode date: (NSString *) theDate {
    NSMutableArray *results = nil;
    NSString *lastTape = nil;
    
    
    for (Clip *aClip in clipList) {
        if ([aClip.show isEqualToString: theShow] && [aClip.episode isEqualToString: theEpisode] &&
            [aClip.date isEqualToString: theDate] && ![aClip.tape isEqualToString: lastTape]) {
            if (! results)
                results = [NSMutableArray array];
                lastTape = aClip.tape;
                [results addObject: aClip.tape];
        }
    }
    return results;
}


-(NSArray *) filesForShow: (NSString *) theShow episode: (NSString *) theEpisode 
date: (NSString *) theDate tape: (NSString *) theTape {
    NSMutableArray *results = nil;
    
    for (Clip *aClip in clipList)
        if ([aClip.show isEqualToString: theShow] && [aClip.episode isEqualToString: theEpisode]
            && [aClip.date isEqualToString: theDate]  && [aClip.tape isEqualToString: theTape]) {
            if (! results)
                results = [NSMutableArray array];
                
                [results addObject: aClip.file];
        }
    return results;
}

-(NSString *) pathForShow: (NSString *) theShow episode: (NSString *) theEpisode 
date: (NSString *) theDate tape: (NSString *) theTape file: (NSString *) theFile {    
    for (Clip *aClip in clipList)
        if ([aClip.show isEqualToString: theShow] && [aClip.episode isEqualToString: theEpisode]
            && [aClip.date isEqualToString: theDate] &&  [aClip.tape isEqualToString: theTape] && [aClip.file isEqualToString: theFile]
            ) {
            return aClip.path;
        }
    
    return nil;
}

#ifdef DVDSUPPORT

dc.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithImage: 
     [UIImage imageNamed: @"dvd-icon.png"] style: UIBarButtonItemStyleBordered target: self 
                                    action: @selector(runAll)] autorelease];  
-(void) updateClipLabels
{
    episodeLabel.text = episode, 
    dateLabel.text = filmDate;
    tapeLabel.text = tape;
    NSLog (@"clip = %@, currenlyPlaying = %@", clip, currentlyPlaying);
    clipLabel.text = [[[clip componentsSeparatedByString:@"_"] lastObject] stringByDeletingPathExtension];
}

-(IBAction) previousClip
{
    VideoTreeAppDelegate *app =  (VideoTreeAppDelegate *) [[UIApplication sharedApplication] delegate];
    
    if (runAllMode) {
        if (--clipNumber >= 0) {
            Clip *aClip = [allClips objectAtIndex: clipNumber];
            self.show =  aClip.show;
            self.clip =  aClip.file;
            self.filmDate = aClip.date;
            self.tape = aClip.tape;
            self.episode = aClip.episode;
            NSLog (@"    === freemem = %.2f MB, clip = %@", [app freemem] / (1024. * 1024.), aClip.file);
            [self loadMovie: aClip.path];
            clipNumber;
        } 
        
        return;
    }
    
    NSLog (@"autoplay previous clip");
    [app.tvc setCurrentClip: [app.tvc currentClip] - 2];
    NSIndexPath *indexP = [NSIndexPath indexPathForRow: [app.tvc currentClip] inSection:0];
    
    @try  {
        [app.tvc tableView: nil didSelectRowAtIndexPath: indexP];
        [app.tvc.tableView selectRowAtIndexPath: indexP animated: YES scrollPosition: UITableViewScrollPositionTop];
    }
    @catch (NSException *exception) {
        NSLog (@"End of clips!");
    }
}


-(BOOL) clipForward
{
    DetailViewController *dc =  [ (VideoTreeAppDelegate *)[[UIApplication sharedApplication] delegate] tvc];
    
    NSLog (@"autoplay next clip");
    return [dc nextClip];
}

-(IBAction) nextClip
{
    if ([self clipForward])
        [self updateClipLabels];
}

-(IBAction) nextTape
{
    Clip *aClip;
    
    while (++clipNumber < [allClips count]) {
        aClip = [allClips objectAtIndex: clipNumber];
        
        if (! [tape isEqualToString: aClip.tape]) 
            break;
    }
    
    if (clipNumber < [allClips count]) {
        self.show =  aClip.show;
        self.clip =  aClip.file;
        self.filmDate = aClip.date;
        self.tape = aClip.tape;
        self.episode = aClip.episode;
        NSLog (@"Next tape: %@", aClip.tape);
        [self loadMovie: aClip.path];
    }
    else
        clipNumber = [allClips count] - 1;
        }

-(IBAction) previousTape
{
    Clip *aClip;
    
    while (--clipNumber >= 0 && clipNumber < [allClips count]) {
        aClip = [allClips objectAtIndex: clipNumber];
        
        if (![tape isEqualToString: aClip.tape])  
            break;
    }
    
    if (clipNumber < 0) {
        clipNumber = 0;
        return;
    }
    
    tape = aClip.tape;
    
    // Get first clip of previous tape
    
    while (--clipNumber >= 0) {
        aClip = [allClips objectAtIndex: clipNumber];
        
        if (! [tape isEqualToString: aClip.tape]) {
            ++clipNumber;
            aClip = [allClips objectAtIndex: clipNumber];
            break;
        }
    }
    
    self.show =  aClip.show;
    self.clip =  aClip.file;
    self.filmDate = aClip.date;
    self.tape = aClip.tape;
    self.episode = aClip.episode;
    
    NSLog (@"Previous tape: %@  === freemem = %.2f MB", aClip.tape);
    [self loadMovie: aClip.path];
}

-(void) runAll
{
    VideoTreeAppDelegate *appDel = (VideoTreeAppDelegate *) [[UIApplication sharedApplication] delegate];
    VideoTreeViewController *vc = [appDel viewController];
    
    vc.runAllMode =  YES;
    vc.autoPlay = YES;
    vc.allClips = [NSMutableArray array];
    vc.clipNumber = -1;
    
    NSArray *tapes  = [self tapesForShow: showName episode: episode date: date];
    
    for (NSString *aTape in tapes) {
        NSArray *clips = [self filesForShow:showName episode:episode date:date tape: aTape];
        
        for (NSString *theClip in clips) {
            NSString *theMovie = [self pathForShow: showName episode: episode date: date tape: aTape file: theClip];
            
            if ([theMovie rangeOfString: @"http://"].location == NSNotFound  && 
                [theMovie rangeOfString: @"https://"].location == NSNotFound) {
                theMovie = [theMovie stringByReplacingOccurrencesOfString: @":" withString: @","];
                
                NSArray *dirList = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString *docDir = [dirList objectAtIndex: 0];
                
                self.moviePath = [docDir stringByAppendingPathComponent: theMovie];
            }
            else 
                self.moviePath = theMovie;
                
                NSLog (@"moviePath = %@", moviePath);
                
                // if (vc.currentlyPlaying  && [vc.currentlyPlaying isEqualToString: moviePath])
                //    continue;
                
                
                Clip *aClip = [[Clip alloc] init];
                aClip.path = moviePath;
                aClip.file = theClip;
                
                [vc.allClips addObject: aClip];
            [aClip release];
        }
    }
    
    NSLog (@"%@", vc.allClips);
    
    if ([vc.allClips count] == 0) {
        vc.runAllMode = NO;
        return;
    }
    
    if (vc.player)
        [vc cleanup];
    
    [vc nextClip];
    vc.airPlayMode = YES;
    vc.remote.hidden = NO;
}

// This code regenerated the thumbnail for the PDF file 

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
}

-(void) loadStill2: (NSString *) link 
{
    if (! stillWebView)  {
        CGRect theFrame = drawView.frame;
        CGSize theSize = { 500, 200 };
        theFrame.size = theSize;
        
        stillWebView = [[UIWebView alloc] initWithFrame: drawView.frame];
        stillWebView.scalesPageToFit = YES;
        stillWebView.delegate = self;
        
        stillView = [[UIImageView alloc] initWithFrame: drawView.frame];
    }
    
    NSURLRequest *request = [NSURLRequest requestWithURL: [NSURL URLWithString: link]];
    
    stillView.contentMode = UIViewContentModeScaleAspectFit;
    [stillWebView loadRequest: request];
}

- (void) webViewDidFinishLoad:(UIWebView *)webView
{    
    NSLog (@"image loaded!"); 
    NSLog (@"webView size is (%g, %g)", webView.bounds.size.width, webView.bounds.size.height);
    
    [webView sizeToFit];
    
    NSLog (@"stillView origin = (%g, %g), size = (%g, %g)", stillView.frame.origin.x, stillView.frame.origin.y,
           stillView.frame.size.width, stillView.frame.size.height);
    NSLog (@"webView size is (%g, %g)", webView.bounds.size.width, webView.bounds.size.height);
    
    //  UIGraphicsBeginImageContext(stillView.frame.size);
    UIGraphicsBeginImageContextWithOptions(webView.frame.size, YES, 1);
    
    [webView.layer renderInContext: UIGraphicsGetCurrentContext()];
    
    stillView.image = UIGraphicsGetImageFromCurrentImageContext();
    stillView.autoresizesSubviews = NO; 
    playerLayerView.autoresizesSubviews = NO;
    
    UIGraphicsEndImageContext();
    
    stillView.userInteractionEnabled = YES;
    
    [playerLayerView addSubview: stillView];
    [stillView addSubview: drawView];
    
    stillShows = YES;
}

#endif
