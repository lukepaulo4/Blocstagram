//
//  LikeButton.h
//  Blocstagram
//
//  Created by Luke Paulo on 7/22/16.
//  Copyright © 2016 Bloc. All rights reserved.
//

#import <UIKit/UIKit.h>

//define 4 possible states that the button might be in, and expose a property for storing this state
typedef NS_ENUM(NSInteger, LikeState) {
    LikeStateNotLiked               = 0,
    LikeStateLiking                 = 1,
    LikeStateLiked                  = 2,
    LikeStateUnliking               = 3
};

@interface LikeButton : UIButton <NSCoding>

//The current state of the like button. Setting to LikeButtonNotLiked or LikeButtonLiked will display an empty heart or a heart, respectively. Setting to LikeButtonLiking or LikeButtonUnliking will display an activity indicator and disable button taps until the button is set to LikeButtonNotLiked or LikeButtonLiked.
@property (nonatomic, assign) LikeState likeButtonState;

@end
