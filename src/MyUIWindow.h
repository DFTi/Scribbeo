//
//  MyUIWindow.h
//  VideoTree
//
//  Created by Steve Kochan on 6/20/11.
//  Copyright 2011 DFT Software. All rights reserved.
//

// This class handles the yellow spot that is displayed 
// whenever the screen is touched (for demos).
// This subclass replaces the UIWindow as the main window
//

#import <Foundation/Foundation.h>


@interface MyUIWindow : UIWindow {
    UIImageView  *spotView;
}

@property (nonatomic, retain) UIImageView  *spotView;

@end
