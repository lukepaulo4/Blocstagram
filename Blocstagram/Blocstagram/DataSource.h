//
//  DataSource.h
//  Blocstagram
//
//  Created by Luke Paulo on 7/2/16.
//  Copyright © 2016 Bloc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Media;

//Completion handlers are custom blocks. We will pass these blocks as method parameters. For example, getLatestImagesWithCompletionBlock: would accept a block and DataSource will execute that block once the images have been received. Meant for asynchronous operations, like downloading something from the internet, waiting on a user response. Long-running operations are usually good candidates for a completion heandler. Now add a new completion handler definition to our data source header. (typedef allows us to state that all instances of this actually refer to that. We can reuse the parameter in multiple methods.)
typedef void (^NewItemCompletionBlock)(NSError *error);
//The (NSError *error) lists any parameters passed to the block. These parameters can be of any type or length, just like a method. We chose an NSError object as our parameter. This is a typical pattern followed by completion handlers.


@interface DataSource : NSObject

+(instancetype) sharedInstance;

@property (nonatomic, strong, readonly) NSArray *mediaItems;
//added this property to store our array of mediaItems... It's read only so other classes can't modify it. We redine the property without read only in the impolementation file.

@property (nonatomic, strong, readonly) NSString *accessToken;

//Add this method (and the @class Media;) to DataSource to let other classes delete a media item.
- (void) deleteMediaItem:(Media *)item;

- (void) requestNewItemsWithCompletionHandler:(NewItemCompletionBlock)completionHandler;
- (void) requestOldItemsWithCompletionHandler:(NewItemCompletionBlock)completionHandler;

//we want other classes to be able to request that images be downloaded, so add downloadImageForMediaItem to public interface
- (void) downloadImageForMediaItem:(Media *)mediaItem;

//This method tells Instagram about the change, update teh Media object, and call completionHandler when it's finished.
- (void) toggleLikeOnMediaItem:(Media *)mediaItem withCompletionHandler:(void (^)(void))completionHandler;
- (void) commentOnMediaItem:(Media *)mediaItem withCommentText:(NSString *)commentText;

+ (NSString *) instagramClientID;

@end


//To access this bitch, call [DataSource sharedInstance]     Simple as that