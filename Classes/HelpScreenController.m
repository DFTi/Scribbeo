//
//  HelpScreenController.m
//  VideoTree
//
//  Created by Steve Kochan on 7/6/11.
//  Copyright 2011 DFT Software. All rights reserved.
//

#import "HelpScreenController.h"
#import "VideoTreeAppDelegate.h"
#import "myDefs.h"

@implementation HelpScreenController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

// A touch anywhere on the help screen dismisses it

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
     
    [[kAppDel viewController] dismissModalViewControllerAnimated: YES];  
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
 
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
}

- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    
}


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

// We only support landscape orientation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return (interfaceOrientation == UIDeviceOrientationLandscapeRight ||
         interfaceOrientation == UIDeviceOrientationLandscapeLeft);
}

// We have a "More" button on the Help screen that sends the user to the website

- (IBAction) moreHelp {
    [[kAppDel viewController] dismissModalViewControllerAnimated: YES];  

    NSString *helpURL = kVideoTreeWebsite; 
    
    [[UIApplication sharedApplication] openURL: [NSURL URLWithString: helpURL]];
}

- (void)dealloc
{
    [super dealloc];
}

@end
