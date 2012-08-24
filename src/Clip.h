//
//  Clip.h
//  VideoTree
//
//  Created by Steve Kochan on 10/11/10.
//  Copyright © 2010-2011 DFT Software. All rights reserved.
//

// NOTE: This class is currently not being used

#import <Foundation/Foundation.h>


@interface Clip : NSObject {
    NSString *path;
    NSString *show;
    NSString *episode;
    NSString *date;
    NSString *tape;
    NSString *file;
}

@property (nonatomic, copy) NSString *path;
@property (nonatomic, copy) NSString *show;
@property (nonatomic, copy) NSString *episode;
@property (nonatomic, copy) NSString *date;
@property (nonatomic, copy) NSString *tape;
@property (nonatomic, copy) NSString *file;


@end
