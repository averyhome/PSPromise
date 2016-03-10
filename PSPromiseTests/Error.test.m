//
//  Error.m
//  PSPromise
//
//  Created by PoiSon on 16/3/4.
//  Copyright © 2016年 PoiSon. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <PSPromise/PSPromise.h>

#define TIME_OUT 1

@interface Error_test : XCTestCase

@end

@implementation Error_test

- (void)testThen1 {
    id ex = [self expectationWithDescription:@""];
    
    PSPromiseWithBlock(^{
        @throw NSErrorMake(nil, @"Error");
    }).then(^{
        XCTAssert(NO, @"这里不应该执行:%@", @"123");
    }).catch(^(NSError *error){
        XCTAssert([error.localizedDescription isEqualToString:@"Error"]);
    }).catch(^{
        XCTAssert(NO, @"这里不应该执行");
    }).always(^{
        [ex fulfill];
    });
    
    [self waitForExpectationsWithTimeout:TIME_OUT handler:nil];
}

- (void)testThen2{
    id ex = [self expectationWithDescription:@""];
    
    PSPromiseWithBlock(^{
        return @"aaa";
    }).thenAsync(^{
        @throw NSErrorMake(nil, @"Error");
    }).then(^{
        XCTAssert(NO, @"这里不应该执行");
        return nil;
    }).catch(^(NSError *error) {
        XCTAssert([error.localizedDescription isEqualToString:@"Error"]);
    }).catch(^(NSError *error){
        XCTAssert(NO, @"这里不应该执行");
    }).always(^{
        [ex fulfill];
    });
    [self waitForExpectationsWithTimeout:TIME_OUT handler:nil];
}

- (void)testThen3{
    id ex = [self expectationWithDescription:@""];
    
    PSPromiseWithBlock(^{
        return @"aaa";
    }).thenPromise(^(id result, PSResolve resolve){
        @throw NSErrorMake(nil, @"Error");
    }).then(^{
        XCTAssert(NO, @"这里不应该执行");
        return nil;
    }).catch(^(NSError *error) {
        XCTAssert([error.localizedDescription isEqualToString:@"Error"]);
    }).catch(^(NSError *error){
        XCTAssert(NO, @"这里不应该执行");
    }).always(^{
        [ex fulfill];
    });
    [self waitForExpectationsWithTimeout:TIME_OUT handler:nil];
}

- (void)testThen4{
    id ex = [self expectationWithDescription:@""];
    
    PSPromiseWithBlock(^{
        return @"aaa";
    }).thenOn(dispatch_get_global_queue(0, 0), ^{
        @throw NSErrorMake(nil, @"Error");
    }).then(^{
        XCTAssert(NO, @"这里不应该执行");
        return nil;
    }).catch(^(NSError *error) {
        XCTAssert([error.localizedDescription isEqualToString:@"Error"]);
    }).catch(^(NSError *error){
        XCTAssert(NO, @"这里不应该执行");
    }).always(^{
        [ex fulfill];
    });
    [self waitForExpectationsWithTimeout:TIME_OUT handler:nil];
}

- (void)testCatch1{
    id ex = [self expectationWithDescription:@""];
    
    PSPromiseWithBlock(^{
        @throw NSErrorMake(nil, @"abc");
    }).catch(^{
        @throw NSErrorMake(nil, @"Error");
    }).then(^{
        XCTAssert(NO, @"这里不应该执行");
        return nil;
    }).catch(^(NSError *error) {
        XCTAssert([error.localizedDescription isEqualToString:@"Error"]);
    }).catch(^(NSError *error){
        XCTAssert(NO, @"这里不应该执行");
    }).always(^{
        [ex fulfill];
    });
    [self waitForExpectationsWithTimeout:TIME_OUT handler:nil];
}

- (void)testCatch2{
    id ex = [self expectationWithDescription:@""];
    
    PSPromiseWithBlock(^{
        @throw NSErrorMake(nil, @"abc");
    }).catchAsync(^{
        @throw NSErrorMake(nil, @"Error");
    }).then(^{
        XCTAssert(NO, @"这里不应该执行");
        return nil;
    }).catch(^(NSError *error) {
        XCTAssert([error.localizedDescription isEqualToString:@"Error"]);
    }).catch(^(NSError *error){
        XCTAssert(NO, @"这里不应该执行");
    }).always(^{
        [ex fulfill];
    });
    [self waitForExpectationsWithTimeout:TIME_OUT handler:nil];
}

- (void)testCatch3{
    id ex = [self expectationWithDescription:@""];
    
    PSPromiseWithBlock(^{
        @throw NSErrorMake(nil, @"abc");
    }).catchOn(dispatch_get_global_queue(0, 0), ^{
        @throw NSErrorMake(nil, @"Error");
    }).then(^{
        XCTAssert(NO, @"这里不应该执行");
        return nil;
    }).catch(^(NSError *error) {
        XCTAssert([error.localizedDescription isEqualToString:@"Error"]);
    }).catch(^(NSError *error){
        XCTAssert(NO, @"这里不应该执行");
    }).always(^{
        [ex fulfill];
    });
    [self waitForExpectationsWithTimeout:TIME_OUT handler:nil];
}

- (void)testAlways{
    id ex = [self expectationWithDescription:@""];
    
    PSPromiseWithBlock(^{
        @throw NSErrorMake(nil, @"abc");
    }).always(^{
        @throw NSErrorMake(nil, @"Error");
    }).then(^{
        XCTAssert(NO, @"这里不应该执行");
        return nil;
    }).catch(^(NSError *error) {
        XCTAssert([error.localizedDescription isEqualToString:@"Error"]);
    }).catch(^(NSError *error){
        XCTAssert(NO, @"这里不应该执行");
    }).always(^{
        [ex fulfill];
    });
    [self waitForExpectationsWithTimeout:TIME_OUT handler:nil];
}

@end
