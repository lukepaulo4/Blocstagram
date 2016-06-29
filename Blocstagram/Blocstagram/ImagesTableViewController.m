//
//  ImagesTableViewController.m
//  Blocstagram
//
//  Created by Luke Paulo on 6/28/16.
//  Copyright © 2016 Bloc. All rights reserved.
//

#import "ImagesTableViewController.h"

@interface ImagesTableViewController ()
@property (nonatomic, strong) NSMutableArray *images;

@end

@implementation ImagesTableViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        //Custom initialize
        self.images = [NSMutableArray array];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    for (int i = 1; i <= 10; i++) {
        NSString *imageName = [NSString stringWithFormat:@"%d.jpg", i];
        UIImage *image = [UIImage imageNamed:imageName];
        if (image) {
            [self.images addObject:image];
        }
    }
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"imageCell"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return self.images.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //step 1. Dequene...:forIndexPath takes identifier string and compares it with its roster fo registered table view cells. Registered UITableViewCell calss in viewDidLoad with identifier imageCell. Rreturns brand new cell or a used one that is no longer visible on screen
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"imageCell" forIndexPath:indexPath];
    
    // Configure the cell...
    
    //step 2 Set imageViewTag to arb #. Just needs to remain consistent. NUmerical tag can be attached to any UIView and used later to recover it from its superview by invoking viewWithTag. Quick and dirty way to recover UIImageView which will host the image for this cell
    static NSInteger imageViewTag = 1234;
    UIImageView *imageView = (UIImageView*)[cell.contentView viewWithTag:imageViewTag];
    
    //#3 Handles when viewWithTag: fails to recover UIImageView. Means it didn't have one and is therefore a brand new cell. We know it's new since we plan to add a UIImageView to each cell we come across. It's contentMode calls out UIView... which menas the image will be stretched both hor and vert to fill the counds of UIImageView. Then we set its frame to be the same as the UITableView's contentView such that the image consumes the entirety of the cell
    if (!imageView) {
        //This is a new cell, it doesn't have an image view yet
        imageView = [[UIImageView alloc] init];
        imageView.contentMode = UIViewContentModeScaleToFill;
        
        imageView.frame = cell.contentView.bounds;
        
    //#4 Set the image view's auto-resizing property. autoresizingMask is associated with all UIView objects. This prop lets its superview know how to resize it when the superviews width of height changes. Set them by ORing them together using |  **CHECK CHECKPOINT 27 FOR RESIZE OPTIONS & EFFECT. THERE IS A GOOD DIAGRAM OF HOW THESE FLAGS AFFECT THEIR VIEWS!!!!!
        imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight / UIViewAutoresizingFlexibleWidth;
        
    //Set tag of new UIImageView before we add it to contentView as a subView. Next time we dequeue with a tag of 1234 and our call to viewWithTag: will return a reference to that UIImageView
        imageView.tag = imageViewTag;
        [cell.contentView addSubview:imageView];
    }
    
    UIImage *image = self.images[indexPath.row];
    imageView.image = image;
    
    return cell;
}



// Override to support conditional editing of the table view.
- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UIImage *image = self.images[indexPath.row];
    //Need to make sure the aspect ratio is currect so that the pic is sized correctly.
    return (CGRectGetWidth(self.view.frame) / image.size.width) * image.size.height;
    //For best pic performance, reize the image objects themselves to exact size in which they'll be displayed. This is why photos in instagram are always the same size (612x612)
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
