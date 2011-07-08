//
//  Note.h
//  VideoTree
//
//  Created by Steve Kochan on 9/21/10.
//  Copyright © 2010-2011 by Digital Film Tree. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "myDefs.h"

@interface Note : NSObject <NSCoding>{
    NSData     *thumb;
    NSData     *voiceMemo;
    NSString    *text;
    NSString    *timeStamp;
    NSString    *date;
    NSString    *initials;
    NSMutableArray  *drawing;
    NSMutableArray  *colors;
    float       frameWidth, frameHeight;  // for scaling the notes
}

@property (nonatomic, retain)  NSData     *thumb;
@property (nonatomic, retain)  NSData     *voiceMemo;
@property (nonatomic, copy)    NSString    *text;
@property (nonatomic, retain)  NSString    *timeStamp;
@property (nonatomic, retain)  NSString    *date;
@property (nonatomic, retain)  NSString    *initials;
@property (nonatomic, copy)    NSMutableArray  *drawing;
@property (nonatomic, copy)    NSMutableArray  *colors;
@property float frameWidth, frameHeight;

@end
