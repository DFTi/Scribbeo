//
//  XMLURL.m
//  Movies
//
//  Created by Stephen Kochan on 6/16/10.
//  Copyright (c) 2011 by Digital Film Tree. All rights reserved.
//

#import "XMLURL.h"

@implementation XMLURL

- (void)parserDidStartDocument:(NSXMLParser *)parser{	
	NSLog(@"found file and started parsing");
}

- (void)parseXMLURL: (NSString *)URL atEndDoSelector: (SEL) theMethod withObject: (id) theObject
{	
	endMethod = theMethod;
	endObject = theObject;
	
	markers = [[NSMutableArray alloc] init];
	NSLog (@"Trying to parse XML stored at %@", URL);
    
    //you must then convert the path to a proper NSURL or it won't work
    NSURL *xmlURL = [NSURL URLWithString:URL];
	
 	[self performSelectorInBackground:@selector(doParse:) withObject: xmlURL]; 
}

-(void) doParse: (NSURL *)xmlURL
{
	NSAutoreleasePool *localPool = [[NSAutoreleasePool alloc] init];
	rssParser = [[NSXMLParser alloc] initWithContentsOfURL:xmlURL];
	
    // Set self as the delegate of the parser so that it will receive the parser delegate methods callbacks.
    rssParser.delegate = self;
	
    // Depending on the XML document you're parsing, you may want to enable these features of NSXMLParser.
    [rssParser setShouldProcessNamespaces:NO];
    [rssParser setShouldReportNamespacePrefixes:NO];
    [rssParser setShouldResolveExternalEntities: NO];	
	
	[rssParser parse];
	[localPool drain];
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
	NSString * errorString = [NSString stringWithFormat:@"Unable to read XML file from web site (Error code %i )", [parseError code]];
	NSLog(@"error parsing XML: %@", errorString);
	
	UIAlertView * errorAlert = [[UIAlertView alloc] initWithTitle:@"Error loading content" message:errorString delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
//	[errorAlert show];
	[errorAlert release];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict{			
    NSLog2(@"found this element: %@", elementName);
	currentElement = [elementName copy];

	if ([elementName isEqualToString:@"marker"]) {
		// clear out our caches...
		
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

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *) string {
	// NSLog(@"found characters: %@", string);
	// save the characters for the current item...
	if ([currentElement isEqualToString:@"name"]) {
		[currentName appendString:string];
	} else if ([currentElement isEqualToString:@"comment"]) {
		[currentComment appendString:string];
	} else if ([currentElement isEqualToString:@"in"]) {
		[currentTimecode appendString:string];
	} 
	
	// NSLog (@"Current element: %@", currentElement);
	
}

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
