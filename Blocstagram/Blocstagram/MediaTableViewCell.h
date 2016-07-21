//
//  MediaTableViewCell.h
//  Blocstagram
//
//  Created by Luke Paulo on 7/2/16.
//  Copyright © 2016 Bloc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Media, MediaTableViewCell;

@protocol MediaTableViewCellDelegate <NSObject>

- (void) cell:(MediaTableViewCell *)cell didTapImageView:(UIImageView *)imageView;
- (void) cell:(MediaTableViewCell *)cell didLongPressImageView:(UIImageView *)imageView;

@end

@interface MediaTableViewCell : UITableViewCell

@property (nonatomic, strong) Media *mediaItem;
@property (nonatomic, weak) id <MediaTableViewCellDelegate> delegate;

//the + signifies that this method does not belong to an instance of that object, it belongs to that clas. It's kind of like static variables we declared earlier which belong to all instances except we've declared it in the header so that any other class may use it. Invoke it like so ---- [MediaTableViewCell heightForMediaItem:someItem width:320];
+ (CGFloat) heightForMediaItem:(Media *)mediaItem width:(CGFloat)width;

@end
