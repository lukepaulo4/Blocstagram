//
//  UIImage+ImageUtilities.h
//  Blocstagram
//
//  Created by Luke Paulo on 7/28/16.
//  Copyright © 2016 Bloc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (ImageUtilities)

- (UIImage *) imageWithFixedOrientation;
- (UIImage *) imageResizedToMatchAspectRatioOfSize:(CGSize)size;
- (UIImage *) imageCroppedToRect:(CGRect)cropRect;
- (UIImage *) imageScaleToSize:(CGSize)size andCroppingWithRect:(CGRect)rect;

@end
