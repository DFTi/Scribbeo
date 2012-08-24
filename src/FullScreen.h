//
//  FullScreen.h
//  VideoTree
//
//  Created by Steve Kochan on 9/22/10.
//  Copyright © 2010-2011 DFT Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MyPlayerLayerView.h"


@interface FullScreen : UIViewController {
    MyPlayerLayerView  *playerView;
}

@property (nonatomic, retain) IBOutlet MyPlayerLayerView  *playerView;

@end
