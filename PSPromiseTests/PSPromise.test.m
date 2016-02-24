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

- (void)testPromiseBlock{
    id ex1 = [self expectationWithDescription:@""];
    PSPROMISE(^(PSResolve  _Nonnull resolve) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            resolve(@"AsyncTask completed");
        });
    }).then(^(NSString *result){
        XCTAssert([result isEqualToString:@"AsyncTask completed"]);
        [ex1 fulfill];
    }).catch(^{
        XCTAssert(NO, @"这里不该执行");
    });
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testPromiseError{
    id ex1 = [self expectationWithDescription:@""];
    
    PSPROMISE(^(PSResolve  _Nonnull resolve) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            resolve([NSError errorWithDomain:@"promise" code:-1000 userInfo:@{NSLocalizedDescriptionKey: @"发生错误了"}]);
        });
    }).then(^{
        XCTAssert(NO, @"这里不该执行");
    }).catch(^(NSError *error){
        XCTAssert(error!= nil);
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:10 handler:nil];
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
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testThen2{
    id ex1 = [self expectationWithDescription:@""];
    PSPROMISE(^(PSResolve  _Nonnull resolve) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            resolve(@"AsyncTask completed");
        });
    }).then(^(NSString *result){
        XCTAssert([result isEqualToString:@"AsyncTask completed"]);
        return PSPROMISE(^(PSResolve  _Nonnull resolve) {
            resolve([result stringByAppendingString:@"123"]);
        }).then(^{
            return @"123";
        });
    }).then(^(NSString *result){
        XCTAssert([result isEqualToString:@"123"]);
    }).catch(^{
        XCTAssert(NO, @"这里不该执行");
    }).finally(^{
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testFinally1{
    id ex1 = [self expectationWithDescription:@""];
    PSPROMISE(^(PSResolve  _Nonnull resolve) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            resolve(@"AsyncTask completed");
        });
    }).then(^(NSString *result){
        XCTAssert([result isEqualToString:@"AsyncTask completed"]);
    }).catch(^{
        XCTAssert(NO, @"这里不该执行");
    }).finally(^{
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testFinally2{
    id ex1 = [self expectationWithDescription:@""];
    PSPROMISE(^(PSResolve  _Nonnull resolve) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            resolve([NSError errorWithDomain:@"promise" code:-1000 userInfo:@{NSLocalizedDescriptionKey: @"发生错误了"}]);
        });
    }).then(^{
        XCTAssert(NO, @"这里不该执行");
    }).catch(^(NSError *error){
        XCTAssert(error!= nil);
    }).finally(^{
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testFinally3{
    id ex1 = [self expectationWithDescription:@""];
    PSPROMISE(^(PSResolve  _Nonnull resolve) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            resolve(@"AsyncTask completed");
        });
    }).then(^(NSString *result){
        XCTAssert([result isEqualToString:@"AsyncTask completed"]);
        return PSPROMISE(^(PSResolve  _Nonnull resolve) {
            resolve([result stringByAppendingString:@"123"]);
        }).then(^{
            return @"123";
        });
    }).catch(^{
        XCTAssert(NO, @"这里不该执行");
    }).finally(^{
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testPipe{
    id ex1 = [self expectationWithDescription:@"expectation"];
    PSPROMISE(^(PSResolve  _Nonnull resolve) {
        resolve(@"123");
    }).then(^(NSString *result){
        return PSPROMISE(^(PSResolve  _Nonnull resolve) {
            resolve([result stringByAppendingString:@"123"]);
        });
    }).then(^(NSString *result){
        XCTAssert([result isEqualToString:@"123123"]);
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testPromiseAll{
    id ex1 = [self expectationWithDescription:@""];
    
    PSPromise *p1 = PSPROMISE(^(PSResolve  _Nonnull resolve) {
        XCTAssertEqual([NSThread currentThread].isMainThread, YES);
        resolve(@"thread1");
    });
    
    PSPromise *p2 = PSPROMISE(^(PSResolve  _Nonnull resolve) {
        XCTAssertEqual([NSThread currentThread].isMainThread, YES);
        resolve(@"thread2");
    });
    
    PSPromise.all(@[@"1", p1, p2]).then(^(NSArray<NSString *> *result){
        BOOL isEqual = [result isEqualToArray:@[@"1", @"thread1", @"thread2"]];
        XCTAssert(isEqual);
        [ex1 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testPromiseRace{
    id ex1 = [self expectationWithDescription:@""];
    
    PSPromise *p1 = PSPROMISE(^(PSResolve  _Nonnull resolve) {
        XCTAssertEqual([NSThread currentThread].isMainThread, YES);
        resolve(@"thread1");
    });
    
    PSPromise *p2 = PSPROMISE(^(PSResolve  _Nonnull resolve) {
        XCTAssertEqual([NSThread currentThread].isMainThread, YES);
        resolve(@"thread2");
    });
    
    PSPromise.race(@[@"1", p1, p2]).then(^(NSString *result){
        XCTAssert([result isKindOfClass:[NSString class]]);
        XCTAssert([result isEqualToString:@"1"]);
        [ex1 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testThenPromise{
    id ex1 = [self expectationWithDescription:@""];
    
    PSPROMISE(^(PSResolve  _Nonnull resolve) {
        resolve(@"1");
    }).thenPromise(^(NSString *result, PSResolve resolve){
        XCTAssert([result isEqualToString:@"1"]);
        resolve(@"2");
    }).then(^(NSString *result){
        XCTAssert([result isEqualToString:@"2"]);
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:10 handler:nil];
}
@end
