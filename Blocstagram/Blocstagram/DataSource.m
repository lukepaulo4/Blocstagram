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

//Added the mutable array because it's a Key-Value Compliant req. An array must be accessible as an instance var name _<key> or by method -<key> which returns a reference to the array.
@interface DataSource () {
    NSMutableArray *_mediaItems;
}

@property (nonatomic, strong) NSArray *mediaItems;

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
        [self addRandomData];
    }
    
    return self;
}

//This method does the following: 1. Loads every placeholder image in our app. 2. creates a Media model for it. 3. Attaches a randomly generated User to it. 4. Adds a random caption. 5. Attaches a randomly generated number of Comments to it. 6. Puts each media item into the mediaItems array.
- (void) addRandomData {
    NSMutableArray *randomMediaItems = [NSMutableArray array];
    
    for (int i = 1; i <=10; i++) {
        NSString *imageName = [NSString stringWithFormat:@"%d.jpg", i];
        UIImage *image = [UIImage imageNamed:imageName];
        
        if (image) {
            Media *media = [[Media alloc] init];
            media.user = [self randomUser];
            media.image = image;
            media.caption = [self randomSentence];
            
            //arc4random_uniform() returns a random, non-negative number less than the number supplied to it. We add 2 to the result (so all random data will have at least two characters), and use the result to create strings of random length and sentences of random word count.
            NSUInteger commentCount = arc4random_uniform(10) + 2;
            NSMutableArray *randomComments = [NSMutableArray array];
            
            for (int i = 0; i <= commentCount; i++) {
                Comment *randomComment = [self randomComment];
                [randomComments addObject:randomComment];
            }
            
            media.comments = randomComments;
            
            [randomMediaItems addObject:media];
            
            }
        }
    
    self.mediaItems = randomMediaItems;
}

- (User *) randomUser {
    User *user = [[User alloc] init];
    
    user.userName = [self randomStringOfLength:arc4random_uniform(10) + 2];
    
    NSString *firstName = [self randomStringOfLength:arc4random_uniform(7) + 2];
    NSString *lastName = [self randomStringOfLength:arc4random_uniform(12) + 2];
    user.fullName = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
    
    return user;
}

- (Comment *) randomComment {
    Comment *comment = [[Comment alloc] init];
    
    comment.from = [self randomUser];
    comment.text = [self randomSentence];
    
    return comment;
}

- (NSString *) randomSentence {
    NSUInteger wordCount = arc4random_uniform(20) + 2;
    
    NSMutableString *randomSentence = [[NSMutableString alloc] init];
    
    for (int i = 0; i <= wordCount; i++) {
        NSString *randomWord = [self randomStringOfLength:arc4random_uniform(12) + 2];
        [randomSentence appendFormat:@"%@ ", randomWord];
    }
    
    return randomSentence;
}

- (NSString *) randomStringOfLength:(NSUInteger) len {
    NSString *alphabet = @"abcdefghijklmnopqrstuvwxyz";
    
    NSMutableString *s = [NSMutableString string];
    for (NSUInteger i = 0U; i < len; i ++) {
        u_int32_t r = arc4random_uniform((u_int32_t)[alphabet length]);
        unichar c = [alphabet characterAtIndex:r];
        [s appendFormat:@"%C", c];
    }
    
    return [NSString stringWithString:s];
}

//Need to use this way even we know DataSource has a reference to _mediaItems. We use mutableArrayValueForKey instead of modifying the _mediaItems array, because if we remove the item from our underlying data source without going through the KVC methods, no objects (including IMagesTableViewController) will receive a KVO notification.
- (void) deleteMediaItem:(Media *)item {
    NSMutableArray *mutableArrayWithKVO = [self mutableArrayValueForKey:@"mediaItems"];
    [mutableArrayWithKVO removeObject:item];
    //This moves our deleted object to the top of our mutable array. 
    [mutableArrayWithKVO insertObject:item atIndex:0];
}



@end




