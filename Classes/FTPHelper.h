

// #define kFTPusername   @"steve"
// #define kFTPpassword   @"gh_67TR_q"
// #define kFTPserver     @"72.37.128.108"

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CFNetwork/CFNetwork.h>
#import "myDefs.h"
#import "VideoTreeAppDelegate.h"
#import "VideoTreeViewController.h"

@protocol FTPHelperDelegate <NSObject>
@optional
// Successes
- (void) receivedListing: (NSDictionary *) listing;
- (void) downloadFinished;
- (void) dataUploadFinished: (NSNumber *) bytes;
- (void) progressAtPercent: (NSNumber *) aPercent;


// Failures
- (void) listingFailed;
- (void) dataDownloadFailed: (NSString *) reason;
- (void) dataUploadFailed: (NSString *) reason;
- (void) credentialsMissing;
@end

@interface FTPHelper : NSObject 
{
	NSString *urlString;
	id <FTPHelperDelegate> delegate;
	BOOL isBusy;
	NSString *uname;
	NSString *pword;
	NSMutableArray *fileListings;
	NSString *filePath;
}
@property (retain) NSString *urlString;
@property (retain) id delegate;
@property (assign) BOOL isBusy;
@property (retain) NSString *uname;
@property (retain) NSString *pword;
@property (retain) NSMutableArray *fileListings;
@property (retain) NSString *filePath; // valid after download

+ (FTPHelper *) sharedInstance;
+ (void) download:(NSString *) anItem to: (NSString *) writepath;
+ (void) upload: (NSString *) anItem;
+ (void) list: (NSString *) aURLString;

+ (NSString *) textForDirectoryListing: (CFDictionaryRef) dictionary;

@end

