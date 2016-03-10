//
//  PSPromiseTests.m
//  PSPromiseTests
//
//  Created by PoiSon on 16/2/15.
//  Copyright © 2016年 PoiSon. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <PSPromise/PSPromise.h>

#define TIME_OUT 1

@interface PSPromise_test : XCTestCase

@end

@implementation PSPromise_test

- (void)testPromiseBlock{
    id ex1 = [self expectationWithDescription:@""];
    PSPromiseWithResolve(^(PSResolve  _Nonnull resolve) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            resolve(@"AsyncTask completed");
        });
    }).then(^(NSString *result){
        XCTAssert([result isEqualToString:@"AsyncTask completed"]);
        [ex1 fulfill];
    }).catch(^{
        XCTAssert(NO, @"这里不该执行");
    });
    [self waitForExpectationsWithTimeout:TIME_OUT handler:nil];
}

- (void)testPromiseError{
    id ex1 = [self expectationWithDescription:@""];
    
    PSPromiseWithResolve(^(PSResolve  _Nonnull resolve) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            resolve(NSErrorMake(nil, @"发生错误了"));
        });
    }).then(^{
        XCTAssert(NO, @"这里不该执行");
    }).catch(^(NSError *error){
        XCTAssert(error!= nil);
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:TIME_OUT handler:nil];
}

- (void)testThen{
    id ex1 = [self expectationWithDescription:@""];
    PSPromise.resolve(@"123").then(^(NSString *result){
        XCTAssert([result isEqualToString:@"123"]);
    }).then(^(NSString *result){
        XCTAssert(result == nil);
        return @"123";
    }).then(^(NSString *result){
        return [result stringByAppendingString:@"123"];
    }).then(^(NSString *result){
        XCTAssert([result isEqualToString:@"123123"]);
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:TIME_OUT handler:nil];
}

- (void)testThen2{
    id ex1 = [self expectationWithDescription:@""];
    PSPromiseWithResolve(^(PSResolve  _Nonnull resolve) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            resolve(@"AsyncTask completed");
        });
    }).then(^(NSString *result){
        XCTAssert([result isEqualToString:@"AsyncTask completed"]);
        return PSPromiseWithResolve(^(PSResolve  _Nonnull resolve) {
            resolve([result stringByAppendingString:@"123"]);
        }).then(^{
            return @"123";
        });
    }).then(^(NSString *result){
        XCTAssert([result isEqualToString:@"123"]);
    }).catch(^{
        XCTAssert(NO, @"这里不该执行");
    }).always(^{
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:TIME_OUT handler:nil];
}

- (void)testFinally1{
    id ex1 = [self expectationWithDescription:@""];
    PSPromiseWithResolve(^(PSResolve  _Nonnull resolve) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            resolve(@"AsyncTask completed");
        });
    }).then(^(NSString *result){
        XCTAssert([result isEqualToString:@"AsyncTask completed"]);
    }).catch(^{
        XCTAssert(NO, @"这里不该执行");
    }).always(^{
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:TIME_OUT handler:nil];
}

- (void)testFinally2{
    id ex1 = [self expectationWithDescription:@""];
    PSPromiseWithResolve(^(PSResolve  _Nonnull resolve) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            resolve(NSErrorMake(nil, @"发生错误了"));
        });
    }).then(^{
        XCTAssert(NO, @"这里不该执行");
    }).catch(^(NSError *error){
        XCTAssert(error!= nil);
    }).always(^{
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:TIME_OUT handler:nil];
}

- (void)testFinally3{
    id ex1 = [self expectationWithDescription:@""];
    PSPromiseWithResolve(^(PSResolve  _Nonnull resolve) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            resolve(@"AsyncTask completed");
        });
    }).then(^(NSString *result){
        XCTAssert([result isEqualToString:@"AsyncTask completed"]);
        return PSPromiseWithResolve(^(PSResolve  _Nonnull resolve) {
            resolve([result stringByAppendingString:@"123"]);
        }).then(^{
            return @"123";
        });
    }).catch(^{
        XCTAssert(NO, @"这里不该执行");
    }).always(^{
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:TIME_OUT handler:nil];
}

- (void)testPipe{
    id ex1 = [self expectationWithDescription:@"expectation"];
    PSPromiseWithResolve(^(PSResolve  _Nonnull resolve) {
        resolve(@"123");
    }).then(^(NSString *result){
        return PSPromiseWithResolve(^(PSResolve  _Nonnull resolve) {
            resolve([result stringByAppendingString:@"123"]);
        });
    }).then(^(NSString *result){
        XCTAssert([result isEqualToString:@"123123"]);
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:TIME_OUT handler:nil];
}

- (void)testPromiseAll{
    id ex1 = [self expectationWithDescription:@""];
    
    PSPromise *p1 = PSPromiseWithResolve(^(PSResolve  _Nonnull resolve) {
        XCTAssertEqual([NSThread currentThread].isMainThread, YES);
        resolve(@"thread1");
    });
    
    PSPromise *p2 = PSPromiseWithResolve(^(PSResolve  _Nonnull resolve) {
        XCTAssertEqual([NSThread currentThread].isMainThread, YES);
        resolve(@"thread2");
    });
    
    PSPromise.all(@[@"1", p1, p2]).then(^(NSArray<NSString *> *result){
        BOOL isEqual = [result isEqualToArray:@[@"1", @"thread1", @"thread2"]];
        XCTAssert(isEqual);
        [ex1 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:TIME_OUT handler:nil];
}

- (void)testPromiseRace{
    id ex1 = [self expectationWithDescription:@""];
    
    PSPromise *p1 = PSPromiseWithResolve(^(PSResolve  _Nonnull resolve) {
        XCTAssertEqual([NSThread currentThread].isMainThread, YES);
        resolve(@"thread1");
    });
    
    PSPromise *p2 = PSPromiseWithResolve(^(PSResolve  _Nonnull resolve) {
        XCTAssertEqual([NSThread currentThread].isMainThread, YES);
        resolve(@"thread2");
    });
    
    PSPromise.race(@[@"1", p1, p2]).then(^(NSString *result){
        XCTAssert([result isKindOfClass:[NSString class]]);
        XCTAssert([result isEqualToString:@"1"]);
        [ex1 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:TIME_OUT handler:nil];
}

- (void)testThenPromise{
    id ex1 = [self expectationWithDescription:@""];
    
    PSPromiseWithResolve(^(PSResolve  _Nonnull resolve) {
        resolve(@"1");
    }).thenPromise(^(NSString *result, PSResolve resolve){
        XCTAssert([result isEqualToString:@"1"]);
        resolve(@"2");
    }).then(^(NSString *result){
        XCTAssert([result isEqualToString:@"2"]);
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:TIME_OUT handler:nil];
}

- (void)testDelay{
    id ex1 = [self expectationWithDescription:@""];
    PSPromiseWithResolve(^(PSResolve  _Nonnull resolve) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            resolve(NSErrorMake(nil, @"发生错误了"));
        });
        resolve(@YES);
    }).then(^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [ex1 fulfill];
        });
    }).catch(^(NSError *error){
        XCTAssert(NO, @"这里不应该执行");
    });
    [self waitForExpectationsWithTimeout:TIME_OUT handler:nil];
}
@end
