//
//  CommentViewTest.m
//  Blocstagram
//
//  Created by Luke Paulo on 8/1/16.
//  Copyright © 2016 Bloc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ComposeCommentView.h"

@interface CommentViewTest : XCTestCase

@end

@implementation CommentViewTest

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

//Set the test so that if the string is equal to the created object string, it passes
- (void)testThatIsWritingCommentWorksForText {
    NSString *text = @"tryer";
    ComposeCommentView *testMeHarder = [[ComposeCommentView alloc] init];
    testMeHarder.text = text;
    XCTAssertTrue(testMeHarder.isWritingComment == TRUE, "Passed");
}

//Set the test so that if the created obejct string is nada, the test fails
- (void)testThatIsWritingCommentFailsForNada {
    NSString *text = @"";
    ComposeCommentView *testMeEvenHarder = [[ComposeCommentView alloc] init];
    testMeEvenHarder.text = text;
    XCTAssertTrue(testMeEvenHarder.isWritingComment == FALSE, "Passed");
}

@end
