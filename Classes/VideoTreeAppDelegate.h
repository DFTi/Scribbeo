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

#import "ServerBrowser.h"
#import "ServerBrowserDelegate.h"
#import "BonjourConnection.h"
#import "MyUIWindow.h"

@class DetailViewController;
@class VideoTreeViewController;
@class AVPlayer;

@interface VideoTreeAppDelegate : NSObject <UIApplicationDelegate, MFMailComposeViewControllerDelegate, UIImagePickerControllerDelegate, ServerBrowserDelegate, UINavigationControllerDelegate, UIAlertViewDelegate> {
    MyUIWindow              *window;
    VideoTreeViewController *viewController;
    
    DetailViewController    *rootTvc, *tvc;
    UINavigationController  *nc;
    NSMutableArray          *clipList;
    NSString                *FTPusername, *FTPpassword, *FTPserver;
    NSString                *HTTPserver, *serverBase;
    BOOL                    FTPMode;
    BOOL                    iPhone;         // Running on an iPhone
    BOOL                    BonjourMode;
    BOOL                    demoView;
    CMTime                  theTime;
    float                   theRate;
    ServerBrowser           *serverBrowser;
    NSNetService            *server;
    BonjourConnection       *bonjour;
    NSString                *FTPhomeDir;
    NSURL                   *theURL;        // From the camera roll or another app
    NSString                *theExtension;
    NSString                *outputFilename;
    
    UIImage                 *imageReference;  // image selected from camera roll
}

@property (nonatomic, retain) IBOutlet MyUIWindow              *window;
@property (nonatomic, retain) IBOutlet VideoTreeViewController *viewController;
@property (nonatomic, retain) IBOutlet NSMutableArray          *clipList;
@property BOOL demoView;

@property (nonatomic, copy)    NSString *FTPusername, *FTPpassword, *FTPserver;

@property (nonatomic, assign)  DetailViewController   *tvc;
@property (nonatomic, retain)  DetailViewController   *rootTvc;
@property (nonatomic, retain)  UINavigationController *nc;
@property (nonatomic, retain)  NSURL                *theURL;
@property (nonatomic, retain)  NSString             *theExtension, *outputFilename;

@property BOOL  FTPMode, iPhone, BonjourMode;
@property (nonatomic, retain)  NSString             *FTPHomeDir;
@property (nonatomic, retain)  NSString             *HTTPserver;
@property (nonatomic, retain)  NSString             *serverBase;

@property (nonatomic, retain)  ServerBrowser        *serverBrowser;
@property (nonatomic, retain)  NSNetService         *server;
@property (nonatomic, retain)  BonjourConnection    *bonjour;

-(void) finishLoad;

-(natural_t) freemem; 
-(void) releasemem;

-(void) makeSettings;
-(void) copyVideoOrImageIntoApp: (id) from;
-(void) saveFileNameEntered;
-(void) animateTransition: (BOOL) start;

-(void) makeDetailTableViewController;

@end

