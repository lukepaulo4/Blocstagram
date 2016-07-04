//
//  DataSource.h
//  Blocstagram
//
//  Created by Luke Paulo on 7/2/16.
//  Copyright © 2016 Bloc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Media;

@interface DataSource : NSObject

+(instancetype) sharedInstance;
@property (nonatomic, strong, readonly) NSArray *mediaItems;
//added this property to store our array of mediaItems... It's read only so other classes can't modify it. We redine the property without read only in the impolementation file.

//Add this method (and the @class Media;) to DataSource to let other classes delete a media item.
- (void) deleteMediaItem:(Media *)item;

@end


//To access this bitch, call [DataSource sharedInstance]     Simple as that