//
//  PostToInstagramViewController.m
//  Blocstagram
//
//  Created by Luke Paulo on 7/31/16.
//  Copyright © 2016 Bloc. All rights reserved.
//

#import "PostToInstagramViewController.h"

@interface PostToInstagramViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UIDocumentInteractionControllerDelegate>


//Store the image passed ionto initWithImage
@property (nonatomic, strong) UIImage *sourceImage;

//displays the image with its current filter
@property (nonatomic, strong) UIImageView *previewImageView;

//stores the photo filter operations
@property (nonatomic, strong) NSOperationQueue *photoFilterOperationQueue;

//is a collection view that shows all of the filters available
@property (nonatomic, strong) UICollectionView *filterCollectionView;

//Hold filter images and their titles
@property (nonatomic, strong) NSMutableArray *filterImages;
@property (nonatomic, strong) NSMutableArray *filterTitles;

//is the big purplr "send to Instagram" button
@property (nonatomic, strong) UIButton *sendButton;

//shows on short iPhones in the navigation bar where there's no room for sendButton
@property (nonatomic, strong) UIBarButtonItem *sendBarButton;

//shares the image to instagram
@property (nonatomic, strong) UIDocumentInteractionController *documentController;

@end

@implementation PostToInstagramViewController

- (instancetype) initWithImage:(UIImage *)sourceImage {
    self = [super init];
    
    if (self) {
        //Store the source image passed in and initialize the preview image view with that image.
        self.sourceImage = sourceImage;
        self.previewImageView = [[UIImageView alloc] initWithImage:self.sourceImage];
        
        //Create operations queue
        self.photoFilterOperationQueue = [[NSOperationQueue alloc] init];
        
        //Create and configure a UICollectionViewFlowLayout instance to define the layout of our filter collection view
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.itemSize = CGSizeMake(44, 64);
        flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        flowLayout.minimumInteritemSpacing = 10;
        flowLayout.minimumLineSpacing = 10;
        
        //Use ^^ to initialize UICollectionView
        self.filterCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
        //Set collection view's delegate and dataSource properties (unecessary in a UICollectionViewController, but we're subclassing plain old UIViewController)
        self.filterCollectionView.dataSource = self;
        self.filterCollectionView.delegate = self;
        
        //Disable showsHori... to hide teh horizontal scroll indicator; this is just an aesthetic preference.
        self.filterCollectionView.showsHorizontalScrollIndicator = NO;
        
        //Initialize filterImages and filterTitles arrays. First object in each array represents the unfiltered image. This allows a user to remove a filter once it's applied.
        self.filterImages = [NSMutableArray arrayWithObject:sourceImage];
        self.filterTitles = [NSMutableArray arrayWithObject:NSLocalizedString(@"None", @"Label for when no filter is applied to a photo")];
        
        //Finally create sendButton & sendBarButton. Both have the same target-action method
        self.sendButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.sendButton.backgroundColor = [UIColor colorWithRed:0.345 green:0.318 blue:0.424 alpha:1]; /*#58516c*/
        self.sendButton.layer.cornerRadius = 5;
        
        //to add text to button
        [self.sendButton setAttributedTitle:[self sendAttributedString] forState:UIControlStateNormal];
        [self.sendButton addTarget:self action:@selector(sendButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        self.sendBarButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Send", @"Send button") style:UIBarButtonItemStyleDone target:self action:@selector(sendButtonPressed:)];
        
        [self addFiltersToQueue];
    }
         
         return self;
}

#pragma mark - Buttons

//Add this method to configure the text on the button
- (NSAttributedString *) sendAttributedString {
    NSString *baseString = NSLocalizedString(@"SEND TO INSTAGRAM", @"send to Instagram button text");
    NSRange range = [baseString rangeOfString:baseString];
    
    NSMutableAttributedString *commentString = [[NSMutableAttributedString alloc] initWithString:baseString];
    
    [commentString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HelveticaNeue-Bold" size:13] range:range];
    [commentString addAttribute:NSKernAttributeName value:@1.3 range:range];
    [commentString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:0.933 green:0.933 blue:0.933 alpha:1] range:range];
    
    return commentString;
}

//Configure teh view, add subviews to the view hierarchy, and decide which button to use
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.view addSubview:self.previewImageView];
    [self.view addSubview:self.filterCollectionView];
    
    if (CGRectGetHeight(self.view.frame) > 500) {
        [self.view addSubview:self.sendButton];
    } else {
        self.navigationItem.rightBarButtonItem = self.sendBarButton;
    }
    
    //Using a vanilla UICollectionViewCell instead of subclass. (Your assignment at the end will be to replace this with a UICollectionViewCell subclass.
    [self.filterCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.filterCollectionView.backgroundColor = [UIColor whiteColor];
    
    self.navigationItem.title = NSLocalizedString(@"Apply Filter", @"apply filter view title");
    
}

//In viewWillLayoutSubviews, we'll position the views: 1. If the view's height is > 500 we'll include sendButton and allow the collection view to take up whatever height remains. 2. If the view's height is < 500 the send button is hidden and the collection view will go to the bottom of the view. We'll also update the UICollectionViewFlowLayout with the scorrect size based on the collection view's determined height.
- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    CGFloat edgeSize = MIN(CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame));
    
    self.previewImageView.frame = CGRectMake(0, self.topLayoutGuide.length, edgeSize, edgeSize);
    
    CGFloat buttonHeight = 50;
    CGFloat buffer = 10;
    
    CGFloat filterViewYOrigin = CGRectGetMaxY(self.previewImageView.frame) + buffer;
    CGFloat filterViewHeight;
    
    if (CGRectGetHeight(self.view.frame) > 500) {
        self.sendButton.frame = CGRectMake(buffer, CGRectGetHeight(self.view.frame) - buffer - buttonHeight, CGRectGetWidth(self.view.frame) - 2 * buffer, buttonHeight);
        
        filterViewHeight = CGRectGetHeight(self.view.frame) - filterViewYOrigin - buffer - buffer - CGRectGetHeight(self.sendButton.frame);
    } else {
        filterViewHeight = CGRectGetHeight(self.view.frame) - CGRectGetMaxY(self.previewImageView.frame) - buffer - buffer;
    }
    
    self.filterCollectionView.frame = CGRectMake(0, filterViewYOrigin, CGRectGetWidth(self.view.frame), filterViewHeight);
    
    UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout *)self.filterCollectionView.collectionViewLayout;
    flowLayout.itemSize = CGSizeMake(CGRectGetHeight(self.filterCollectionView.frame) - 20, CGRectGetHeight(self.filterCollectionView.frame));
    
}

#pragma mark - UICollectionView delegate and data source

//The collection view will always have only one section, so we don't need to implement numberOfSectionsInCollectionView. The number of items will alawys be equal to the number of filtered images available.
- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.filterImages.count;
}

//When the cell loads, we'll make sure there's an image view and a label on it, and we'll set their content from the appropriate arrays. We set the frames of these items based on the flow layout's itemSize property, which is set earlier in viewWillLayoutSubviews.
- (UICollectionViewCell*) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    
    static NSInteger imageViewTag = 1000;
    static NSInteger labelTag = 1001;
    
    UIImageView *thumbnail = (UIImageView *)[cell.contentView viewWithTag:imageViewTag];
    UILabel *label = (UILabel *)[cell.contentView viewWithTag:labelTag];
    
    UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout *)self.filterCollectionView.collectionViewLayout;
    CGFloat thumbnailEdgeSize = flowLayout.itemSize.width;
    
    if (!thumbnail) {
        thumbnail = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, thumbnailEdgeSize, thumbnailEdgeSize)];
        thumbnail.contentMode = UIViewContentModeScaleAspectFill;
        thumbnail.tag = imageViewTag;
        thumbnail.clipsToBounds = YES;
        
        [cell.contentView addSubview:thumbnail];
    }
    
    if (!label) {
        label = [[UILabel alloc] initWithFrame:CGRectMake (0, thumbnailEdgeSize, thumbnailEdgeSize, 20)];
        label.tag = labelTag;
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:10];
        [cell.contentView addSubview:label];
    }
    
    thumbnail.image = self.filterImages[indexPath.row];
    label.text = self.filterTitles[indexPath.row];
    
    return cell;
}

//If the user taps on one of the cells, we'll update the preview image to show the image with the filter:
- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    self.previewImageView.image = self.filterImages[indexPath.row];
}

#pragma mark - Photo filters

- (void) addCIImageToCollectionView:(CIImage *)CIImage withFilterTitle:(NSString *)filterTitle {
    
    //Converts CIImage to UImage. Becasue CIImage isn't fully rendered the output UIImage is slow to draw
    UIImage *image = [UIImage imageWithCIImage:CIImage scale:self.sourceImage.scale orientation:self.sourceImage.imageOrientation];
    
    if (image) {
        //Decompress image
        UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
        [image drawAtPoint:CGPointZero];
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSUInteger newIndex = self.filterImages.count;
            
            [self.filterImages addObject:image];
            [self.filterTitles addObject:filterTitle];
            
            [self.filterCollectionView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:newIndex inSection:0]]];
        });
    }
}

//Add filter to the operation queue.
- (void) addFiltersToQueue {
    CIImage *sourceCIImage = [CIImage imageWithCGImage:self.sourceImage.CGImage];
    
    //Noir filter - addOperationWithBlock takes a block of code and adds it to the operation queue, which means it will run eventually.
    [self.photoFilterOperationQueue addOperationWithBlock:^{
        CIFilter *noirFilter = [CIFilter filterWithName:@"CIPhotoEffectNoir"];
        
        if (noirFilter) {
            [noirFilter setValue:sourceCIImage forKey:kCIInputImageKey];
            [self addCIImageToCollectionView:noirFilter.outputImage withFilterTitle:NSLocalizedString(@"Noir", @"Noir Filter")];
            
        }
    }];


    //Boom filter
    [self.photoFilterOperationQueue addOperationWithBlock:^{
        CIFilter *boomFilter = [CIFilter filterWithName:@"CIPhotoEffectProcess"];
    
        if (boomFilter) {
            [boomFilter setValue:sourceCIImage forKey:kCIInputImageKey];
            [self addCIImageToCollectionView:boomFilter.outputImage withFilterTitle:NSLocalizedString(@"Coom", @"Coom Filter")];
        }
    }];

    //Warm filter
    [self.photoFilterOperationQueue addOperationWithBlock:^{
        CIFilter *warmFilter = [CIFilter filterWithName:@"CIPhotoEffectTransfer"];
    
        if (warmFilter) {
            [warmFilter setValue:sourceCIImage forKey:kCIInputImageKey];
            [self addCIImageToCollectionView:warmFilter.outputImage withFilterTitle:NSLocalizedString(@"Warm", @"Warm Filter")];
        }
    }];

    //Pixel Filter
    [self.photoFilterOperationQueue addOperationWithBlock:^{
        CIFilter *pixelFilter = [CIFilter filterWithName:@"CIPixellate"];
    
        if (pixelFilter) {
            [pixelFilter setValue:sourceCIImage forKey:kCIInputImageKey];
            [self addCIImageToCollectionView:pixelFilter.outputImage withFilterTitle:NSLocalizedString(@"Pixel", @"Pixel Filter")];
        }
    }];

    //Moody filter
    [self.photoFilterOperationQueue addOperationWithBlock:^{
        CIFilter *moodyFilter = [CIFilter filterWithName:@"CISRGBToneCurveToLinear"];
    
        if (moodyFilter) {
            [moodyFilter setValue:sourceCIImage forKey:kCIInputImageKey];
            [self addCIImageToCollectionView:moodyFilter.outputImage withFilterTitle:NSLocalizedString(@"Moody", @"Moody Filter")];
        }
    }];
    
    //Drunk filter. Uses CIStraightenFilter, which is usually used for straightening, to tilt the image 0.2 radians (about 11.5 degrees). We'll combine this filter with the CIConvolutions5x5 filter to create a blurry double-vision effect
    [self.photoFilterOperationQueue addOperationWithBlock:^ {
        CIFilter *drunkFilter = [CIFilter filterWithName:@"CIConvolutions5x5"];
        CIFilter *tiltFilter = [CIFilter filterWithName:@"CIStraightenFilter"];
        
        if (drunkFilter) {
            [drunkFilter setValue:sourceCIImage forKey:kCIInputImageKey];
            
            CIVector *drunkVector = [CIVector vectorWithString:@"0.5 0 0 0 0 0 0 0 0 0.05 0 0 0 0 0 0 0 0 0 0 0.05 0 0 0 0.5]"];
            
            [drunkFilter setValue:drunkVector forKeyPath:@"inputWeights"];
            
            CIImage *result = drunkFilter.outputImage;
            
            if (tiltFilter) {
                [tiltFilter setValue:result forKeyPath:kCIInputImageKey];
                [tiltFilter setValue:@0.2 forKeyPath:kCIInputAngleKey];
                result = tiltFilter.outputImage;
            }
            
            [self addCIImageToCollectionView:result withFilterTitle:NSLocalizedString(@"Drunk", @"Drunk Filter")];
        }
    }];
    
    //Film filter
    [self.photoFilterOperationQueue addOperationWithBlock:^{
        
        // #1 - Makes a sepia tone version of our source image
        CIFilter *sepiaFilter = [CIFilter filterWithName:@"CISepiaTone"];
        [sepiaFilter setValue:@1 forKey:kCIInputIntensityKey];
        [sepiaFilter setValue:sourceCIImage forKey:kCIInputImageKey];
        
        // #2 - Makes a random image called randomImage. It's output looks like color TV static
        CIFilter *randomFilter = [CIFilter filterWithName:@"CIRandomGenerator"];
        
        CIImage *randomImage = [CIFilter filterWithName:@"CIRandomGenerator"].outputImage;
        
        // #3 - We stretch the image a little bit horizontally and a lot vertically. This second image is called otherRandomImage
        CIImage *otherRandomImage = [randomImage imageByApplyingTransform:CGAffineTransformMakeScale(1.5, 25.0)];
        
        // #4 - Creates two filters, whiteSpecks will extract white specs from randomImage and darkScratches will extract vertical scratches from otherRandomImage
        CIFilter *whiteSpecks = [CIFilter filterWithName:@"CIColorMatrix" keysAndValues:kCIInputImageKey, randomImage,
                                 @"inputRVector", [CIVector vectorWithX:0.0 Y:1.0 Z:0.0 W:0.0],
                                 @"inputGVector", [CIVector vectorWithX:0.0 Y:1.0 Z:0.0 W:0.0],
                                 @"inputBVector", [CIVector vectorWithX:0.0 Y:1.0 Z:0.0 W:0.0],
                                 @"inputAVector", [CIVector vectorWithX:0.0 Y:0.01 Z:0.0 W:0.0],
                                 @"inputBiasVector", [CIVector vectorWithX:0.0 Y:0.0 Z:0.0 W:0.0],
                                 nil];
        
        CIFilter *darkScratches = [CIFilter filterWithName:@"CIColorMatrix" keysAndValues:kCIInputImageKey, otherRandomImage,
                                   @"inputRVector", [CIVector vectorWithX:3.659f Y:0.0 Z:0.0 W:0.0],
                                   @"inputGVector", [CIVector vectorWithX:0.0 Y:0.0 Z:0.0 W:0.0],
                                   @"inputBVector", [CIVector vectorWithX:0.0 Y:0.0 Z:0.0 W:0.0],
                                   @"inputAVector", [CIVector vectorWithX:0.0 Y:0.0 Z:0.0 W:0.0],
                                   @"inputBiasVector", [CIVector vectorWithX:0.0 Y:1.0 Z:1.0 W:1.0],
                                   nil];
        
        // #5 - Create minimumCOmponent and composite which will combine the layers
        CIFilter *minimumComponent = [CIFilter filterWithName:@"CIMinimumComponent"];
        CIFilter *composite = [CIFilter filterWithName:@"CIMultiplyCompositing"];
        
        // #6
        if (sepiaFilter && randomFilter && whiteSpecks && darkScratches && minimumComponent && composite) {
            // #7
            CIImage *sepiaImage = sepiaFilter.outputImage;
            
            // #8
            CIImage *whiteSpecksImage = [whiteSpecks.outputImage imageByCroppingToRect:sourceCIImage.extent];
            
            // #9
            CIImage *sepiaPlusWhiteSpecksImage = [CIFilter filterWithName:@"CISourceOverCompositing" keysAndValues:
                                                  kCIInputImageKey, whiteSpecksImage,
                                                  kCIInputBackgroundImageKey, sepiaImage,
                                                  nil].outputImage;
            
            // #10
            CIImage *darkScratchesImage = [darkScratches.outputImage imageByCroppingToRect:sourceCIImage.extent];
            
            [minimumComponent setValue:darkScratchesImage forKey:kCIInputImageKey];
            darkScratchesImage = minimumComponent.outputImage;
            
            [composite setValue:sepiaPlusWhiteSpecksImage forKey:kCIInputImageKey];
            [composite setValue:darkScratchesImage forKey:kCIInputBackgroundImageKey];
            
            [self addCIImageToCollectionView:composite.outputImage withFilterTitle:NSLocalizedString(@"Film", @"Film Filter")];
        }
    }];

}

//When the send button is pressed, let's check to make sure Instagram is installed, and ask the user if they'd like to write a caption
- (void) sendButtonPressed:(id)sender {
    NSURL *instagramURL = [NSURL URLWithString:@"instagram://location?id=1"];
    
    UIAlertController *alertVC;
    
    if ([[UIApplication sharedApplication] canOpenURL:instagramURL]) {
        alertVC = [UIAlertController alertControllerWithTitle:@"" message:NSLocalizedString(@"Add a caption and send your image in the Instagram ap.", @"send image instructions") preferredStyle:UIAlertControllerStyleAlert];
        
        [alertVC addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = NSLocalizedString(@"Caption", @"Caption");
        }];
        
        [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"cancel button") style:UIAlertActionStyleCancel handler:nil]];
        [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Send", @"Send button") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            
            UITextField *textField = alertVC.textFields[0];
            [self sendImageToInstagramWithCaption:textField.text];
        }]];
    } else {
        alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"No Instagram App", nil) message:NSLocalizedString(@"Add a caption and send your image in the Instagram app.", @"send image instructions") preferredStyle:UIAlertControllerStyleAlert];
        
        [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK button") style:UIAlertActionStyleCancel handler:nil]];
    }
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

//To send the filtered photo to Instagram, we'll build a UIDocementInteractionController. This is similar to the UIActivityViewController class you used earlier (for long-pressing on images in the feed view), but you pass in a file instead of a UIImage. We'll do this work after checking that the OK button was tapped:
- (void) sendImageToInstagramWithCaption:(NSString *)caption {
    NSData *imagedata = UIImageJPEGRepresentation(self.previewImageView.image, 0.9f);
    
    NSURL *tmpDirURL = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
    NSURL *fileURL = [[tmpDirURL URLByAppendingPathComponent:@"blocstagram"]URLByAppendingPathExtension:@"igo"];
    
    BOOL success = [imagedata writeToURL:fileURL atomically:YES];
    
    if (!success) {
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Couldn't save image", nil) message:NSLocalizedString(@"Your cropped and filtered photo couldn't be saved. Make sure you have enough disk space and try again.", nil) preferredStyle:UIAlertControllerStyleAlert];
        [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK button") style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alertVC animated:YES completion:nil];
        return;
    }
    
    self.documentController = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
    self.documentController.UTI = @"com.instagram.exclusivegram";
    self.documentController.delegate = self;
    
    if (caption.length > 0) {
        self.documentController.annotation = @{@"InstagramCaption": caption};
    }
    
    if (self.sendButton.superview) {
        [self.documentController presentOpenInMenuFromRect:self.sendButton.bounds inView:self.sendButton animated:YES];
    } else {
        [self.documentController presentOpenInMenuFromBarButtonItem:self.sendBarButton animated:YES];
    }
    
}
//This process is more complex than UIActivityViewController's because we need to write the file to disk and send the URL of the file to Instagram. We convert the image to NSData, create a file in the temporary directory with the igo ("instagram only") extension and com.instagram.exclusivegram UTI, and initialize and present a UIDocumentInterfactionController with the file.

#pragma mark - UIDocumentInteractionControllerDelegate

//When the document interaction controller finishes, we should dismiss the crop view
- (void)documentInteractionController:(UIDocumentInteractionController *)controller didEndSendingToApplication:(NSString *)application {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
