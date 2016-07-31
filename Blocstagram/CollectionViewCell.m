//
//  CollectionViewCell.m
//  Blocstagram
//
//  Created by Luke Paulo on 7/31/16.
//  Copyright © 2016 Bloc. All rights reserved.
//

#import "CollectionViewCell.h"

@implementation CollectionViewCell

- (instancetype) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
            self.imageView = [[UIImageView alloc] initWithFrame:frame];
            self.imageView.tag = imageViewTag;
            self.imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
            self.imageView.contentMode = UIViewContentModeScaleAspectFill;
            self.imageView.clipsToBounds = YES;
            [self.contentView addSubview:self.imageView];
        }
    return self;
}

@end
