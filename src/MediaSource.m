//
//  MediaSource.m
//  Scribbeo
//
//  Created by Keyvan Fatehi on 8/27/12.
//  Copyright (c) 2012 DFT. All rights reserved.
//

#import "MediaSource.h"
#import "VideoTreeAppDelegate.h"
#import "DetailViewController.h"

@implementation MediaSource

@synthesize BonjourMode, UseManualServerDetails, LiveTranscode;
@synthesize HTTPserver, serverBase, serverBrowser, server, bonjour;


- (NSDictionary*)assets
{
    NSMutableArray *assetArray;
    return [NSArray arrayWithArray:assetArray];
}

// Part of Bonjour server support; connect to a discovered Scribbeo server
- (void)updateServerList
{
    NSLog(@"updateServerList called");
    
    if (serverBrowser.servers.count == 0) {
        NSLog (@"Scribbeo Server disconnected!");
        [[kAppDel rootTvc] showActivity];
        [[kAppDel rootTvc] showDisconnected]; // show the disconnected indicator
        return;
    }
    // else...
    self.server = [serverBrowser.servers objectAtIndex: 0];
    NSLog (@"Connecting to Scribbeo server");
    
    if (bonjour)
        self.bonjour = nil;
    
    bonjour = [[BonjourConnection alloc] initWithNetService: server];

    
    // If it is animating, it is likely we are coming back from a disconnect.
    if ( [[[kAppDel rootTvc] activityIndicator] isAnimating]) {
        if (! [bonjour connect])  // ~connect updates the HTTPserver address
            NSLog (@"Couldn't reconnect to Scribbeo server");
    }
}

// Start looking for Bonjour services
-(void) doBonjour
{
    NSLog (@"doBonjour");
    
    if (! BonjourMode )
        return;
        
    // restart server browser if already running
    
    if (serverBrowser) 
        [serverBrowser stop];
    else {
        self.serverBrowser = [[[ServerBrowser alloc] init] autorelease];
        serverBrowser.delegate = self;
    }

    [serverBrowser start];
    
    [self addObserver: self forKeyPath: @"HTTPserver" options: NSKeyValueObservingOptionNew context: nil];
    
    NSLog (@"**** UDID is %@", [[UIDevice currentDevice] uniqueIdentifier]);
}

// When we receive the IP address from the Bonjour server, it will be stored
// in the HTTPServer variable.  We're observing that variable so we are alerted
// when it changes

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSLog (@"Observe value change for HTTPserver: %@", HTTPserver);
    
    if ([[change objectForKey: NSKeyValueChangeKindKey] integerValue] !=  NSKeyValueChangeSetting) {
//        NSLog (@"Key value did not change: %i", [change objectForKey: NSKeyValueChangeKindKey]);
        return;
    }
    
    if (! HTTPserver)
        return;
    
    [self removeObserver: self forKeyPath: @"HTTPserver"];

    [kAppDel makeList];
}

- (void) connectWithSettings: (NSUserDefaults *) settings {
    NSLog(@"MediaSource will use new settings.");
    [self loadSettings:settings];
    if (BonjourMode) {
        NSLog(@"Networking is ENABLED");
        if (UseManualServerDetails) {
            [self setHTTPserver:nil];
            NSString *manualIP = [settings stringForKey:@"ServerIP"];
            NSString *manualPort = [settings stringForKey:@"ServerPort"];
            NSString *scheme = [NSString stringWithString:(useSSL ? @"https" : @"http")];
            HTTPserver = [NSString stringWithFormat:@"%@://%@:%@",
                          scheme, manualIP, manualPort];
            [self makeManualServerConnection];
        } else {
            [self makeBonjourConnection];
        }
    } else // "local mode"
        NSLog(@"Networking is DISABLED, running in iTunes Document sharing mode");
    
    if (UseManualServerDetails) {
    
    } else {
        
    }
}

- (void) makeManualServerConnection {
    // could be python or caps server
    // we'll figure out if we're having an SSL problem
    NSLog(@"Manual override requested, will not do bonjour discovery.");
    NSLog(@"Checking for valid Scribbeo server: %@", HTTPserver);
    NSError *error = nil;
    NSURLResponse *response;
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:HTTPserver] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:3];
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if (error != nil) {
        NSLog(@"%@", error.localizedDescription);
        [UIAlertView doAlert:  @"Connection Error"
                     withMsg:@"Cannot find a Scribbeo Server at the specified URL. Please enter a valid IP and Port, otherwise enable Auto Discovery."];
        NSLog(@"Failed to connect to manually entered server %@", HTTPserver);
    } else {
        NSLog(@"Got back this much data: %d", [data length]);
    }
}

- (void) makeBonjourConnection {
    [self setHTTPserver:nil];
    NSLog(@"Will now discover bonjour servers.");
    NSLog(@"HTTP server: %@", HTTPserver);
    [self doBonjour];
}

//private

-(void) loadSettings:(NSUserDefaults *)settings {
    useSSL = NO;
    useCAPS = NO;
    LiveTranscode = [settings boolForKey: @"LiveTranscode"];
    BonjourMode = [settings boolForKey: @"Bonjour"];
    UseManualServerDetails = ![settings boolForKey:@"AutoDiscover"];
    // default value is not working I guess? good insurance anyway...
    if (!LiveTranscode) LiveTranscode = NO;
    if (!UseManualServerDetails) UseManualServerDetails = NO;
    if (!BonjourMode) BonjourMode = NO;
}

@end