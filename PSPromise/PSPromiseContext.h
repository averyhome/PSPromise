//
//  PSPromiseContext.h
//  PSPromise
//
//  Created by PoiSon on 16/2/15.
//  Copyright © 2016年 PoiSon. All rights reserved.
//

#import <Foundation/Foundation.h>

#define PSPROMISE_API_UNAVAILABLE(INFO) __attribute__((unavailable(INFO)))

NS_ASSUME_NONNULL_BEGIN
typedef void (^PSResolver)(id __nullable result);

@interface PSPromiseContext : NSObject
- (instancetype)init PSPROMISE_API_UNAVAILABLE("不允许直接实例化");
+ (instancetype)new PSPROMISE_API_UNAVAILABLE("不允许直接实例化");

- (PSPromiseContext *(^)(id block))then;/**< then do somthing on privious promise thread. */
- (PSPromiseContext *(^)(id block))thenSync;/**< then do something on main thread. */
- (PSPromiseContext *(^)(id block))thenAsync;/**< then do somthing on globle thread. */
- (PSPromiseContext *(^)(void (^block)(id result, PSResolver resolver)))thenSyncWithResolver;
- (PSPromiseContext *(^)(void (^block)(id result, PSResolver resolver)))thenAsyncWithResolver;
- (PSPromiseContext *(^)(dispatch_queue_t queue, id block))thenOn;/**< then do something on specify thread. */

- (PSPromiseContext *(^)(id block))finally;/**< finally do something on main thread. */
- (PSPromiseContext *(^)(dispatch_queue_t queue, id block))finallyOn;/**< finally on something on specify thread. */

- (PSPromiseContext *(^)(id block))catch;/**< handle error on main thread. */

@property (nonatomic, readonly) id value;/**< final result of promise. return nil if promise not completed. */
@end

NS_ASSUME_NONNULL_END