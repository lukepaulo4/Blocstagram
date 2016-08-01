//
//  MediaFullScreenViewController.m
//  Blocstagram
//
//  Created by Luke Paulo on 7/20/16.
//  Copyright © 2016 Bloc. All rights reserved.
//

#import "MediaFullScreenViewController.h"
#import "Media.h"

@interface MediaFullScreenViewController () <UIScrollViewDelegate>

@property (nonatomic, strong) UITapGestureRecognizer *tap;
@property (nonatomic, strong) UITapGestureRecognizer *doubleTap;

//Need a property for outsideTap & for UIWindow!
@property (nonatomic, strong) UITapGestureRecognizer *outsideTap;
@property (nonatomic, strong) UIWindow *window;


@end

@implementation MediaFullScreenViewController

- (instancetype) initWithMedia:(Media *)media {
    self = [super init];
    
    if (self) {
        self.media = media;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //#1 - Create & configure a scroll view, and add it as the only subview of self.view
    self.scrollView = [UIScrollView new];
    self.scrollView.delegate = self;
    self.scrollView.backgroundColor = [UIColor whiteColor];
    
    [self.view addSubview:self.scrollView];
    
    //#2 - Create an image view, set the image, and add it as a subview of the scroll view.
    self.imageView = [UIImageView new];
    self.imageView.image = self.media.image;
    
    [self.scrollView addSubview:self.imageView];
    
    //#3 - Property reps the size of the content view, which is the content being scrolled around. In our case, we're simply scrolling around an image, so we'll pass in it's size.
    self.scrollView.contentSize = self.media.image.size;
    
    self.tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapFired:)];
    
    self.doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapFired:)];
    self.doubleTap.numberOfTapsRequired = 2;
    
    //Add the window and outsideTap
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.outsideTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(outsideTapFired:)];
    
    //This allows one gesture recognizer to wait for another gest recog to fail before it succeeds. Without this line, it would be impossible to double-tap because the single tap gesture recognizer would fire before the user had a chance to tap twice.
    [self.tap requireGestureRecognizerToFail:self.doubleTap];
    
    [self.scrollView addGestureRecognizer:self.tap];
    [self.scrollView addGestureRecognizer:self.doubleTap];
}

//When the user single-taps, simply dismiss the view controller
#pragma mark - Gesture Recognizers

- (void) tapFired:(UITapGestureRecognizer *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

//when user double taps, adjust the zoom level
- (void) doubleTapFired:(UITapGestureRecognizer *)sender {
    if (self.scrollView.zoomScale == self.scrollView.minimumZoomScale) {
        //#8 - If current zoom scale is already as small as it can be, double tapping will zoom in. This woks by calculating a rectangle using the user's finger as a center point, and telling the scroll view to zoom in on that rectangle
        CGPoint locationPoint = [sender locationInView:self.imageView];
        
        CGSize scrollViewSize = self.scrollView.bounds.size;
        
        CGFloat width = scrollViewSize.width / self.scrollView.maximumZoomScale;
        CGFloat height = scrollViewSize.height / self.scrollView.maximumZoomScale;
        CGFloat x = locationPoint.x - (width /2);
        CGFloat y = locationPoint.y - (height /2);
        
        [self.scrollView zoomToRect:CGRectMake(x, y, width, height) animated:YES];
    } else {
        // #9 - If the current zoom scale is larger then zoom out to the minimum scale
        [self.scrollView setZoomScale:self.scrollView.minimumZoomScale animated:YES];
    
    }
}

//Add a method for outsideTapFired. Set location of tap in the local view coordinate system. If it is out of it, get rid of the view. Yee
- (void) outsideTapFired:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        CGPoint pointLocation = [sender locationInView:nil];
    
        if (![self.view pointInside:[self.view convertPoint:pointLocation fromView:self.view.window] withEvent:nil]) {
            [self.view.window removeGestureRecognizer:sender];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

- (void) viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    //#4 - Set the scroll's frame to the view's bounds. Scroll will always take up all of the view's space
    self.scrollView.frame = self.view.bounds;
    
    [self recalculateZoomScale];
}

- (void) recalculateZoomScale {

    //#5 - 2 ratios. Scrolls width to image width && scroll views height to images height. Whichever is smaller will become our minimumZoomScale. This prevents user from pinching the image so small that theres wasted screen space. maximumZoomScale will alwyas be 1 (repping 100%). We could make this bigger, but then the image would get pixalated if the user zooms in too much.
    CGSize scrollViewFrameSize = self.scrollView.frame.size;
    CGSize scrollViewContentSize = self.scrollView.contentSize;
    
    //Add these lines to divide the size dimensions by self.scrollView.zoomScale. This allows subclasses to recalculate the zoom scale for scroll views that are zoomed out
    scrollViewContentSize.height /= self.scrollView.zoomScale;
    scrollViewContentSize.width /= self.scrollView.zoomScale;
    
    CGFloat scaleWidth = scrollViewFrameSize.width / scrollViewContentSize.width;
    CGFloat scaleHeight = scrollViewFrameSize.width / scrollViewContentSize.height;
    CGFloat minScale = MIN(scaleWidth, scaleHeight);
    
    self.scrollView.minimumZoomScale = minScale;
    self.scrollView.maximumZoomScale = 1;
}

//Centers the picture (media item) in case it's square or something and doesn't cover the whole screen
- (void)centerScrollView {
    [self.imageView sizeToFit];
    
    CGSize boundsSize = self.scrollView.bounds.size;
    CGRect contentsFrame = self.imageView.frame;
    
    if (contentsFrame.size.width < boundsSize.width) {
        contentsFrame.origin.x = (boundsSize.width - CGRectGetWidth(contentsFrame)) / 2;
    } else {
        contentsFrame.origin.x = 0;
    }
    
    if (contentsFrame.size.height < boundsSize.height) {
        contentsFrame.origin.y = (boundsSize.height - CGRectGetHeight(contentsFrame)) / 2;
    } else {
        contentsFrame.origin.y = 0;
    }
    
    self.imageView.frame = contentsFrame;

}

#pragma mark - UIScrollViewDelegate
//#6 - Tell scroll view which view to zoom in and out on
- (UIView*)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

//#7 - Calls centerScrollView ater the user has changed the zoom level.
- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self centerScrollView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//Make sure image starts out centered
- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self centerScrollView];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
