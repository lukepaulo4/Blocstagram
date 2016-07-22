//
//  Media.h
//  Blocstagram
//
//  Created by Luke Paulo on 7/2/16.
//  Copyright © 2016 Bloc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"

//Track which media items have been downloaded, and which still need to be downloaded. Start by declaring an enumeration in Media.h.  typedef NS_ENUM delcares MediaDownloadState as equivalent to NSInteger, with four predefined values. Now MediaDownloadState can theoretically be used anywhere as NSInteger
typedef NS_ENUM(NSInteger, MediaDownloadState) {
    MediaDownloadStateNeedsImage            = 0,
    MediaDownloadStateDownloadInProgress    = 1,
    MediaDownloadStateNonRecoverableError   = 2,
    MediaDownloadStateHasImage              = 3
};


//We use the @class User instead of just adding #import User.h because it is poor practice to import custom classes inside a header file. It causes an error called circular inclusion. BUT THEN THEY SAY FUCK IT AND WE ADDED IT ABOVE ANYWAYS???????
@class User;

@interface Media : NSObject <NSCoding>

@property (nonatomic, strong) NSString *idNumber;
@property (nonatomic, strong) User *user;
@property (nonatomic, strong) NSURL *mediaURL;
@property (nonatomic, strong) UIImage *image;

//Use assign not strong becasue MediaDownloadState (aka NSInteger) is a simple type, not an object.
@property (nonatomic, assign) MediaDownloadState downloadState;

@property (nonatomic, strong) NSString *caption;
@property (nonatomic, strong) NSArray *comments;

- (instancetype) initWithDictionary:(NSDictionary *)mediaDictionary;

@end
