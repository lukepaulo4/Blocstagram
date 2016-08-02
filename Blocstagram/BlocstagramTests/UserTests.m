//
//  UserTests.m
//  Blocstagram
//
//  Created by Luke Paulo on 8/1/16.
//  Copyright © 2016 Bloc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "User.h"

@interface UserTests : XCTestCase

@end

@implementation UserTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


//This method makes an NSDictionary that mimics the relevant portion of the JSON response from the Instagram API. This dictionary is passed to [User -initWithDictionary:]. After the user is created, we then assert that the testUser' four properties (idNumber, userName, fullName, and profilePictureURL) are what we expect them to be. If any of these assertions are false, the test fails. If they're all true, the test passes. The XCTAssertEqualObjects sends an isEqual. There are alos ones for True, Fail, NotNil. There is a full list linked in checkpoint 45.
- (void)testThatInitializationWorks {
    NSDictionary *sourceDictionary = @{@"id": @"8675309",
                                       @"username" : @"d'oh",
                                       @"full_name" : @"Homer Simpson",
                                       @"profile_picture" : @"http://www.example.com/example.jpg"};
    User *testUser = [[User alloc] initWithDictionary:sourceDictionary];
    
    XCTAssertEqualObjects(testUser.idNumber, sourceDictionary[@"id"], @"The ID number should be equal");
    XCTAssertEqualObjects(testUser.userName, sourceDictionary[@"username"], @"Theusername should be equal");
    XCTAssertEqualObjects(testUser.fullName, sourceDictionary[@"full_name"], @"The full name should be equal");
    XCTAssertEqualObjects(testUser.profilePictureURL, [NSURL URLWithString:sourceDictionary[@"profile_picture"]], @"The profile picture should be equal");
}


@end
