//
//  Error.m
//  PSPromise
//
//  Created by PoiSon on 16/3/4.
//  Copyright © 2016年 PoiSon. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <PSPromise/PSPromise.h>

@interface Error_test : XCTestCase

@end

NSError *NSErrorWithLocalizedDescription(NSString *description){
    return [NSError errorWithDomain:@"cn.yerl.Promise" code:-1000 userInfo:@{NSLocalizedDescriptionKey: description}];
}

@implementation Error_test

- (void)test1 {
    id ex = [self expectationWithDescription:@""];
    
    PSPromiseWithBlock(^{
        @throw NSErrorWithLocalizedDescription(@"Error");
    }).then(^{
        XCTAssert(NO, @"这里不应该执行");
    }).catch(^(NSError *error){
        XCTAssert([error.localizedDescription isEqualToString:@"Error"]);
        [ex fulfill];
    });
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
}


@end
