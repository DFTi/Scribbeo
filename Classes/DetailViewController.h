//
//  DetailViewController.h
//  VideoTree
//
//  Created by Steve Kochan on 9/12/10.
//  Copyright © 2010-2011 by Digital Film Tree. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "myDefs.h"
#import "FTPHelper.h"

@interface DetailViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource, UIPopoverControllerDelegate, UINavigationControllerDelegate,
    UIImagePickerControllerDelegate> {
    NSString            *currentPath;
    NSMutableArray      *files, *fileTypes;
    UIView                  *progressView;
    UIActivityIndicatorView  *activityIndicator;
    
    NSString            *showName;
    NSMutableArray      *clipList;
    int                 levelCount;
    int                 currentClip, clipCount, currentTape;     // for autoplay
    NSString            *episode, *date, *tape, *clip;
    UIBarButtonItem    *cameraRollButton;
    UIPopoverController *popoverController;
    NSString            *moviePath;
    NSTimer             *networkTimer;
}

@property (nonatomic, retain) NSString *currentPath, *moviePath;
@property (nonatomic, retain) NSMutableArray      *files, *fileTypes;
@property (nonatomic, retain) UIView     *progressView;
@property (nonatomic, retain) UIActivityIndicatorView  *activityIndicator;

@property (nonatomic, retain)  NSString            *showName;
@property (nonatomic, retain)  UIPopoverController *popoverController;
@property (nonatomic, retain)  NSMutableArray      *clipList;
@property (nonatomic, retain)  NSString            *episode, *date, *tape, *clip;
@property int   clipCount, currentClip, currentTape;
@property (nonatomic, retain)  NSTimer *networkTimer;
@property int levelCount;

-(BOOL) nextClip;
-(void) makeList;
-(void) iTunesLoad;
-(void) setTheMoviePath: (NSString *) movie;

#ifdef OLDSTUFF
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
