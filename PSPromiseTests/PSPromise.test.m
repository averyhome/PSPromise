//
//  PSPromiseTests.m
//  PSPromiseTests
//
//  Created by PoiSon on 16/2/15.
//  Copyright © 2016年 PoiSon. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <PSPromise/PSPromise.h>

@interface PSPromiseTests : XCTestCase

@end

@implementation PSPromiseTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testPromiseArray{
    id ex1 = [self expectationWithDescription:@""];
    
    NSMutableArray *array = [NSMutableArray new];
    [array addObject:@"1"];
    
    [array addObject:PSAsyncPromise(^(PSResolver  _Nonnull resolver) {
        XCTAssertEqual([NSThread currentThread].isMainThread, NO);
        resolver(@"thread1");
    })];
    
    [array addObject:PSSyncPromise(^(PSResolver  _Nonnull resolver) {
        XCTAssertEqual([NSThread currentThread].isMainThread, YES);
        resolver(@"thread2");
    })];

    PSPromise(array).then(^(NSArray *result){
        BOOL isEqual = [result isEqualToArray:@[@"1", @"thread1", @"thread2"]];
        XCTAssert(isEqual);
        [ex1 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testPromiseBlock{
    id ex1 = [self expectationWithDescription:@""];
    PSAsyncPromise(^(PSResolver  _Nonnull resolver) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            resolver(@"AsyncTask completed");
        });
    }).then(^(NSString *result){
        XCTAssert([result isEqualToString:@"AsyncTask completed"]);
        [ex1 fulfill];
    }).catch(^(NSError *error){
        XCTAssert(NO, @"这里不该执行");
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testPromiseError{
    id ex1 = [self expectationWithDescription:@""];
    PSAsyncPromise(^(PSResolver  _Nonnull resolver) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            resolver([NSError errorWithDomain:@"promise" code:-1000 userInfo:@{NSLocalizedDescriptionKey: @"发生错误了"}]);
        });
    }).then(^(NSString *result){
        XCTAssert(NO, @"这里不该执行");
    }).catch(^(NSError *error){
        XCTAssert(error!= nil);
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testThen{
    id ex1 = [self expectationWithDescription:@""];
    PSPromise(@"123").then(^(NSString *result){
        XCTAssert([result isEqualToString:@"123"]);
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testThenSync{
    id ex1 = [self expectationWithDescription:@""];
    PSPromise(@"123").thenSync(^(NSString *result){
        XCTAssert([result isEqualToString:@"123"]);
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testThenAsync{
    id ex1 = [self expectationWithDescription:@""];
    PSPromise(@"123").thenAsync(^(NSString *result){
        XCTAssert([result isEqualToString:@"123"]);
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testThenSyncWithResolver{
    id ex1 = [self expectationWithDescription:@""];
    PSPromise(@"123").thenSyncWithResolver(^(NSString *result, PSResolver resolver){
        resolver([result stringByAppendingString:@"abc"]);
    }).then(^(NSString *result){
        XCTAssert([result isEqualToString:@"123abc"]);
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testThenAsyncWithResolver{
    id ex1 = [self expectationWithDescription:@""];
    PSPromise(@"123").thenAsyncWithResolver(^(NSString *result, PSResolver resolver){
        resolver([result stringByAppendingString:@"abc"]);
    }).then(^(NSString *result){
        XCTAssert([result isEqualToString:@"123abc"]);
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}
@end
