//
//  CropImageViewController.m
//  Blocstagram
//
//  Created by Luke Paulo on 7/30/16.
//  Copyright © 2016 Bloc. All rights reserved.
//

#import "CropImageViewController.h"
#import "CropBox.h"
#import "Media.h"
#import "UIImage+ImageUtilities.h"


@interface CropImageViewController ()

@property (nonatomic, strong) CropBox *cropBox;
@property (nonatomic, assign) BOOL hasLoadedOnce;

//We will just be using these for their unique translucent effect. Not for displaying small buttons (their typical use).
@property (nonatomic, strong) UIToolbar *topView;
@property (nonatomic, strong) UIToolbar *bottomView;



@end

@implementation CropImageViewController

//Initialize the crop box. Also, since the superclass (MediaFullScreenViewController) uses Media item, we'll create a new Media item from the image.
- (instancetype) initWithImage:(UIImage *)sourceImage {
    self = [super init];
    
    if (self) {
        self.media = [[Media alloc] init];
        self.media.image = sourceImage;
        
        self.cropBox = [CropBox new];
        
        //Initialize the toolbars
        self.topView = [UIToolbar new];
        self.bottomView = [UIToolbar new];
    }
    
    return self;
}

//The superclass takes care of most of the work. We need to: 1. Set clipsToBounds to YES so the crop image doesn't overlap other controllers during nav controller transitions. 2. Add the crop box to view hierarchy. 3. Create a "crop image" button in the nav bar. 4. Disable UINavigationControllers behavior of automatically adjusting scroll view insets (since we'll position it manually). 5. Set title and background color.
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.clipsToBounds = YES;
    
    UIColor *whiteBG = [UIColor colorWithWhite:1.0 alpha:.15];
    self.topView.barTintColor = whiteBG;         //like background color, but translucent
    self.bottomView.barTintColor = whiteBG;
    self.topView.alpha = 0.5;
    self.bottomView.alpha = 0.5;
    
    //Add the views....
    [self.view addSubview:self.cropBox];
    [self.view addSubview:self.topView];
    [self.view addSubview:self.bottomView];
    
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Crop", @"Crop command") style:UIBarButtonItemStyleDone target:self action:@selector(cropPressed:)];
    
    self.navigationItem.title = NSLocalizedString(@"Crop Image", nil]);
    self.navigationItem.rightBarButtonItem = rightButton;
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.view.backgroundColor = [UIColor colorWithWhite:0.8 alpha:1];
}

- (void) viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGRect cropRect = CGRectZero;
    
    CGFloat edgeSize = MIN(CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame));
    cropRect.size = CGSizeMake(edgeSize, edgeSize);
    
    CGSize size = self.view.frame.size;
    
    self.cropBox.frame = cropRect;
    self.cropBox.center = CGPointMake(size.width / 2, size.height / 2);
    self.scrollView.frame = self.cropBox.frame;
    self.scrollView.clipsToBounds = NO;
    
    //Make the frames for the translucent toolbar ya bish.
    CGFloat width = CGRectGetWidth(self.view.bounds);
    self.topView.frame = CGRectMake(0, 0, width, CGRectGetMinY(self.cropBox.frame));
    
    CGFloat yOriginOfBottomView = CGRectGetMaxY(self.topView.frame) + width;
    CGFloat heightOfBottomView = CGRectGetHeight(self.view.frame) - yOriginOfBottomView;
    self.bottomView.frame = CGRectMake(0, yOriginOfBottomView, width, heightOfBottomView);

    
    [self recalculateZoomScale];
    
    if (self.hasLoadedOnce == NO) {
        self.scrollView.zoomScale = self.scrollView.minimumZoomScale;
        self.hasLoadedOnce = YES;
    }
    
}



- (void) cropPressed:(UIBarButtonItem *)sender {
    CGRect visibleRect;
    float scale = 1.0f / self.scrollView.zoomScale / self.media.image.scale;
    visibleRect.origin.x = self.scrollView.contentOffset.x * scale;
    visibleRect.origin.y = self.scrollView.contentOffset.y * scale;
    visibleRect.size.width = self.scrollView.bounds.size.width * scale;
    visibleRect.size.height = self.scrollView.bounds.size.height * scale;
    
    UIImage *scrollViewCrop = [self.media.image imageWithFixedOrientation];
    scrollViewCrop = [scrollViewCrop imageCroppedToRect:visibleRect];
    
    [self.delegate cropControllerFinishedWithImage:scrollViewCrop];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
