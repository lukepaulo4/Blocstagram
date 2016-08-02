//
//  MediaTableViewCellTests.m
//  Blocstagram
//
//  Created by Luke Paulo on 8/1/16.
//  Copyright © 2016 Bloc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MediaTableViewCell.h"
#import "Media.h"


@interface MediaTableViewCellTests : XCTestCase

@property (nonatomic, strong) UIImage *testImage;
@property (nonatomic, strong) Media *mediaItem;
@property (nonatomic, strong) UITraitCollection *traitCollector;

@end

@implementation MediaTableViewCellTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


//Set traitCollector. Download your image. Set its download state.
- (void) testHeightsforMediaCell {
    
    self.mediaItem = [[Media alloc] init];
    self.traitCollector = [UITraitCollection traitCollectionWithDisplayScale:1.0];
    self.traitCollector = [UITraitCollection traitCollectionWithHorizontalSizeClass:UIUserInterfaceSizeClassRegular];
    self.traitCollector = [UITraitCollection traitCollectionWithVerticalSizeClass:UIUserInterfaceSizeClassRegular];
    
    NSString *imageURLString = @"http://www.kenrockwell.com/trips/2014-10-yosemite/16/810_2841-full.jpg";
    NSURL *url = [NSURL URLWithString:imageURLString];
    NSData *imageData = [NSData dataWithContentsOfURL:url];
    self.mediaItem.image = [[UIImage alloc] initWithData:imageData scale:1.0];
    self.mediaItem.downloadState = MediaDownloadStateHasImage;
    
    CGFloat mediaItemHeight = [MediaTableViewCell heightForMediaItem:self.mediaItem width:100 traitCollection:self.traitCollector];
    XCTAssertEqual(mediaItemHeight, 810);
    
    
}

//+ (CGFloat) heightForMediaItem:(Media *)mediaItem width:(CGFloat)width traitCollection:(UITraitCollection *) traitCollection {
//    //Make a cell
//    MediaTableViewCell *layoutCell = [[MediaTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"layoutCell"];
//    
//    layoutCell.mediaItem = mediaItem;
//    
//    layoutCell.frame = CGRectMake(0, 0, width, CGRectGetHeight(layoutCell.frame));
//    
//    layoutCell.overrideTraitCollection = traitCollection;
//    
//    [layoutCell setNeedsLayout];
//    [layoutCell layoutIfNeeded];
//    
//    //Get the actual height required for the cell
//    return CGRectGetMaxY(layoutCell.commentView.frame);
//}

@end
