//
//  LikeButton.m
//  Blocstagram
//
//  Created by Luke Paulo on 7/22/16.
//  Copyright © 2016 Bloc. All rights reserved.
//


//NOTE************  The button is just a view. - it shows what it's told. In order to display accurate information, we'll need to know whether the user has liked an image or not. So go to Media.h!!!!!!

#import "LikeButton.h"
#import "CircleSpinnerView.h"

#define kLikedStateImage @"heart-full"
#define kUnlikedStateImage @"heart-empty"

@interface LikeButton ()

@property (nonatomic, strong) CircleSpinnerView *spinnerView;

@end

@implementation LikeButton

//In the initializer, we'll create the spinner view and set up the button
- (instancetype) init {
    self = [super init];
    
    if (self) {
        self.spinnerView = [[CircleSpinnerView alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
        [self addSubview:self.spinnerView];
        
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        
        //contentEdgeInsets provides a buffer between the edge of the button and the content
        self.contentEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10);
        
        //specifies the alignment of the button's content. By default it's centered, but we want it at the top so that the like button isn't misaligned on photos with longer captions.
        self.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
        
        //set default state to "not liked"
        self.likeButtonState = LikeStateNotLiked;
    }
    
    return self;
}

//The spinner view's frame should be uploaded whenever the button's frame changes
- (void) layoutSubviews {
    [super layoutSubviews];
    self.spinnerView.frame = self.imageView.frame;
}

//Update the button's appearance based on the set state
- (void) setLikeButtonState:(LikeState)likeState {
    _likeButtonState = likeState;
    
    NSString *imageName;
    
    switch (_likeButtonState) {
        case LikeStateLiked:
        case LikeStateUnliking:
            imageName = kLikedStateImage;
            break;
            
        case LikeStateNotLiked:
        case LikeStateLiking:
            imageName = kUnlikedStateImage;
            
    }
    
    switch (_likeButtonState) {
        case LikeStateLiking:
        case LikeStateUnliking:
            self.spinnerView.hidden = NO;
            self.userInteractionEnabled = NO;
            break;
            
        case LikeStateLiked:
        case LikeStateNotLiked:
            self.spinnerView.hidden = YES;
            self.userInteractionEnabled = YES;
    }
    
    [self setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
}

#pragma mark - NSCoding

//Incorporate this with the other Media encode/decode stuff, not its own new one!
//- (instancetype) initWithCoder:(NSCoder *)aDecoder {
//    
//    self = [super init];
//    
//    
//    NSString *likeStateString = [NSString stringWithFormat:@"%ld", (long)likeState];
//    
//    if (self) {
//        self.likeStateString = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(likeButtonState))];
//    }
//    
//    return self;
//}
//
//- (void) encodeWithCoder:(NSCoder *)aCoder {
//    [aCoder encodeObject:self.likeStateString forKey:NSStringFromSelector(@selector(likeButtonState))];
//}

@end


