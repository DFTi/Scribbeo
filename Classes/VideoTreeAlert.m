//
//  VideoTreeAlert.m
//  VideoTree
//
//  Created by Steve Kochan on 5/31/11.
//  Copyright 2011 DFT Software. All rights reserved.
//

#import "VideoTreeAlert.h"

@implementation UIAlertView (VideoTreeAlert)

+(void) doAlert: (NSString *) title withMsg: (NSString *) msg
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle: title
            message: msg  delegate:self 
            cancelButtonTitle: @"OK"  otherButtonTitles: nil];

    [alert show];
    [alert release];
}
@end
