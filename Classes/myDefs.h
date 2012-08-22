/*
 *  myDefs.h
 *  VideoTree
 *
 *
 *  Copyright © 2010-2011 by Digital Film Tree. All rights reserved.
 */

#import "VideoTreeAlert.h"

#define APPSTORE


// might have disabled debug who knows. force switch here? fuck it
// #define DEBUG YES
//#ifdef DEBUG
//@implementation NSURLRequest (IgnoreSSL)
//
//+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString *)host
//{
//    return YES;
//}
//
//@end
//#endif

extern int gIOSMajorVersion;

#define kNoteDelimiter   @"+"

// These are utility defines.  So just provide quick access to iVars in the app delegate class

#define kAppDel (VideoTreeAppDelegate *) [[UIApplication sharedApplication] delegate] 

#define iPHONE  ([(VideoTreeAppDelegate *) [[UIApplication sharedApplication] delegate] iPhone])
#define EQUALS(x,y) ([x caseInsensitiveCompare: y] == NSOrderedSame)
#define kdemoView  [kAppDel demoView]

#define kIsMovie(x) (EQUALS (x, @"mp4") || EQUALS (x, @"mov") || EQUALS (x, @"m4v") || EQUALS (x, @"m3u8"))
#define kIsStill(x)  (EQUALS (x, @"jpg") || EQUALS (x, @"jpeg") || EQUALS (x, @"png"))

// Are we running on iOS 5.0 or greater?  
// We want to know this because iOS 5.0 implements direct Airplay support for
// AVPlayer and also provides two new methods to get an accurate screen grab

#define kRunningOS5OrGreater  (gIOSMajorVersion >= '5') 

#define kHTTPserver  ([kAppDel HTTPserver])
#define kVideoTreeWebsite @"http://www.scribbeo.com"


#define kBonjourMode ([kAppDel BonjourMode])

// #define Turner  ////////////////////////////////
// #define kOSXServer

//
//#ifdef DEBUG
//#define kMakeLogFile        // Only make log files for our own use (not the app store version)
//#endif
//
//#ifdef kMakeLogFile
//#define NSLog  MyNSLog
//#define NSLog2 

// These routines were supposed to make log file generation more efficient...

extern void MyNSLog (NSString *fmt, ...);
extern void removeLogFile (void);
extern void newLogFile (void);
extern void uploadLogFile (void);
//#else
//#define NSLog(x,...) // Disables NSLog
//#define NSLog2(x,...)
//#endif

void mySleep (unsigned long millisec);
