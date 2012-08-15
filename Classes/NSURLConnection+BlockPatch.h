//
//  NSURLConnection+BlockPatch.h
//  SBServerLogin
//
//  Created by Zachry Thayer on 4/23/12.
//  Copyright (c) 2012 Zachry Thayer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURLConnection (BlockPatch)


//+ (void)patch_sendAsynchronousRequest:(NSURLRequest *)request queue:(NSOperationQueue *)queue completionHandler:(void (^)(NSURLResponse*, NSData*, NSError*))handler;

@end
