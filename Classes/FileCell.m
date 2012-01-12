//
//  FileCell.m
//  Scribbeo
//
//  Created by keyvan on 11/18/11.
//  Copyright (c) 2011 DFT. All rights reserved.
//

#import "FileCell.h"

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
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (UILabel*)timeLabel
{

    if (!timeLabel) {
        timeLabel = [[UILabel alloc] init];
        timeLabel.frame = CGRectMake(60, 0, 100, 20);
//        CGRectMake(<#CGFloat x#>, <#CGFloat y#>, <#CGFloat width#>, <#CGFloat height#>)
        timeLabel.textColor = [UIColor whiteColor];
        timeLabel.shadowColor = [UIColor blackColor];
        timeLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
        timeLabel.textAlignment = UITextAlignmentLeft;
        
        [self addSubview:timeLabel];
    }
    
    return timeLabel;
    
}

- (UILabel*)dateLabel
{
    
    if (!dateLabel) {
        dateLabel = [[UILabel alloc] init];
        dateLabel.frame = CGRectMake(0, 0, 120, 20);
        dateLabel.textColor = [UIColor whiteColor];
        dateLabel.shadowColor = [UIColor blackColor];
        dateLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
        dateLabel.textAlignment = UITextAlignmentLeft;
        
        [self addSubview:dateLabel];
    }
    
    return dateLabel;
    
}

- (UILabel*)initialsLabel
{
    
    if (!initialsLabel) {
        initialsLabel = [[UILabel alloc] init];
        initialsLabel.frame = CGRectMake(0, 110, 60, 20);
        initialsLabel.textColor = [UIColor whiteColor];
        initialsLabel.shadowColor = [UIColor blackColor];
        initialsLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
        initialsLabel.textAlignment = UITextAlignmentLeft;
        
        [self addSubview:initialsLabel];
    }
    
    return initialsLabel;
    
}

- (UILabel*)commentLabel
{
    
    if (!commentLabel) {
        commentLabel = [[UILabel alloc] init];
        commentLabel.frame = CGRectMake(60, 110, 210, 20);
        commentLabel.textColor = [UIColor whiteColor];
        commentLabel.shadowColor = [UIColor blackColor];
        commentLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
        commentLabel.textAlignment = UITextAlignmentLeft;
        
        [self addSubview:commentLabel];
    }
    
    return initialsLabel;
    
}

- (void)layoutSubviews
{
    return;
    [super layoutSubviews];
    
    CGRect timeLabelRect = timeLabel.frame;
    timeLabelRect.origin.y = self.frame.size.height - 20;
    timeLabelRect.size.width = self.frame.size.width;
    self.timeLabel.frame = timeLabelRect;
    
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        
        CGRect dateLabelRect = dateLabel.frame;
        dateLabelRect.size.width = self.frame.size.width/2;
        self.dateLabel.frame = dateLabelRect;
        
        CGRect initialsLabelRect = initialsLabel.frame;
        initialsLabelRect.size.width = self.frame.size.width/2;
        self.initialsLabel.frame = initialsLabelRect;
        
    }
    else
    {
        
        CGRect dateLabelRect = dateLabel.frame;
        dateLabelRect.size.width = 0;
        self.dateLabel.frame = dateLabelRect;
        
        CGRect initialsLabelRect = initialsLabel.frame;
        initialsLabelRect.size.width = self.frame.size.width;
        initialsLabelRect.origin.x = 0;
        self.initialsLabel.frame = initialsLabelRect;
        
    }    
    
    
    
}

@end
