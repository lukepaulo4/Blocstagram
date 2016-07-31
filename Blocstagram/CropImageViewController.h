//
//  CropImageViewController.h
//  Blocstagram
//
//  Created by Luke Paulo on 7/30/16.
//  Copyright © 2016 Bloc. All rights reserved.
//

#import "MediaFullScreenViewController.h"

@class CropImageViewController;

@protocol CropImageViewControllerDelegate <NSObject>

- (void) cropControllerFinishedWithImage:(UIImage *)croppedImage;

@end

@interface CropImageViewController : MediaFullScreenViewController

- (instancetype) initWithImage:(UIImage *)sourceImage;

@property (nonatomic, weak) NSObject <CropImageViewControllerDelegate> *delegate;

@end

//This view controller's interface indicates: 1. Another controller will pass it a UIImage and set itself as the crop controller's delegate. 2. The user will size and crop the image, and the controller will pass a new, cropped UIImage back to its delegate.