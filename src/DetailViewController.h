//
//  DetailViewController.h
//  VideoTree
//
//  Created by Steve Kochan on 9/12/10.
//  Copyright © 2010-2011 by Digital Film Tree. All rights reserved.
//
// This class handles clip selection, including selection of a clip 
// from the camera roll
//

#import <UIKit/UIKit.h>
#import "myDefs.h"
#import "JSONKit.h"

@interface DetailViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource, UIPopoverControllerDelegate, UINavigationControllerDelegate,
    UIImagePickerControllerDelegate> {
    NSString                 *currentPath;           // The current path for the current clip
    NSMutableArray           *files, *fileTypes;     // A list of files are their corresponding type (e.g., directory)
        NSMutableArray           *assetURLs, *timeCodes;              // Used in Bonjour Mode
    UIView                   *progressView;          // A view to hold an activity indicator when the clip table loads
    UIActivityIndicatorView  *activityIndicator;
    
    int                 currentClip;                // current index into the files table 
    NSString            *clip;
    UIPopoverController *popoverController;         // The controller for showing the popover when selecting a local clip
    NSString            *moviePath;                 // Is this an album (all stills?)
    BOOL                allStills;
}

@property (nonatomic, retain) NSString                  *currentPath, *moviePath;
@property (nonatomic, retain) NSMutableArray            *files, *fileTypes, *assetURLs, *timeCodes;
@property (nonatomic, retain) UIView                    *progressView;
@property (nonatomic, retain) UIActivityIndicatorView   *activityIndicator;
@property (nonatomic, retain)  UIPopoverController      *popoverController;
@property int     currentClip;


- (void) showDisconnected;
- (void) hideDisconnected;
- (void) showActivity;
- (void) stopActivity;
- (BOOL) nextClip;
- (void) makeList;
- (void) iTunesLoad;
- (void) setTheMoviePath: (NSString *) movie;
- (void) filesFromJSONFileListing: (NSDictionary *) listing;
- (void) setNotesAndTimecodeForAsset: (NSString *) assetURL atIndex:(NSInteger) index;
- (void)rowSelected:(int)row;
- (void) playAsset: (NSString *)theMedia;
- (void)closeOut:(id)sender;

#ifdef OLDSTUFF
@property (nonatomic, retain)  NSString        *episode, *date, *tape, *clip;

-(NSArray *) shows;
-(NSArray *) episodesForShow: (NSString *) theShow;
-(NSArray *) datesForShow: (NSString *) theShow episode: (NSString *) theEpisode;
-(NSArray *) tapesForShow: (NSString *) theShow episode: (NSString *) theEpisode date: (NSString *) theDate;
-(NSArray *) filesForShow: (NSString *) theShow episode: (NSString *) theEpisode 
                     date: (NSString *) theDate tape: (NSString *) theTape;
-(NSString *) pathForShow: (NSString *) theShow episode: (NSString *) theEpisode 
              date: (NSString *) theDate tape: (NSString *) theTape file: (NSString *) theFile;
#endif
@end
