/*
 *  myDefs.h
 *  VideoTree
 *
 *
 *  Copyright © 2010-2011 by Digital Film Tree. All rights reserved.
 */

#import "VideoTreeAlert.h"


extern int gIOSMajorVersion;

#define kdemoView  [kAppDel demoView]

#define iPHONE  ([(VideoTreeAppDelegate *) [[UIApplication sharedApplication] delegate] iPhone])
#define EQUALS(x,y) ([x caseInsensitiveCompare: y] == NSOrderedSame)
#define kAppDel (VideoTreeAppDelegate *) [[UIApplication sharedApplication] delegate] 
#define kdemoView  [kAppDel demoView]

#define CAMERAROLL
#define kRunningOS5OrGreater  (gIOSMajorVersion >= '5')  /* change this to dynamically determine */

#define kHTTPserver  ([kAppDel HTTPserver])

// FTP stuff

#define kFTPMode ([kAppDel FTPMode])
#define kBonjourMode ([kAppDel BonjourMode])
#define kFTPusername ([kAppDel FTPusername])
#define kFTPpassword ([kAppDel FTPpassword])
#define kFTPserver ([kAppDel FTPserver])
#define kSameServerAddress ([kFTPserver isEqualToString: [kAppDel serverBase]])

// #define Turner  ////////////////////////////////
// #define kOSXServer

#ifdef  kOSXServer
    #define homeDir @"/Sites/VideoTree"
    #define userDir @"~VideoTree/VideoTree"  // for http access with OS X
#else
    #define homeDir ([kAppDel FTPHomeDir])

    #ifdef Turner
        #define userDir  ([kAppDel BonjourMode] \
        ? [NSString stringWithFormat: @"~%@", [kAppDel FTPusername]] : @"")
    #else
        #define userDir  ([kAppDel BonjourMode] \
              ? [NSString stringWithFormat: @"/~%@", [kAppDel FTPusername]] \
              : [NSString stringWithFormat: @"/iPad/%@", [kAppDel FTPusername]] )
    #endif
#endif

#define kMakeLogFile

#ifdef kMakeLogFile
#define NSLog  MyNSLog
#define NSLog2 

extern void MyNSLog (NSString *fmt, ...);
extern void removeLogFile (void);
extern void newLogFile (void);
extern void uploadLogFile (void);
#else
#define NSLog(x,...)
#endif

void mySleep(unsigned long millisec);
