//
//  CameraView.m
//  WordSearchCheater
//
//  Created by Nathan Swenson on 12/5/13.
//  Copyright (c) 2013 Nathan Swenson. All rights reserved.
//

#import "CameraView.h"

@implementation CameraView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.previewView = [[UIImageView alloc] initWithFrame:self.bounds];
        [self addSubview:self.previewView];
        self.previewView.backgroundColor = [UIColor purpleColor];
        self.backgroundColor = [UIColor greenColor];
    }
    return self;
}

- (void) layoutSubviews {
    self.previewView.frame = self.bounds;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
