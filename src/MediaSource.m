//
//  MediaSource.m
//  Scribbeo
//
//  Created by Keyvan Fatehi on 8/27/12.
//  Copyright (c) 2012 DFT. All rights reserved.
//

#import "MediaSource.h"
#import "VideoTreeAppDelegate.h"

@implementation MediaSource

@synthesize BonjourMode, UseManualServerDetails, LiveTranscode;
@synthesize HTTPserver, serverBase, serverBrowser, server, bonjour;

-(MediaSource*)init
{
    NSLog(@"Scribbeo, meet OOP. OOP, Scribbeo");
    return self;
}

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
//        [rootTvc showActivity];
//        [rootTvc showDisconnected]; // show the disconnected indicator
        return;
    }
    // else...
    self.server = [serverBrowser.servers objectAtIndex: 0];
    NSLog (@"Connecting to Scribbeo server");
    
    if (bonjour)
        self.bonjour = nil;
    
    bonjour = [[BonjourConnection alloc] initWithNetService: server];

    
    // If it is animating, it is likely we are coming back from a disconnect.
//    if ( [[rootTvc activityIndicator] isAnimating]) {
//        HTTPserver = nil; // Clear our http server, the ip and port may change.
//        [self addObserver: self forKeyPath: @"HTTPserver" options: NSKeyValueObservingOptionNew context: nil];
//        if (! [bonjour connect])  // ~connect updates the HTTPserver address
//            NSLog (@"Couldn't reconnect to Scribbeo server");
//    }
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

- (void) useSettings: (NSUserDefaults *) settings {
    NSLog(@"MediaSource is using new settings.");
    // Live Transcode
    LiveTranscode = [settings boolForKey: @"LiveTranscode"];
    if (!LiveTranscode) LiveTranscode = NO;

    // Network Support
    BonjourMode = [settings boolForKey: @"Bonjour"];
    
    UseManualServerDetails = ![settings boolForKey:@"AutoDiscover"];

    if (!UseManualServerDetails) UseManualServerDetails = NO;
    
    if (!BonjourMode) BonjourMode = NO;
    
    if (BonjourMode) {
        NSLog(@"Running in Networked Mode");
        if (UseManualServerDetails) {
            [self setHTTPserver:nil];
            NSString *manualIP = [settings stringForKey:@"ServerIP"];
            NSString *manualPort = [settings stringForKey:@"ServerPort"];            
            NSString *manualServer = [NSString stringWithFormat:@"https://%@:%@", manualIP, manualPort];
            NSLog(@"Manual override requested, will not do bonjour discovery.");
            NSLog(@"Checking for valid Scribbeo server: %@", manualServer);
            NSError *error = nil;
            NSURLResponse *response;
            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:manualServer] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:3];
            NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
            if (error != nil) {
                NSLog(@"%@", error.localizedDescription);
                [UIAlertView doAlert:  @"Connection Error" 
                         withMsg:@"Cannot find a Scribbeo Server at the specified URL. Please enter a valid IP and Port, otherwise enable Auto Discovery."];
                NSLog(@"Failed to connect to manually entered server %@", manualServer);
            } else {
                NSLog(@"Got back this much data: %d", [data length]);   
                [self setHTTPserver:manualServer];
            }
        } else {
            [self setHTTPserver:nil];
            // maybe put an observer now? :/
            NSLog(@"No manual override, will now discover bonjour servers.");
            NSLog(@"HTTP server: %@", HTTPserver);
            [self doBonjour];
        }
    } else
        NSLog (@"Running in iTunes Document sharing mode");
}

@end