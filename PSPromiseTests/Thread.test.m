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
    PSPromise(^{
        XCTAssertEqual([NSThread currentThread].isMainThread, YES);
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test2{
    id ex1 = [self expectationWithDescription:@""];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        PSPromise(^{
            XCTAssertEqual([NSThread currentThread].isMainThread, NO);
            [ex1 fulfill];
        });
    });
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}
- (void)test3{
    id ex1 = [self expectationWithDescription:@""];
    
    PSSyncPromise(^(PSResolver  _Nonnull resolver) {
        XCTAssertEqual([NSThread currentThread].isMainThread, YES);
        [ex1 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}
- (void)test4{
    id ex1 = [self expectationWithDescription:@""];
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        PSSyncPromise(^(PSResolver  _Nonnull resolver) {
            XCTAssertEqual([NSThread currentThread].isMainThread, YES);
            [ex1 fulfill];
        });
    });
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}
- (void)test5{
    id ex1 = [self expectationWithDescription:@""];
    
    PSAsyncPromise(^(PSResolver  _Nonnull resolver) {
        XCTAssertEqual([NSThread currentThread].isMainThread, NO);
        [ex1 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}
- (void)test6{
    id ex1 = [self expectationWithDescription:@""];
    dispatch_async(dispatch_get_main_queue(), ^{
        PSAsyncPromise(^(PSResolver  _Nonnull resolver) {
            XCTAssertEqual([NSThread currentThread].isMainThread, NO);
            [ex1 fulfill];
        });
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}
- (void)test7{
    id ex1 = [self expectationWithDescription:@""];
    
    PSSyncPromise(^(PSResolver  _Nonnull resolver) {
        resolver(nil);
    }).then(^{
        XCTAssertEqual([NSThread currentThread].isMainThread, YES);
        [ex1 fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1 handler:nil];
}
- (void)test8{
    id ex1 = [self expectationWithDescription:@""];
    PSSyncPromise(^(PSResolver  _Nonnull resolver) {
        resolver(nil);
    }).thenSync(^{
        XCTAssertEqual([NSThread currentThread].isMainThread, YES);
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}
- (void)test9{
    id ex1 = [self expectationWithDescription:@""];
    PSSyncPromise(^(PSResolver  _Nonnull resolver) {
        resolver(nil);
    }).thenAsync(^{
        XCTAssertEqual([NSThread currentThread].isMainThread, NO);
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}
- (void)test10{
    id ex1 = [self expectationWithDescription:@""];
    dispatch_queue_t queue = dispatch_queue_create("cn.yerl.promise.thread", DISPATCH_QUEUE_CONCURRENT);
    
    PSSyncPromise(^(PSResolver  _Nonnull resolver) {
        resolver(nil);
    }).thenOn(queue, ^{
        XCTAssert([@(dispatch_queue_get_label(dispatch_get_current_queue())) isEqualToString:@"cn.yerl.promise.thread"]);
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}
- (void)test11{
    id ex1 = [self expectationWithDescription:@""];
    PSAsyncPromise(^(PSResolver  _Nonnull resolver) {
        resolver(nil);
    }).then(^{
        XCTAssertEqual([NSThread currentThread].isMainThread, NO);
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}
- (void)test12{
    id ex1 = [self expectationWithDescription:@""];
    PSAsyncPromise(^(PSResolver  _Nonnull resolver) {
        resolver(nil);
    }).thenSync(^{
        XCTAssertEqual([NSThread currentThread].isMainThread, YES);
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}
- (void)test13{
    id ex1 = [self expectationWithDescription:@""];
    PSAsyncPromise(^(PSResolver  _Nonnull resolver) {
        resolver(nil);
    }).thenAsync(^{
        XCTAssertEqual([NSThread currentThread].isMainThread, NO);
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}
- (void)test14{
    id ex1 = [self expectationWithDescription:@""];
    PSSyncPromise(^(PSResolver  _Nonnull resolver) {
        resolver(nil);
    }).finally(^{
        XCTAssertEqual([NSThread currentThread].isMainThread, YES);
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}- (void)test15{
    id ex1 = [self expectationWithDescription:@""];
    dispatch_queue_t queue = dispatch_queue_create("cn.yerl.promise.thread", DISPATCH_QUEUE_CONCURRENT);
    PSSyncPromise(^(PSResolver  _Nonnull resolver) {
        resolver(nil);
    }).finallyOn(queue, ^{
        XCTAssert([@(dispatch_queue_get_label(dispatch_get_current_queue())) isEqualToString:@"cn.yerl.promise.thread"]);
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}
- (void)test16{
    id ex1 = [self expectationWithDescription:@""];
    PSAsyncPromise(^(PSResolver  _Nonnull resolver) {
        resolver(nil);
    }).finally(^{
        XCTAssertEqual([NSThread currentThread].isMainThread, YES);
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}
- (void)test17{
    id ex1 = [self expectationWithDescription:@""];
    PSAsyncPromise(^(PSResolver  _Nonnull resolver) {
        resolver([NSError errorWithDomain:@"cn.yerl.promise" code:-1000 userInfo:@{}]);
    }).catch(^{
        XCTAssertEqual([NSThread currentThread].isMainThread, YES);
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)test18{
    id ex1 = [self expectationWithDescription:@""];
    PSSyncPromise(^(PSResolver  _Nonnull resolver) {
        resolver([NSError errorWithDomain:@"cn.yerl.promise" code:-1000 userInfo:@{}]);
    }).catch(^{
        XCTAssertEqual([NSThread currentThread].isMainThread, YES);
        [ex1 fulfill];
    });
    [self waitForExpectationsWithTimeout:1 handler:nil];
}
@end
