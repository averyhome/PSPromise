//
//  Thread.test.m
//  PSPromise
//
//  Created by PoiSon on 16/2/19.
//  Copyright © 2016年 PoiSon. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <PSPromise/PSPromise.h>
#import "error.h"

@interface Thread_test : XCTestCase

@end

@implementation Thread_test

- (void)test1{
    id ex1 = [self expectationWithDescription:@""];
    PSPromiseWithResolve(^(PSResolve  _Nonnull resolve) {
        XCTAssertEqual([NSThread currentThread].isMainThread, YES);
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)test2{
    id ex1 = [self expectationWithDescription:@""];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        PSPromiseWithResolve(^(PSResolve  _Nonnull resolve) {
            XCTAssertEqual([NSThread currentThread].isMainThread, YES);
            [ex1 fulfill];
        });
    });
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
}
- (void)test3{
    id ex1 = [self expectationWithDescription:@""];
    
    PSPromiseWithResolve(^(PSResolve  _Nonnull resolve) {
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
        PSPromiseWithResolve(^(PSResolve  _Nonnull resolve) {
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
    
    PSPromiseWithResolve(^(PSResolve  _Nonnull resolve) {
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
    
    PSPromiseWithResolve(^(PSResolve  _Nonnull resolve) {
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
    
    PSPromiseWithResolve(^(PSResolve  _Nonnull resolve) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            resolve([NSError errorWithDomain:@"cn.yerl.promise.error" code:-1000 userInfo:@{NSLocalizedDescriptionKey: @"测试错误"}]);
        });
    }).always(^{
        XCTAssertEqual([NSThread currentThread].isMainThread, YES);
        [ex1 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
}
- (void)test8{
    id ex1 = [self expectationWithDescription:@""];
    
    PSPromiseWithResolve(^(PSResolve  _Nonnull resolve) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            resolve(@"success");
        });
    }).always(^{
        XCTAssertEqual([NSThread currentThread].isMainThread, YES);
        [ex1 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)test9{
    id ex1 = [self expectationWithDescription:@""];
    
    PSPromiseWithResolve(^(PSResolve  _Nonnull resolve) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            resolve(@"success");
        });
    }).thenAsync(^{
        XCTAssertEqual([NSThread currentThread].isMainThread, NO);
        [ex1 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)test10{
    id ex1 = [self expectationWithDescription:@""];
    
    dispatch_queue_t queue = dispatch_queue_create("dispatch_test", DISPATCH_QUEUE_PRIORITY_DEFAULT);
    
    PSPromiseWithResolve(^(PSResolve  _Nonnull resolve) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            resolve(@"success");
        });
    }).thenOn(queue, ^{
        dispatch_queue_t current_queuet = dispatch_get_current_queue();
        XCTAssert(strcmp(dispatch_queue_get_label(queue), "dispatch_test") == 0);
        [ex1 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)test11{
    id ex1 = [self expectationWithDescription:@""];
    
    dispatch_queue_t queue = dispatch_queue_create("dispatch_test", DISPATCH_QUEUE_PRIORITY_DEFAULT);
    
    PSPromiseWithResolve(^(PSResolve  _Nonnull resolve) {
        @throw NSErrorWithLocalizedDescription(@"Error");
    }).catchOn(queue, ^{
        dispatch_queue_t current_queuet = dispatch_get_current_queue();
        XCTAssert(strcmp(dispatch_queue_get_label(queue), "dispatch_test") == 0);
        [ex1 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)test12{
    id ex1 = [self expectationWithDescription:@""];
    
    dispatch_queue_t queue = dispatch_queue_create("dispatch_test", DISPATCH_QUEUE_PRIORITY_DEFAULT);
    
    PSPromiseWithResolve(^(PSResolve  _Nonnull resolve) {
        @throw NSErrorWithLocalizedDescription(@"Error");
    }).catchAsync(^{
        XCTAssertEqual([NSThread currentThread].isMainThread, NO);
        [ex1 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
}
@end
