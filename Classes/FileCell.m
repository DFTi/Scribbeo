//
//  FileCell.m
//  Scribbeo
//
//  Created by keyvan on 11/18/11.
//  Copyright (c) 2011 DFT. All rights reserved.
//

#import "FileCell.h"

@implementation FileCell

@synthesize timeLabel;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        

    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (UILabel*)timeLabel
{

    if (!timeLabel) {
        timeLabel = [[UILabel alloc] init];
        timeLabel.frame = CGRectMake(0, 110, 210, 20);
        timeLabel.textColor = [UIColor whiteColor];
        timeLabel.shadowColor = [UIColor blackColor];
        timeLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
        timeLabel.textAlignment = UITextAlignmentCenter;
        
        [self addSubview:timeLabel];
    }
    
    return timeLabel;
    
}

@end
