//
//  VideoTreeAlert.h
//  VideoTree
//
//  Created by Steve Kochan on 5/31/11.
//  Copyright 2011 DFT Software. All rights reserved.
//

// A category extension to the UIAlertView class for a customized alert
// Added just to save a little work!
//

#import <UIKit/UIKit.h>

@interface UIAlertView (VideoTreeAlert)
+(void) doAlert: (NSString *) title withMsg: (NSString *) msg;
    
@end
