//
//  VideoTreeAlert.h
//  VideoTree
//
//  Created by Steve Kochan on 5/31/11.
//  Copyright 2011 DFT Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIAlertView (VideoTreeAlert)
+(void) doAlert: (NSString *) title withMsg: (NSString *) msg;
    
@end
