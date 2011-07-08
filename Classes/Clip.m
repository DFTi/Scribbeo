//
//  Clip.m
//  VideoTree
//
//  Created by Steve Kochan on 10/11/10.
//  Copyright © 2010-2011 DFT Software. All rights reserved.
//

#import "Clip.h"


@implementation Clip
@synthesize     path, show, episode, date, tape, file;

-(NSString *) description 
{
    return [NSString stringWithFormat: @"Show: %@ Episode: %@: Date: %@ Tape: %@ File: %@",
            show, episode, date, tape, file];
}

-(void) dealloc
{
    [path release];
    [show release];
    [episode release];
    [date release];
    [tape release];
    [file release];
    [super dealloc];
}
@end
