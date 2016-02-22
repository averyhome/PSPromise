//
//  Thread.test.m
//  PSPromise
//
//  Created by PoiSon on 16/2/19.
//  Copyright © 2016年 PoiSon. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <PSPromise/PSPromise.h>

@interface Thread_test : XCTestCase

@end

@implementation Thread_test

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)test1{
    id ex1 = [self expectationWithDescription:@""];
    PSPROMISE(^(PSResolve  _Nonnull resolve) {
        XCTAssertEqual([NSThread currentThread].isMainThread, YES);
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)test2{
    id ex1 = [self expectationWithDescription:@""];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        PSPROMISE(^(PSResolve  _Nonnull resolve) {
            XCTAssertEqual([NSThread currentThread].isMainThread, YES);
            [ex1 fulfill];
        });
    });
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
}
- (void)test3{
    id ex1 = [self expectationWithDescription:@""];
    
    PSPROMISE(^(PSResolve  _Nonnull resolve) {
        resolve(@"abc");
    }).then(^(NSString *result){
        XCTAssertEqual([NSThread currentThread].isMainThread, YES);
        [ex1 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
}
- (void)test4{
    id ex1 = [self expectationWithDescription:@""];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        PSPROMISE(^(PSResolve  _Nonnull resolve) {
            resolve(@"abc");
        }).then(^(NSString *result){
            XCTAssertEqual([NSThread currentThread].isMainThread, YES);
            [ex1 fulfill];
        });
    });
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
}
- (void)test5{
    id ex1 = [self expectationWithDescription:@""];
    
    PSPROMISE(^(PSResolve  _Nonnull resolve) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            resolve(@"success");
        });
    }).then(^(NSString *result){
        XCTAssertEqual([NSThread currentThread].isMainThread, YES);
        [ex1 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)test6{
    id ex1 = [self expectationWithDescription:@""];
    
    PSPROMISE(^(PSResolve  _Nonnull resolve) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            resolve([NSError errorWithDomain:@"cn.yerl.promise.error" code:-1000 userInfo:@{NSLocalizedDescriptionKey: @"测试错误"}]);
        });
    }).catch(^(NSError *error){
        XCTAssertEqual([NSThread currentThread].isMainThread, YES);
        [ex1 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
}
- (void)test7{
    id ex1 = [self expectationWithDescription:@""];
    
    PSPROMISE(^(PSResolve  _Nonnull resolve) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            resolve([NSError errorWithDomain:@"cn.yerl.promise.error" code:-1000 userInfo:@{NSLocalizedDescriptionKey: @"测试错误"}]);
        });
    }).finally(^{
        XCTAssertEqual([NSThread currentThread].isMainThread, YES);
        [ex1 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
}
- (void)test8{
    id ex1 = [self expectationWithDescription:@""];
    
    PSPROMISE(^(PSResolve  _Nonnull resolve) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            resolve(@"success");
        });
    }).finally(^{
        XCTAssertEqual([NSThread currentThread].isMainThread, YES);
        [ex1 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

@end
