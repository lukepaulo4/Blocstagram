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
//Quotes "" for importing local files, <> for importing external files. This below keychain is good for storing small amounts of privacy-critical data.
#import <UICKeyChainStore.h>
#import <AFNetworking.h>

//Added the mutable array because it's a Key-Value Compliant req. An array must be accessible as an instance var name _<key> or by method -<key> which returns a reference to the array.
@interface DataSource () {
    NSMutableArray *_mediaItems;
}
@property (nonatomic, strong) NSString *accessToken;
@property (nonatomic, strong) NSArray *mediaItems;

//Need BOOL property to track whether a refresh is already in progress so not fetching multiple times while waiting for a result from server
@property (nonatomic, assign) BOOL isRefreshing;
@property (nonatomic, assign) BOOL isLoadingOlderItems;

//Add property ro prevent pointless requests if there are no more older messages
@property (nonatomic, assign) BOOL thereAreNoMoreOlderMessages;

@property (nonatomic, strong) AFHTTPRequestOperationManager *instagramOperationManager;

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
        [self createOperationManager];
        
        self.accessToken = [UICKeyChainStore stringForKey:@"access token"];
        
        if (!self.accessToken) {
            [self registerForAccessTokenNotification];
        } else {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSString *fullPath = [self pathForFilename:NSStringFromSelector(@selector(mediaItems))];
                NSArray *storedMediaItems = [NSKeyedUnarchiver unarchiveObjectWithFile:fullPath];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (storedMediaItems.count > 0) {
                        NSMutableArray *mutableMediaItems = [storedMediaItems mutableCopy];
                        
                        [self willChangeValueForKey:@"mediaItems"];
                        self.mediaItems = mutableMediaItems;
                        [self didChangeValueForKey:@"mediaItems"];
                        
                        
                    } else {
                        [self populateDataWithParameters:nil completionHandler:nil];
                    }
                });
            });
        }
    }
    
    return self;
}




- (void) populateDataWithParameters:(NSDictionary *) parameters completionHandler:(NewItemCompletionBlock)completionHandler {
    if (self.accessToken) {
        //only try to get the data if there's an access token
        
        NSMutableDictionary *mutableParameters = [@{@"access_token": self.accessToken} mutableCopy];
        
        [mutableParameters addEntriesFromDictionary:parameters];
        
        [self.instagramOperationManager GET:@"users/self/media/recent"
                        parameters:mutableParameters
                                    success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                        if ([responseObject isKindOfClass:[NSDictionary class]]) {
                                            [self parseDataFromFeedDictionary:responseObject fromRequestWithParameters:parameters];
                                        }
                                        
                                        if (completionHandler) {
                                            completionHandler(nil);
                                        }
                                    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                        if (completionHandler) {
                                            completionHandler(error);
                                        }
                                    }];
        
    }
}

- (void) registerForAccessTokenNotification {
    [[NSNotificationCenter defaultCenter] addObserverForName:LoginViewControllerDidGetAccessTokenNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        self.accessToken = note.object;
        [UICKeyChainStore setString:self.accessToken forKey:@"access token"];
        //Got a token; populate the initial data
        [self populateDataWithParameters:nil completionHandler:nil];
    }];
}

- (void) parseDataFromFeedDictionary:(NSDictionary *) feedDictionary fromRequestWithParameters:(NSDictionary *)parameters {
    
    NSArray *mediaArray = feedDictionary[@"data"];
    
    NSMutableArray *tmpMediaItems = [NSMutableArray array];
    
    for (NSDictionary *mediaDictionary in mediaArray) {
        Media *mediaItem = [[Media alloc] initWithDictionary:mediaDictionary];
        
        if (mediaItem) {
            [tmpMediaItems addObject:mediaItem];
        }
    }
    
    NSMutableArray *mutableArrayWithKVO = [self mutableArrayValueForKey:@"mediaItems"];
    
    if (parameters[@"min_id"]) {
        //this was a pull to refresh request
        
        NSRange rangeOfIndexes = NSMakeRange(0, tmpMediaItems.count);
        NSIndexSet *indexSetOfNewObjects = [NSIndexSet indexSetWithIndexesInRange:rangeOfIndexes];
        
        [mutableArrayWithKVO insertObjects:tmpMediaItems atIndexes:indexSetOfNewObjects];
    } else if (parameters[@"max_id"]) {
        //This was an infinite scroll reqeust
        
        if (tmpMediaItems.count == 0) {
            //disable infinite scroll, since there are no more older messages
            self.thereAreNoMoreOlderMessages = YES;
        } else {
            [mutableArrayWithKVO addObjectsFromArray:tmpMediaItems];
        }
    
    } else {
        [self willChangeValueForKey:@"mediaItems"];
        self.mediaItems = tmpMediaItems;
        [self didChangeValueForKey:@"mediaItems"];
    }
    //added this when added the below method to write to the file when new data arrives.
    [self saveImages];
}

//New method to write to the file when new data arrives
- (void) saveImages {
    
    if (self.mediaItems.count > 0) {
        //Write the changes to disk. Just like connecting to the Internet, reading or writing to disk can be slow. It's best to dispatch_async onto a background queue to do the file work you need.
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSUInteger numberOfItemsToSave = MIN(self.mediaItems.count, 50);
            
            //After we're on a background queue, we make an NSArray containing the first 50 or fewer items(so we don't flood the user's hard drive). We convert this array into an NSData and save it to disk.
            NSArray *mediaItemsToSave = [self.mediaItems subarrayWithRange:NSMakeRange(0, numberOfItemsToSave)];
            NSString *fullPath = [self pathForFilename:NSStringFromSelector(@selector(mediaItems))];
            NSData *mediaItemData = [NSKeyedArchiver archivedDataWithRootObject:mediaItemsToSave];
            
            NSError *dataError;
            
            //When we save to disk, we pass it two options: NSDataWritingAtomic & NSDataWritingFileProtectionCompletionUnlessOpen. You should always pass these two options unless there is a compellign reason not to. ...Atomic ensures a complete file is saved. Without it, we might corrupt our file if the app crashes while writing to disk.  ...UnlessOpen encrypts the data. This helps protect the user's privacy.
            BOOL wroteSuccessfully = [mediaItemData writeToFile:fullPath options:NSDataWritingAtomic |NSDataWritingFileProtectionCompleteUnlessOpen error:&dataError];
            
            if (!wroteSuccessfully) {
                NSLog(@"Couldn't write file: %@", dataError);
            }
        });
    }
}

- (void) downloadImageForMediaItem:(Media *)mediaItem {
    if (mediaItem.mediaURL && !mediaItem.image) {
        
        //set download state to download in progrerss
        mediaItem.downloadState = MediaDownloadStateDownloadInProgress;
        
        [self.instagramOperationManager GET:mediaItem.mediaURL.absoluteString
                        parameters:nil
                                    success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                        if ([responseObject isKindOfClass:[UIImage class]]) {
                                            mediaItem.image = responseObject;
                                            
                                            //operations complete and image set successfully, statehasimage
                                            mediaItem.downloadState = MediaDownloadStateHasImage;
                                            NSMutableArray *mutableArrayWithKVO = [self mutableArrayValueForKey:@"mediaItems"];
                                            NSUInteger index = [mutableArrayWithKVO indexOfObject:mediaItem];
                                            [mutableArrayWithKVO replaceObjectAtIndex:index withObject:mediaItem];
                                            [self saveImages];
                                        } else {
                                            
                                            //if error :( set to nonRecoverableError
                                            mediaItem.downloadState = MediaDownloadStateNonRecoverableError;
                                        }
                                        
                                    
                                        
                                    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                        NSLog(@"Error downloading image: %@", error);
                                        
                                        mediaItem.downloadState = MediaDownloadStateNonRecoverableError;
                                        
                                        if ([error.domain isEqualToString:NSURLErrorDomain]) {
                                            //A networking problem
                                            if (error.code == NSURLErrorTimedOut ||
                                                error.code == NSURLErrorCancelled ||
                                                error.code == NSURLErrorCannotConnectToHost ||
                                                error.code == NSURLErrorNetworkConnectionLost ||
                                                error.code == NSURLErrorNotConnectedToInternet ||
                                                error.code == kCFURLErrorInternationalRoamingOff ||
                                                error.code == kCFURLErrorCallIsActive ||
                                                error.code == kCFURLErrorDataNotAllowed ||
                                                error.code == kCFURLErrorRequestBodyStreamExhausted) {
                                                
                                                //It might work if we try again
                                                mediaItem.downloadState = MediaDownloadStateNeedsImage;
                                            }
                                        }
                                        
                                    }];
        
        }
}


//Need to use this way even we know DataSource has a reference to _mediaItems. We use mutableArrayValueForKey instead of modifying the _mediaItems array, because if we remove the item from our underlying data source without going through the KVC methods, no objects (including IMagesTableViewController) will receive a KVO notification.
- (void) deleteMediaItem:(Media *)item {
    NSMutableArray *mutableArrayWithKVO = [self mutableArrayValueForKey:@"mediaItems"];
    [mutableArrayWithKVO removeObject:item];
}



#pragma mark - Completion Handler

- (void) requestNewItemsWithCompletionHandler:(NewItemCompletionBlock)completionHandler {
    self.thereAreNoMoreOlderMessages = NO;
    
    //#1 Means if there isn't currently isRefreshing, we set it to YES then run the code.
    if (self.isRefreshing == NO) {
        self.isRefreshing = YES;
        //#2 - Create new random media object and append it to the front of the KVC array. We place media item at index 0 because that is the index of the top-most table cell.
        
        NSString *minID = [[self.mediaItems firstObject] idNumber];
        NSDictionary *parameters;
        
        if (minID) {
            parameters = @{@"min_id":minID};
        }
        
        [self populateDataWithParameters:parameters completionHandler:^(NSError *error) {
            self.isRefreshing = NO;
            
            if (completionHandler) {
                completionHandler(error);
            }
        }];
        
    }
}

- (void) requestOldItemsWithCompletionHandler:(NewItemCompletionBlock)completionHandler {
    if (self.isLoadingOlderItems == NO && self.thereAreNoMoreOlderMessages == NO) {
        self.isLoadingOlderItems = YES;
        
        NSString *maxID = [[self.mediaItems lastObject] idNumber];
        NSDictionary *parameters;
        
        if (maxID) {
            parameters = @{@"max_id": maxID};;
        }
        
        [self populateDataWithParameters:parameters completionHandler:^(NSError *error) {
            self.isLoadingOlderItems = NO;
            if (completionHandler) {
                completionHandler(error);
            }
        }];
    }
}

+ (NSString *) instagramClientID {
    return @"2481f86c2ea6461db672f40935e28d5f";
}

//Now that objects conform to NSCoding, let's update DataSource to save files to disk and check for it at launch. Add method to create the full path to a file given a filename. This code will create a string containing an absolute path to the user's documents directory likd /somedir/someotherdir/filenmae. We'll write to the file when new data arrives. We do that by adding a new method called saveImages which we will call at the end of parseDataFromFeedDirectory:fromRequestWithParameters
- (NSString *) pathForFilename:(NSString *) filename {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:filename];
    return dataPath;
}

#pragma mark - Liking Media Items

- (void) toggleLikeOnMediaItem:(Media *)mediaItem withCompletionHandler:(void (^)(void))completionHandler {
    NSString *urlString = [NSString stringWithFormat:@"media/%@/likes", mediaItem.idNumber];
    NSDictionary *parameters = @{@"access_token": self.accessToken};
    
    if (mediaItem.likeState == LikeStateNotLiked) {
        
        mediaItem.likeState = LikeStateLiking;
        
        [self.instagramOperationManager POST:urlString parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            mediaItem.likeState = LikeStateLiked;
            
            mediaItem.likeCount++;
            
            if (completionHandler) {
                completionHandler();
            }
            
            [self saveImages];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            mediaItem.likeState = LikeStateNotLiked;
            
            if (completionHandler) {
                completionHandler();
            }
        
        }];
        
    } else if (mediaItem.likeState == LikeStateLiked) {
        
        mediaItem.likeState = LikeStateUnliking;
        
        [self.instagramOperationManager DELETE:urlString parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            mediaItem.likeState = LikeStateNotLiked;
            
            mediaItem.likeCount--;
            
            if (completionHandler) {
                completionHandler();
            }
            
            [self saveImages];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            mediaItem.likeState = LikeStateLiked;
            
            if (completionHandler) {
                completionHandler();
            }
        
        }];
    
    }
}


//Initialize the operation manager
- (void) createOperationManager {
    NSURL *baseURL = [NSURL URLWithString:@"https://api.instagram.com/v1/"];
    self.instagramOperationManager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:baseURL];
    
    AFJSONResponseSerializer *jsonSerializer = [AFJSONResponseSerializer serializer];
    
    AFImageResponseSerializer *imageSerializer = [AFImageResponseSerializer serializer];
    imageSerializer.imageScale = 1.0;
    
    AFCompoundResponseSerializer *serializer = [AFCompoundResponseSerializer compoundSerializerWithResponseSerializers:@[jsonSerializer, imageSerializer]];
    self.instagramOperationManager.responseSerializer = serializer;
    
}
    

@end

    
