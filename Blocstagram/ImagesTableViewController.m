//
//  ImagesTableViewController.m
//  Blocstagram
//
//  Created by Luke Paulo on 6/28/16.
//  Copyright © 2016 Bloc. All rights reserved.
//

#import "ImagesTableViewController.h"
#import "DataSource.h"
#import "Media.h"
#import "User.h"
#import "Comment.h"
#import "MediaTableViewCell.h"
#import "MediaFullScreenViewController.h"
#import "CameraViewController.h"

@interface ImagesTableViewController () <MediaTableViewCellDelegate, CameraViewControllerDelegate>

@property (nonatomic, weak) UIImageView *lastTappedImageView;

//update the images table controller to control the cell and its comment view
@property (nonatomic, weak) UIView *lastSelectedCommentView;
@property (nonatomic, assign) CGFloat lastKeyboardAdjustment;

@end

@implementation ImagesTableViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        //Removed the below code with the introduction of the other classes and new MVC design
        //self.images = [NSMutableArray array];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //Below we register for KVO of mediaItems
    [[DataSource sharedInstance] addObserver:self forKeyPath:@"mediaItems" options:0 context:nil];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshControlDidFire:) forControlEvents:UIControlEventValueChanged];
    
    [self.tableView registerClass:[MediaTableViewCell class] forCellReuseIdentifier:@"mediaCell"];
    
    //Request notifications of the keyboard appearing and disappearing. We'll also enable UIScrollViewKeyboardKismissModeInteractive
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    
    //Check if any photo capabilities at all are available, and if so, add a camera button:
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] || [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum]) {
        UIBarButtonItem *cameraButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(cameraPressed:)];
        
        self.navigationItem.rightBarButtonItem = cameraButton;
        //NOTE THAT THE CAMERA WON'T APPEAR IN THE SIMULATOR
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
}


//Make sure the cells aren't selected when the view appears. Since we're skipping the code that does that, we'll now need to do that ourself
- (void)viewWillAppear:(BOOL)animated {
    NSIndexPath *indexPath = self.tableView.indexPathForSelectedRow;
    if (indexPath) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:animated];
    }
}

- (void) viewWilldisappear:(BOOL)animated {
    
}


- (void) refreshControlDidFire:(UIRefreshControl *) sender {
    [[DataSource sharedInstance] requestNewItemsWithCompletionHandler:^(NSError *error) {
        [sender endRefreshing];
    }];
}

- (void) infiniteScrollIfNecessary {
    //#3 - Checks whether or not the user has scrolled to the last photo. This is accomplished by inspecting an array of NSIndexPath objects which represent the cells visible on the screen. We call lastObject on the NSArray returned by indexPathsForVisibleRows to recover the index path of the cell shown at the very bottom of the table. If that cell reps the last image in the _mediaItems array, we call requestOldItemsWithCompletionHandler: in order to recover more.
    NSIndexPath *bottomIndexPath = [[self.tableView indexPathsForVisibleRows] lastObject];
    
    if (bottomIndexPath && bottomIndexPath.row == [DataSource sharedInstance].mediaItems.count -1) {
        //The very last cell is on the screen
        [[DataSource sharedInstance] requestOldItemsWithCompletionHandler:nil];
    }
}

#pragma mark - UIScrollViewDelegate

//#4 UITableView is a subclass of UIScrollView. A scroll view is a UI element which scrolls. When its content size is larger than its frame, a pan gesture moves its content. A scroll view can be scrolled hor and/or vert. A table view is locked into vert only scrollage. Scroll view has a delegate protocol with many methods in it, one of which is scrollViewDidScroll. This delegate method is invoked when the scroll view is scrolled in any direction. As the user scrolls the table view, this method will be called repeatedly. It's a good place to check whether or not the last image in our array has made it onto the screen.
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self infiniteScrollIfNecessary];
}

//Observers must be removed when they're no longer needed. Dealloc smack smacks this. Dealloc is an NSObject method. Allows an object to perform some cleanup before the object goes away. This method is a class' last chance to do anything before 'self' disappears. We call removeObserver:forKeyPath here because once dealloc returns. ImagesTableViewController will no longer exist and therefore will not need the notifications. Forgetting to remove observers may result in a crash if the observed object attempts to communicate with an observer that no longer exists.
- (void) dealloc {
    [[DataSource sharedInstance] removeObserver:self forKeyPath:@"mediaItems"];
    
    //Unregister for the notifications called for keyboardWillShow and keyboardWillHide
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

//Info about update will be found in the change dictionary. There are multiple kind of change that can occue. Read documentation to see more (Entire obj replaced, Added, Removed, Replaced within the collection)
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == [DataSource sharedInstance] && [keyPath isEqualToString:@"mediaItems"]) {
        //We know mediaItems changed. Let's see what kind of change it is.
        NSKeyValueChange kindOfChange = [change[NSKeyValueChangeKindKey] unsignedIntegerValue];
        
        if (kindOfChange == NSKeyValueChangeSetting) {
            //Someone set a brand new images array
            [self.tableView reloadData];
            
        } else if (kindOfChange == NSKeyValueChangeInsertion || kindOfChange == NSKeyValueChangeRemoval || kindOfChange == NSKeyValueChangeReplacement) {
            //We have an incremental change: inserted, deleted, or replaced images
            
            //Get a list of the index (or indices) that changed
            NSIndexSet *indexSetOfChanges = change[NSKeyValueChangeIndexesKey];
            
            //#1 - Convert this NSIndexSet to an NSArray of NSIndexPaths (which is what the table view animation methods require). Create and provide NSArray of NSIndexPath objects to update the table view's rows. All the rows are in a single section and are ordered by their location in the mediaItems array. Therefore we enumerate indexSetOfChanges and add to a brand new array, indexPathsThatChanged.
            NSMutableArray *indexPathsThatChanged = [NSMutableArray array];
            [indexSetOfChanges enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:idx inSection:0];
                [indexPathsThatChanged addObject:newIndexPath];
            }];
            
            //#2 - Call 'beginUpdates' to tell the table view we're about to make changes. Before we tell the table which rows have been altered, removed, or deleted, we prepare it for updates by calling beginUpdates.
            [self.tableView beginUpdates];
            
            //Tell the table view what the changes are. The else if block checks to make sure that the changes which occured is one of the remaining: insert, remove, or replace. We recover NSIndexSet for each modified index. For ex, if images 2 and 3 were removed from mediaItems, those two values would be found in this set.
            if (kindOfChange == NSKeyValueChangeInsertion) {
                [self.tableView insertRowsAtIndexPaths:indexPathsThatChanged withRowAnimation:UITableViewRowAnimationAutomatic];
            } else if (kindOfChange == NSKeyValueChangeRemoval) {
                [self.tableView deleteRowsAtIndexPaths:indexPathsThatChanged withRowAnimation:UITableViewRowAnimationAutomatic];
            } else if (kindOfChange == NSKeyValueChangeReplacement) {
                [self.tableView reloadRowsAtIndexPaths:indexPathsThatChanged withRowAnimation:UITableViewRowAnimationAutomatic];
            }
            
            //Tell the table view that we're done telling it about changes, and to complete the animation
            [self.tableView endUpdates];
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Camera and CameraViewControllerDelegate

- (void) cameraPressed:(UIBarButtonItem *) sender {
    CameraViewController *cameraVC = [[CameraViewController alloc] init];
    cameraVC.delegate = self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:cameraVC];
    [self presentViewController:nav animated:YES completion:nil];
    
    return;
}

- (void) cameraViewController:(CameraViewController *)cameraViewController didCompleteWithImage:(UIImage *)image {
    [cameraViewController dismissViewControllerAnimated:YES completion:^{
        if (image) {
            NSLog(@"Got an image!");
        } else {
            NSLog(@"Closed without an image.");
        }
    }];
}

#pragma mark - Table view data source


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    //Removed the below code with the introduction of the other classes and new MVC design
    //return self.images.count;
    
    //Added the below
    return [DataSource sharedInstance].mediaItems.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // Configure the cell...
    MediaTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"mediaCell" forIndexPath:indexPath];
    cell.delegate = self;
    cell.mediaItem = [DataSource sharedInstance].mediaItems[indexPath.row];
    
    return cell;
}

#pragma mark - MediaTableViewCellDelegate

- (void) cell:(MediaTableViewCell *)cell didTapImageView:(UIImageView *)imageView {
    MediaFullScreenViewController *fullScreenVC = [[MediaFullScreenViewController alloc] initWithMedia:cell.mediaItem];
    
    [self presentViewController:fullScreenVC animated:YES completion:nil];
}

- (void) cell:(MediaTableViewCell *)cell didLongPressImageView:(UIImageView *)imageView {
    NSMutableArray *itemsToShare = [NSMutableArray array];
    
    if (cell.mediaItem.caption.length > 0) {
        [itemsToShare addObject:cell.mediaItem.caption];
    }
    
    if (cell.mediaItem.image) {
        [itemsToShare addObject:cell.mediaItem.image];
    }
    
    if (itemsToShare.count > 0) {
        UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:itemsToShare applicationActivities:nil];
        [self presentViewController:activityVC animated:YES completion:nil];
    }
}

//Connect the cell to the new data source method. Both the completion handler and at the end of the method, we set cell.mediaItem, which updates the button's appearance
- (void) cellDidPressLikeButton:(MediaTableViewCell *)cell {
    Media *item = cell.mediaItem;
    
    [[DataSource sharedInstance] toggleLikeOnMediaItem:item withCompletionHandler:^{
        
        //This is important because table views reload cells. If the user scrolls and the cell is reused to display a different media item, we no longer want to update the button
        if (cell.mediaItem == item) {
            cell.mediaItem = item;
        }
    }];
    
    cell.mediaItem = item;
}

//If the user starts composing a comment, we'll store a reference to the comment view
- (void) cellWillStartComposingComment:(MediaTableViewCell *)cell {
    self.lastSelectedCommentView = (UIView *)cell.commentView;
}

//If the user presses the comment button, we'll tell the API to send a comment
- (void) cell:(MediaTableViewCell *)cell didComposeComment:(NSString *)comment {
    [[DataSource sharedInstance] commentOnMediaItem:cell.mediaItem withCommentText:comment];
}

//If a row is tapped, let's assume the user doesn't want the keyboard
- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MediaTableViewCell *cell = (MediaTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    [cell stopComposingComment];
}

- (void) tableView:(UITableView *)tableView willDisplaceCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    Media *mediaItem = [DataSource sharedInstance].mediaItems[indexPath.row];
    if (mediaItem.downloadState == MediaDownloadStateNeedsImage) {
        [[DataSource sharedInstance] downloadImageForMediaItem:mediaItem];
    }
}

// Override to support conditional editing of the table view.
- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    Media *item = [DataSource sharedInstance].mediaItems[indexPath.row];
    
    return [MediaTableViewCell heightForMediaItem:item width:CGRectGetWidth(self.view.frame)];
}

//Implement the swip to delete action
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //Delete the row from the data source
        Media *item = [DataSource sharedInstance].mediaItems[indexPath.row];
        [[DataSource sharedInstance] deleteMediaItem:item];
    }
}

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    Media *item = [DataSource sharedInstance].mediaItems[indexPath.row];
    if (item.image) {
        return 450;
    } else {
        return 250;
        
    }
}

#pragma mark - Keyboard Handling

//Determine if the keyboard will obscure the comment view's text box. (Happens if user taps comment on lower half of the screen). If will obscure, adjust the table view's content insets and offset to move the comment view directly above the keyboard. If we make changes, save them for later so we can undo them when teh keyboard hides.
- (void)keyboardWillShow:(NSNotification *)notification {
    // Get the frame of the keyboard within self.view's coordinate system
    NSValue *frameValue = notification.userInfo[UIKeyboardFrameEndUserInfoKey];
    
    //make sure keyboard's frame and the comment view's frame are in same coordinate system.
    CGRect keyboardFrameInScreenCoordinates = frameValue.CGRectValue;
    CGRect keyboardFrameInViewCoordinates = [self.navigationController.view convertRect:keyboardFrameInScreenCoordinates fromView:nil];
    
    // Get the frame of the comment view in the same coordinate system
    CGRect commentViewFrameInViewCoordinates = [self.navigationController.view convertRect:self.lastSelectedCommentView.bounds fromView:self.lastSelectedCommentView];
    
    CGPoint contentOffset = self.tableView.contentOffset;
    UIEdgeInsets contentInsets = self.tableView.contentInset;
    UIEdgeInsets scrollIndicatorInsets = self.tableView.scrollIndicatorInsets;
    CGFloat heightToScroll = 0;
    
    CGFloat keyboardY = CGRectGetMinY(keyboardFrameInViewCoordinates);
    CGFloat commentViewY = CGRectGetMinY(commentViewFrameInViewCoordinates);
    CGFloat difference = commentViewY - keyboardY;
    
    if (difference > 0) {
        heightToScroll += difference;
    }
    
    if (CGRectIntersectsRect(keyboardFrameInViewCoordinates, commentViewFrameInViewCoordinates)) {
        // The two frames intersect (the keyboard would block the view)
        CGRect intersectionRect = CGRectIntersection(keyboardFrameInViewCoordinates, commentViewFrameInViewCoordinates);
        heightToScroll += CGRectGetHeight(intersectionRect);
    }
    
    if (heightToScroll > 0) {
        contentInsets.bottom += heightToScroll;
        scrollIndicatorInsets.bottom += heightToScroll;
        contentOffset.y += heightToScroll;
        
        NSNumber *durationNumber = notification.userInfo[UIKeyboardAnimationDurationUserInfoKey];
        NSNumber *curveNumber = notification.userInfo[UIKeyboardAnimationCurveUserInfoKey];
        
        NSTimeInterval duration = durationNumber.doubleValue;
        UIViewAnimationCurve curve = curveNumber.unsignedIntegerValue;
        UIViewAnimationOptions options = curve << 16;
        
        [UIView animateWithDuration:duration delay:0 options:options animations:^{
            self.tableView.contentInset = contentInsets;
            self.tableView.scrollIndicatorInsets = scrollIndicatorInsets;
            self.tableView.contentOffset = contentOffset;
        } completion:nil];
    }
    
    self.lastKeyboardAdjustment = heightToScroll;
}

- (void)keyboardWillHide:(NSNotification *)notification {
    UIEdgeInsets contentInsets = self.tableView.contentInset;
    contentInsets.bottom -= self.lastKeyboardAdjustment;
    
    UIEdgeInsets scrollIndicatorInsets = self.tableView.scrollIndicatorInsets;
    scrollIndicatorInsets.bottom -= self.lastKeyboardAdjustment;
    
    NSNumber *durationNumber = notification.userInfo[UIKeyboardAnimationDurationUserInfoKey];
    NSNumber *curveNumber = notification.userInfo[UIKeyboardAnimationCurveUserInfoKey];
    
    NSTimeInterval duration = durationNumber.doubleValue;
    UIViewAnimationCurve curve = curveNumber.unsignedIntegerValue;
    UIViewAnimationOptions options = curve << 16;
    
    [UIView animateWithDuration:duration delay:0 options:options animations:^{
        self.tableView.contentInset = contentInsets;
        self.tableView.scrollIndicatorInsets = scrollIndicatorInsets;
    } completion:nil];
}


/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 } else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
