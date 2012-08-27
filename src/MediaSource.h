//
//  MediaSource.h
//  Scribbeo
//
//  Created by Keyvan Fatehi on 8/27/12.
//  Copyright (c) 2012 DFT. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "myDefs.h"

#import "ServerBrowser.h"
#import "ServerBrowserDelegate.h"
#import "BonjourConnection.h"

@interface MediaSource : NSObject <ServerBrowserDelegate> {
    NSString                *HTTPserver, *serverBase;
    BOOL                    BonjourMode, LiveTranscode, UseManualServerDetails;
    ServerBrowser           *serverBrowser;
    NSNetService            *server;
    BonjourConnection       *bonjour;
}

@property BOOL BonjourMode, UseManualServerDetails, LiveTranscode;
@property (nonatomic, retain)  NSString             *HTTPserver, *serverBase;
@property (nonatomic, retain)  ServerBrowser        *serverBrowser;
@property (nonatomic, retain)  NSNetService         *server;
@property (nonatomic, retain)  BonjourConnection    *bonjour;

-(NSDictionary*) assets;
-(void) doBonjour;
-(void) useSettings: (NSUserDefaults *) settings;
@end