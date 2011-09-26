/*
 *  myDefs.h
 *  VideoTree
 *
 *
 *  Copyright © 2010-2011 by Digital Film Tree. All rights reserved.
 */

#import "VideoTreeAlert.h"

#define APPSTORE

extern int gIOSMajorVersion;

// These are utility defines.  So just provide quick access to iVars in the app delegate class

#define kAppDel (VideoTreeAppDelegate *) [[UIApplication sharedApplication] delegate] 

#define iPHONE  ([(VideoTreeAppDelegate *) [[UIApplication sharedApplication] delegate] iPhone])
#define EQUALS(x,y) ([x caseInsensitiveCompare: y] == NSOrderedSame)
#define kdemoView  [kAppDel demoView]

#define CAMERAROLL          // We support import from the camera roll

// Are we running on iOS 5.0 or greater?  
// We want to know this because iOS 5.0 implements direct Airplay support for
// AVPlayer and also provides two new methods to get an accurate screen grab

#define kRunningOS5OrGreater  (gIOSMajorVersion >= '5') 

#define kHTTPserver  ([kAppDel HTTPserver])
#define kVideoTreeWebsite @"http://www.digitalfilmtree.com"

// FTP stuff

#define kFTPMode ([kAppDel FTPMode])
#define kBonjourMode ([kAppDel BonjourMode])
#define kFTPusername ([kAppDel FTPusername])
#define kFTPpassword ([kAppDel FTPpassword])
#define kFTPserver ([kAppDel FTPserver])
#define kSameServerAddress ([kFTPserver isEqualToString: [kAppDel serverBase]])

// #define Turner  ////////////////////////////////
// #define kOSXServer

#define homeDir ([kAppDel FTPHomeDir])

#ifdef Turner   // Special code for Turner to support their name mapping
    #define userDir  ([kAppDel BonjourMode] \
    ? [NSString stringWithFormat: @"~%@", [kAppDel FTPusername]] : @"")
#else
    #define userDir  ([kAppDel BonjourMode] \
          ? [NSString stringWithFormat: @"/~%@", [kAppDel FTPusername]] \
          : [NSString stringWithFormat: @"/%@", [kAppDel FTPusername]] )
#endif

#ifndef APPSTORE
#define kMakeLogFile        // Only make log files for our own use (not the app store version)
#endif

#ifdef kMakeLogFile
#define NSLog  MyNSLog
#define NSLog2 

// These routines were supposed to make log file generation more efficient...

extern void MyNSLog (NSString *fmt, ...);
extern void removeLogFile (void);
extern void newLogFile (void);
extern void uploadLogFile (void);
#else
#define NSLog(x,...)
#define NSLog2(x,...)
#endif

void mySleep (unsigned long millisec);
