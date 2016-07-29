//
//  CameraToolbar.h
//  Blocstagram
//
//  Created by Luke Paulo on 7/27/16.
//  Copyright © 2016 Bloc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CameraToolbar;

@protocol CameraToolbarDelegate <NSObject>

- (void) leftButtonPressedOnToolbar:(CameraToolbar *)toolbar;
- (void) rightButtonPressedOnToolbar:(CameraToolbar *)toolbar;
- (void) cameraButtonPressedOnToolbar:(CameraToolbar *)toolbar;

@end;

@interface CameraToolbar : UIView

//Some NOTES!!!!  The image names on the icons of the side buttons will be passed to initWithImageNames. The view will know NOTHING about the function of these buttons. Instead, the delegate will be informed when the buttons are pressed.
- (instancetype) initWithImageNames:(NSArray *)imageNames;

@property (nonatomic, weak) NSObject <CameraToolbarDelegate> *delegate;

@end
