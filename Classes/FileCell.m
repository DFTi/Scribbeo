//
//  FileCell.m
//  Scribbeo
//
//  Created by keyvan on 11/18/11.
//  Copyright (c) 2011 DFT. All rights reserved.
//

#import "FileCell.h"
#import <QuartzCore/QuartzCore.h>

@implementation FileCell

@synthesize timeLabel, dateLabel, initialsLabel, commentLabel;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        

    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    //[super setSelected:selected animated:animated];
    self.layer.borderColor = [[UIColor yellowColor] CGColor];
    self.layer.borderWidth = (selected)?2.f:0.f;
    // Configure the view for the selected state
}

- (UILabel*)timeLabel
{

    if (!timeLabel) {
        timeLabel = [[UILabel alloc] init];
        timeLabel.frame = CGRectMake(103, 0, 104, 20);
        timeLabel.textColor = [UIColor whiteColor];
        timeLabel.shadowColor = [UIColor blackColor];
        timeLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
        timeLabel.textAlignment = UITextAlignmentCenter;
        
        [self addSubview:timeLabel];
    }
    
    return timeLabel;
    
}

- (UILabel*)dateLabel
{
    
    if (!dateLabel) {
        dateLabel = [[UILabel alloc] init];
        dateLabel.frame = CGRectMake(0, 0, 110, 20);
        dateLabel.textColor = [UIColor whiteColor];
        dateLabel.shadowColor = [UIColor blackColor];
        dateLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
        dateLabel.textAlignment = UITextAlignmentCenter;
        
        [self addSubview:dateLabel];
    }
    
    return dateLabel;
    
}

- (UILabel*)initialsLabel
{
    
    if (!initialsLabel) {
        initialsLabel = [[UILabel alloc] init];
        initialsLabel.frame = CGRectMake(0, 110, 40, 20);
        initialsLabel.textColor = [UIColor whiteColor];
        initialsLabel.shadowColor = [UIColor blackColor];
        initialsLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
        initialsLabel.textAlignment = UITextAlignmentCenter;
        
        [self addSubview:initialsLabel];
    }
    
    return initialsLabel;
    
}

- (UILabel*)commentLabel
{
    
    if (!commentLabel) {
        commentLabel = [[UILabel alloc] init];
        commentLabel.frame = CGRectMake(40, 110, 200, 20);
        commentLabel.textColor = [UIColor whiteColor];
        commentLabel.shadowColor = [UIColor blackColor];
        commentLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
        commentLabel.textAlignment = UITextAlignmentLeft;
        
        [self addSubview:commentLabel];
    }
    
    return commentLabel;
    
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        
        CGRect dateLabelRect = dateLabel.frame;
        dateLabelRect.size.width = self.frame.size.width/2;
        self.dateLabel.frame = dateLabelRect;
        
        //CGRect initialsLabelRect = initialsLabel.frame;
        //initialsLabelRect.size.width = self.frame.size.width/2;
        //self.initialsLabel.frame = initialsLabelRect;
        
    }
    else
    {
        // top
        CGRect timeLabelRect = timeLabel.frame;
        timeLabelRect.origin.x = self.frame.origin.x;
        timeLabelRect.size.width = self.frame.size.width;
        self.timeLabel.frame = timeLabelRect;
        
        
        // bottom
        
        CGRect dateLabelRect = dateLabel.frame;
        dateLabelRect.origin.x = self.frame.origin.x;
        dateLabelRect.origin.y = self.frame.size.height-20;
        dateLabelRect.size.width = self.frame.size.width/2;
        self.dateLabel.frame = dateLabelRect;
        
        CGRect initialsLabelRect = initialsLabel.frame;
        initialsLabelRect.origin.x = dateLabelRect.size.width;
        initialsLabelRect.origin.y = self.frame.size.height-20;
        initialsLabelRect.size.width = self.frame.size.width/2;
        self.initialsLabel.frame = initialsLabelRect;
        
    }    
    
    
    
}

@end
