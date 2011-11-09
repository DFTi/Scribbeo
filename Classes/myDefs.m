//
//  myDefs.m
//  VideoTree
//
//  Created by Steve Kochan on 1/5/11.
//  Copyright © 2010-2011 by Digital Film Tree. All rights reserved.
//

#import "MyDefs.h"

#undef NSLog

// Custom sleep function that allows us to add a slight delay in the 
// code where needed

void mySleep(unsigned long millisec)
{
    struct timespec req;
    
    time_t sec = (int) (millisec / 1000);
    millisec = millisec % 1000;
    req.tv_sec = sec;
    req.tv_nsec = millisec * 1000000L;
    
    nanosleep (&req, NULL);
}

#ifdef kMakeLogFile

#import <Foundation/Foundation.h>
#import <stdio.h>
#import "VideoTreeAppDelegate.h"
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

#define kLogFile  @"logfile"

static NSString *logFilePath;
static char *cLogFilePath;

NSString *pathToLogFile (void)
{
    if (!logFilePath) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *saveDirectory = [paths objectAtIndex:0];
        logFilePath = [[NSString stringWithFormat: @"%@/%@.%@.txt", saveDirectory, kLogFile, [[UIDevice currentDevice] uniqueIdentifier]] retain];
        cLogFilePath = malloc (strlen([logFilePath UTF8String]));
        strcpy(cLogFilePath, [logFilePath UTF8String]);
    }
    
    return logFilePath;
}

BOOL checkLogFile (void)
{
    NSFileManager *fm = [NSFileManager defaultManager];
    
    if ([fm fileExistsAtPath: pathToLogFile ()])
        return YES;
    else
        return NO;
}

void newLogFile (void)
{
    NSFileManager *fm = [NSFileManager defaultManager];

    [fm createFileAtPath: pathToLogFile () contents: nil attributes: nil];   
}

void removeLogFile (void)
{
    NSFileManager *fm = [NSFileManager defaultManager];

    [fm removeItemAtPath: pathToLogFile () error: NULL];
}

void uploadLogFile (void)
{
    if (!checkLogFile ())
        return;
    
    if (kBonjourMode) {
        // Here's where we can upload the log file using pathToLogFile if desired.
    }
}


void MyNSLog (NSString *fmt, ...)
{
    NSData              *buffer;
    
    // Open the logfile for updating
    
 
#ifdef USECOCOA
    NSFileHandle        *outFile;

    outFile = [NSFileHandle fileHandleForWritingAtPath: pathToLogFile ()];
    
    if (outFile == nil) 
        return;
    
    // Seek to the end of outFile
    
    [outFile seekToEndOfFile];
#else
    FILE *fp;
    
    if (!cLogFilePath)
       (void) pathToLogFile ();
    
    fp = fopen (cLogFilePath, "a");
    
    if (!fp) {
        fprintf (stderr, "Couldn't open log file %s\n", cLogFilePath);
        return;
    }
#endif
    
    va_list args;
    
    va_start(args, fmt);
    NSString *fmt2 = [fmt stringByAppendingString: @"\n"];
    NSString *s = [[NSString alloc] initWithFormat:fmt2 arguments:args];
    va_end(args);
    
    buffer = [s dataUsingEncoding:NSASCIIStringEncoding];
    
#ifdef COCOA
    [outFile writeData: buffer];
    [s release];
    
    // Close the log file
    
    [outFile closeFile];
#else
//  fprintf (stderr, "buffer = %p, length = %i\n", buffer.bytes, buffer.length);
    fwrite (buffer.bytes, (size_t) 1, (size_t) buffer.length, fp); 
    fclose (fp);
#endif
 
    // Do the normal console logging here
    
    va_start (args, fmt);
    NSLogv (fmt, args);
    va_end (args);
}

#ifdef NOTNOW
void mailLogFile (void)
{
    MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
    
    if (! [MFMailComposeViewController canSendMail]) {
        NSLog (@"*** Can't send email from this device");
        return;
    }
    
	picker.mailComposeDelegate = (id <MFMailComposeViewControllerDelegate>) [[UIApplication sharedApplication] delegate];
	
	[picker setSubject: [NSString stringWithFormat: @"log notes from %@",
                         [[UIDevice currentDevice] uniqueIdentifier]]];
    
	// Set up recipients
    
	NSArray *toRecipients = [NSArray arrayWithObject:@"steve_kochan@mac.com"]; 
	NSArray *ccRecipients = [NSArray array];
	NSArray *bccRecipients = [NSArray array];
	
	[picker setToRecipients:toRecipients];
	[picker setCcRecipients:ccRecipients];	
	[picker setBccRecipients:bccRecipients];
	
	// Attach the Log file to the email
    
    NSString *newFilePath = pathTologFile (); 
    NSData *myData = [[NSData alloc] initWithContentsOfFile: newFilePath];
	[picker addAttachmentData:myData mimeType:@"application/txt" fileName: kLogFile];
    
	// Fill out the email body text
    
	NSString *emailBody = [NSString stringWithFormat: @"Sent from VideoTree (v%@.%@), \u00A9 2010-2011 by DFT Software", 
                           [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],  [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]];
	[picker setMessageBody:emailBody isHTML:NO];
	
    [picker release];
    [myData release];
}
#endif


#endif


