//
//  MediaTableViewCell.h
//  Blocstagram
//
//  Created by Luke Paulo on 7/2/16.
//  Copyright © 2016 Bloc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Media, MediaTableViewCell, ComposeCommentView;

@protocol MediaTableViewCellDelegate <NSObject>


- (void) cell:(MediaTableViewCell *)cell didTapImageView:(UIImageView *)imageView;
- (void) cell:(MediaTableViewCell *)cell didLongPressImageView:(UIImageView *)imageView;

//Delegate protocol, add a method indicating that the button was pressed
- (void) cellDidPressLikeButton:(MediaTableViewCell *)cell;
- (void) cellWillStartComposingComment:(MediaTableViewCell *)cell;
- (void) cell:(MediaTableViewCell *)cell didComposeComment:(NSString *)comment;

@end

@interface MediaTableViewCell : UITableViewCell

@property (nonatomic, strong) Media *mediaItem;
@property (nonatomic, weak) id <MediaTableViewCellDelegate> delegate;

//add a public readonly property for the comment view and a similar stopComposingComment method
@property (nonatomic, strong, readonly) ComposeCommentView *commentView;

@property (nonatomic, strong) UITraitCollection *overrideTraitCollection;

//the + signifies that this method does not belong to an instance of that object, it belongs to that clas. It's kind of like static variables we declared earlier which belong to all instances except we've declared it in the header so that any other class may use it. Invoke it like so ---- [MediaTableViewCell heightForMediaItem:someItem width:320];
+ (CGFloat) heightForMediaItem:(Media *)mediaItem width:(CGFloat)width traitCollection:(UITraitCollection *) traitCollection;

- (void) stopComposingComment;

@end
