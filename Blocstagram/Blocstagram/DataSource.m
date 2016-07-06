//
//  DataSource.m
//  Blocstagram
//
//  Created by Luke Paulo on 7/2/16.
//  Copyright © 2016 Bloc. All rights reserved.
//

#import "DataSource.h"
#import "User.h"
#import "Media.h"
#import "Comment.h"
#import "LoginViewController.h"

//Added the mutable array because it's a Key-Value Compliant req. An array must be accessible as an instance var name _<key> or by method -<key> which returns a reference to the array.
@interface DataSource () {
    NSMutableArray *_mediaItems;
}

@property (nonatomic, strong) NSString *accessToken;
@property (nonatomic, strong) NSArray *mediaItems;

//Need BOOL property to track whether a refresh is already in progress so not fetching multiple times while waiting for a result from server
@property (nonatomic, assign) BOOL isRefreshing;
@property (nonatomic, assign) BOOL isLoadingOlderItems;

@end

@implementation DataSource

#pragma mark - Key/Value Observing

//Add accessor methods which will allow observers to be notified when the content of the array changes.
- (NSUInteger) countOfMediaItems {  //Required accessor method. Since countOf<key> you capitalize Media
    return self.mediaItems.count;
}

- (id) objectInMediaItemsAtIndex:(NSUInteger)index {
    return [self.mediaItems objectAtIndex:index];
}

- (NSArray *) mediaItemsAtIndexes:(NSIndexSet *)indexes {
    return [self.mediaItems objectsAtIndexes:indexes];
}

//Next let's add mutable accessor methods. These are KVC methods which allow insertion and deletion of elements from mediaItems
- (void) insertObject:(Media *)object inMediaItemsAtIndex:(NSUInteger)index {
    [_mediaItems insertObject:object atIndex:index];
}

- (void) removeObjectFromMediaItemsAtIndex:(NSUInteger)index {
    [_mediaItems removeObjectAtIndex:index];
}

- (void) replaceObjectInMediaItemsAtIndex:(NSUInteger)index withObject:(id)object {
    [_mediaItems replaceObjectAtIndex:index withObject:object];
}
//Note in these three methods above we use the instance variable _mediaItems and not the property self.mediaItems. This is because the header file is declared as readonly, but in the implementation file, _mediaItems is mutable. If we tried tio write these methods using self.mediaItems, Xcode would mark those lines as syntax errors.



+(instancetype) sharedInstance {
    static dispatch_once_t once;     //dispatch_once ensures we only create a single instance of this class
    static id sharedInstance;        //holds our shared instance
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
    
}

-(instancetype) init {
    self = [super init];
    
    if (self) {
        [self registerForAccessTokenNotification];
    }
    
    return self;
}

- (void) populateDataWithParameters:(NSDictionary *) parameters {
    if (self.accessToken) {
        //only try to get the data if there's an access token
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            //do the network request in the background, so the UI doesn't lock up
            
            NSMutableString *urlString = [NSMutableString stringWithFormat:@"https://api.instagram.com/v1/users/self/media/recent?access_token=%@", self.accessToken];
            
            for (NSString *parameterName in parameters) {
                //for ex, if dict contains {count:50}, append '&count=50' to the URL
                [urlString appendFormat:@"&%@=%@", parameterName, parameters[parameterName]];
            }
            
            NSURL *url = [NSURL URLWithString:urlString];
            
            if (url) {
                NSURLRequest *request = [NSURLRequest requestWithURL:url];
                
                NSURLResponse *response;
                NSError *webError;
                NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&webError];
                
                if (responseData) {
                    NSError *jsonError;
                    NSDictionary *feedDictionary = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&jsonError];
                    
                    if (feedDictionary) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            //done networking, go back on the main thread
                            [self parseDataFromFeedDictionary:feedDictionary fromRequestWithParameters:parameters];
                        });
                    }
                }
            }
        });
    }
}

- (void) registerForAccessTokenNotification {
    [[NSNotificationCenter defaultCenter] addObserverForName:LoginViewControllerDidGetAccessTokenNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        self.accessToken = note.object;
        //Got a token; populate the initial data
        [self populateDataWithParameters:nil];
    }];
}

- (void) parseDataFromFeedDictionary:(NSDictionary *) feedDictionary fromRequestWithParameters:(NSDictionary *)parameters {
    NSLog(@"%@", feedDictionary);
}


//Need to use this way even we know DataSource has a reference to _mediaItems. We use mutableArrayValueForKey instead of modifying the _mediaItems array, because if we remove the item from our underlying data source without going through the KVC methods, no objects (including IMagesTableViewController) will receive a KVO notification.
- (void) deleteMediaItem:(Media *)item {
    NSMutableArray *mutableArrayWithKVO = [self mutableArrayValueForKey:@"mediaItems"];
    [mutableArrayWithKVO removeObject:item];
}

#pragma mark - Completion Handler

- (void) requestNewItemsWithCompletionHandler:(NewItemCompletionBlock)completionHandler {
    //#1 Means if there isn't currently isRefreshing, we set it to YES then run the code.
    if (self.isRefreshing == NO) {
        self.isRefreshing = YES;
        //#2 - Create new random media object and append it to the front of the KVC array. We place media item at index 0 because that is the index of the top-most table cell.
        
        //TODO: Add images
        self.isRefreshing = NO;
        
        //Check if a completion handler was passed before calling it with nil.
        if (completionHandler) {
            completionHandler(nil);
        }
    }
}

- (void) requestOldItemsWithCompletionHandler:(NewItemCompletionBlock)completionHandler {
    if (self.isLoadingOlderItems == NO) {
        self.isLoadingOlderItems = YES;
        
        //TODO: Add images
        self.isLoadingOlderItems = NO;
        
        if (completionHandler) {
            completionHandler(nil);
        }
    }
}

+ (NSString *) instagramClientID {
    return @"2481f86c2ea6461db672f40935e28d5f";
}

@end



