 //
//  VideoTreeAppDelegate.h
//  VideoTree
//
//  Created by Steve Kochan on 9/10/10.
//  Copyright © 2010-2011 by Digital Film Tree. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "myDefs.h"
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import <mach/mach.h>
#import <mach/mach_host.h>
#import <AVFoundation/AVFoundation.h>

#import "MyUIWindow.h"
#import "MediaSource.h"

@class DetailViewController;
@class VideoTreeViewController;
@class AVPlayer;

@interface VideoTreeAppDelegate : NSObject <UIApplicationDelegate, MFMailComposeViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIAlertViewDelegate> {
    MyUIWindow              *window;
    VideoTreeViewController *viewController;
    
    DetailViewController    *rootTvc, *tvc;
    UINavigationController  *nc;
    NSMutableArray          *clipList;

    BOOL                    iPhone;         // Running on an iPhone
    
    BOOL                    demoView;
    CMTime                  theTime;
    float                   theRate;
    
    NSURL                   *theURL;        // From the camera roll or another app FIXME rename this from "the URL" ... wtf?
    NSString                *theExtension; // really necessary on the app delegate?
    NSString                *outputFilename; // again, is this necessary?
    UIImage                 *imageReference;  // and this, what is this?
    // looks like the 4 above are related to local mode, perhaps another extension to AppServer, rather, MediaSource?
    
    MediaSource             *mediaSource;
}

@property (nonatomic, retain) IBOutlet MyUIWindow              *window;
@property (nonatomic, retain) IBOutlet VideoTreeViewController *viewController;
@property (nonatomic, retain) IBOutlet NSMutableArray          *clipList;
@property BOOL demoView, iPhone;

@property (nonatomic, assign)  DetailViewController   *tvc;
@property (nonatomic, retain)  DetailViewController   *rootTvc;
@property (nonatomic, retain)  UINavigationController *nc;
@property (nonatomic, retain)  NSURL                *theURL;
@property (nonatomic, retain)  NSString             *theExtension, *outputFilename;

@property (nonatomic, retain) MediaSource           *mediaSource;

-(void) finishLoad;

-(natural_t) freemem; 
-(void) releasemem;
-(void) makeSettings;
-(void) copyVideoOrImageIntoApp: (id) from;
-(void) saveFileNameEntered;
-(void) animateTransition: (BOOL) start;

-(void) makeDetailTableViewController;
-(void)setupDefaults;

-(void)makeList;

@end

