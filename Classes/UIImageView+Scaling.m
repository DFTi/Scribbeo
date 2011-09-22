//
//  UIImageView+Scaling.m
//  VideoTree
//
//  Created by Stephen Kochan on 9/7/11.
//  Copyright 2011 DFT Software. All rights reserved.
//

#import "UIImageView+Scaling.h"


@implementation UIImageView (Scaling) // extensions to UIImageView

// scale the view to fill the given bounds without distorting

- (void)expandToFill:(CGRect)bounds
{
    UIImage *image = self.image; // get the image of this view
    CGRect frame = self.frame; // get the frame of this view
    
    // check if the image is bound by its height
    if (image.size.height / image.size.width >
        bounds.size.height / bounds.size.width)
    {
        // expand the new height to fill the entire view
        frame.size.height = bounds.size.height;
        
        // calculate the new width so the image isn't distorted
        frame.size.width = image.size.width * bounds.size.height /
        image.size.height;
        
        // add to the x and y coordinates so the view remains centered
        frame.origin.y -= (self.frame.size.height - frame.size.height) / 2;
        frame.origin.x += (self.frame.size.width - frame.size.width) / 2;
    } // end if
    else // the image is bound by its width
    {
        // expand the new width to fill the entire view
        frame.size.width = bounds.size.width;
        
        // calculate the new height so the image isn't distorted
        frame.size.height = image.size.height * bounds.size.width /
        image.size.width;
        
        // add to the x and y coordinates so the view remains centered
        frame.origin.y -= (self.frame.size.height - frame.size.height) / 2;
        frame.origin.x += (self.frame.size.width - frame.size.width) / 2;
    } // end else
    
    self.frame = frame; // assign the new frame
} 

@end
