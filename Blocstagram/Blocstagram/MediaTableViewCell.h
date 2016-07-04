//
//  MediaTableViewCell.h
//  Blocstagram
//
//  Created by Luke Paulo on 7/2/16.
//  Copyright © 2016 Bloc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Media;

@interface MediaTableViewCell : UITableViewCell

@property (nonatomic, strong) Media *mediaItem;

//the + signifies that this method does not belong to an instance of that object, it belongs to that class. It's kind of like static variables we declared earlier which belong to all instances except we've declared it in the header so that any other class may use it. Invoke it like so ---- [MediaTableViewCell heightForMediaItem:someItem width:320];
+ (CGFloat) heightForMediaItem:(Media *)mediaItem width:(CGFloat)width;


@end
