    //
//  FullScreen.m
//  VideoTree
//
//  Created by Steve Kochan on 9/22/10.
//  Copyright © 2010-2011 DFT Software. All rights reserved.
//

#if 0
#import "FullScreen.h"
#import "VideoTreeViewController.h"

@implementation FullScreen

@synthesize playerView;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight;
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    VideoTreeViewController *vc = [(VideoTreeAppDelegate *)[[UIApplication sharedApplication] delegate] viewController];

    NSLog (@"touches began");
    [vc leaveFullScreen];
}

-(void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
}

-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)dealloc {
    [playerView release];
    [super dealloc];
}


@end
#endif
