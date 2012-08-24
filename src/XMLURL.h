//
//  XMLURL.h
//
//  Created by Stephen Kochan on 6/16/11.
//  Copyright (c) 2011 by Digital Film Tree. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MyDefs.h"

// This class is for parsing an XML stream given an NSString path
// that points to the file. In particular, this class is used
// for importing FCP markers.

// The class is customzied  to look for markers that contain
// "name", "comment," and "in" (timecode) elements


@interface XMLURL : NSObject <NSXMLParserDelegate> {
	NSXMLParser				*rssParser;
	NSMutableArray			*markers;
	SEL						endMethod;
	id						endObject;
	
	// A temporary item; added to the array one at a time, and cleared for the next one
    
	NSMutableDictionary		*item;
	
	// Parse through the document, from top to bottom...
	// We collect and cache each sub-element, and then save each item (which is a dictionary) to our array.
	// We use these to track each current item, until it's ready to be added to the "markers" array
    
	NSString				*currentElement;
	NSMutableString			*currentName, *currentComment, *currentTimecode;
}

-(void)parseXMLURL: (NSString *)URL atEndDoSelector: (SEL) theMethod withObject: (id) theObject;

@end
