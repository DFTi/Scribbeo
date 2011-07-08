//
//  XMLURL.h
//  Movies
//
//  Created by Stephen Kochan on 6/16/10.
//  Copyright (c) 2011 by Digital Film Tree. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MyDefs.h"


@interface XMLURL : NSObject <NSXMLParserDelegate> {
	NSXMLParser				*rssParser;
	NSMutableArray			*markers;
	SEL						endMethod;
	id						endObject;
	
	// A temporary item; added to the array one at a time, and cleared for the next one
	NSMutableDictionary		*item;
	
	// Parse through the document, from top to bottom...
	// We collect and cache each sub-element value, and then save each item to our array.
	// We use these to track each current item, until it's ready to be added to the "stories" array
	NSString				*currentElement;
	NSMutableString			*currentName, *currentComment, *currentTimecode;
}

- (void)parseXMLURL: (NSString *)URL atEndDoSelector: (SEL) theMethod withObject: (id) theObject;

@end
