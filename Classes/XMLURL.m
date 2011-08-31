//
//  XMLURL.m
//
//  Created by Stephen Kochan on 6/16/11.
//  Copyright (c) 2011 by Digital Film Tree. All rights reserved.
//

#import "XMLURL.h"

@implementation XMLURL

// This is the only externally-facing method that is called.  All others are
// for external support

- (void)parseXMLURL: (NSString *)URL atEndDoSelector: (SEL) theMethod withObject: (id) theObject
{	
	endMethod = theMethod;   // We call this method when we're done parsing the XML file
	endObject = theObject;   // This is the object whose class contains "endMethod"
	
	markers = [[NSMutableArray alloc] init];
    
	NSLog2 (@"Trying to parse XML stored at %@", URL);
    
    // You must then convert the path to a proper NSURL or it won't work
    
    NSURL *xmlURL = [NSURL URLWithString: URL];
    
    // Should probably send this off to GCD to handle...not used much, so not a big deal
	
 	[self performSelectorInBackground: @selector(doParse:) withObject: xmlURL]; 
}

-(void) doParse: (NSURL *)xmlURL
{
	NSAutoreleasePool *localPool = [[NSAutoreleasePool alloc] init];
	rssParser = [[NSXMLParser alloc] initWithContentsOfURL:xmlURL];
	
    // Set self as the delegate of the parser so that it will 
    // receive the parser delegate methods callbacks.
    
    rssParser.delegate = self;
	
    // Depending on the XML document you're parsing,
    // you may want to enable these features of NSXMLParser.
    
    [rssParser setShouldProcessNamespaces: NO];
    [rssParser setShouldReportNamespacePrefixes: NO];
    [rssParser setShouldResolveExternalEntities: NO];	
	
	[rssParser parse];
	[localPool drain];
}

// Hopefully we don't get this method called (called on error)

- (void)parser: (NSXMLParser *)parser parseErrorOccurred: (NSError *)parseError {
	NSString * errorString = [NSString 
                stringWithFormat:@"Unable to read XML file from server (Error code %i )", 
                        [parseError code]];
    
	NSLog(@"error parsing XML: %@", errorString);
	
//	UIAlertView * errorAlert = [[UIAlertView alloc] initWithTitle:@"Error loading content" message:errorString delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
//	[errorAlert show];
//	[errorAlert release];
}

// Started parsing a new element.  If it's a marker, let's do it!

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict{			
 
    NSLog2(@"found this element: %@", elementName);
	currentElement = [elementName copy];

	if ([elementName isEqualToString:@"marker"]) {
		// clear out our caches...
        // Note: these will be nil the first time through, but we know that's ok!
		
		[item release];
		[currentName release];
		[currentComment release];
		[currentTimecode release];
		
		item = [[NSMutableDictionary alloc] init];
		currentName = [[NSMutableString alloc] init];
		currentComment = [[NSMutableString alloc] init];
		currentTimecode = [[NSMutableString alloc] init];
	}
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName{     
    NSLog2 (@"ended element: %@", elementName);
	if ([elementName isEqualToString:@"marker"]) {
		// save values to an item, then store that item into the array...
        
		[item setObject:currentName forKey:@"name"];
		[item setObject:currentComment forKey:@"comment"];
		[item setObject:currentTimecode forKey:@"in"];
		
		[markers addObject: item];

		NSLog (@"adding marker: %@", currentName);
	}
}

// This is called as characters are read.  We append them to the appropriate string
// based on the currentElement we're processing (which should be a marker)

- (void)parser:(NSXMLParser *)parser foundCharacters: (NSString *) string {
	if ([currentElement isEqualToString:@"name"]) {
		[currentName appendString:string];
	} else if ([currentElement isEqualToString:@"comment"]) {
		[currentComment appendString:string];
	} else if ([currentElement isEqualToString:@"in"]) {
		[currentTimecode appendString:string];
	} 	
}

// We're done parsing the XML file.  Call the "endMethod" 
// and pass it the markers array as argument to the method

- (void)parserDidEndDocument:(NSXMLParser *)parser {
	NSLog2 (@"all done!");
	NSLog(@"markers array has %d items", [markers count]);
	[endObject performSelector: endMethod withObject: markers];
}

-(void) dealloc {
	[currentElement release];
	[item release];
	[currentName release];
	[currentComment release];
	[currentTimecode release];
	[rssParser release];
	[markers release];
	[super dealloc];
}
@end
