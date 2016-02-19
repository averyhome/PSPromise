//
//  PSPromise.h
//  PSPromise
//
//  Created by PoiSon on 16/2/15.
//  Copyright © 2016年 PoiSon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PSPromise/PSPromiseContext.h>

typedef void (^PSResolver)(id __nullable result);

NS_ASSUME_NONNULL_BEGIN
/**
 *  PSPromise可以在当前线程处理单个block，也可以处理多个Promise的集合，直至集合中所有的Promise完成后才继续处理
 */
FOUNDATION_EXPORT PSPromiseContext *PSPromise(id __nullable block);

/**
 *  PSSyncPromise用于在同步线程中执行任务
 */
FOUNDATION_EXPORT PSPromiseContext *PSSyncPromise(void (^)(PSResolver resolver));

/**
 *  PSAsyncPromise用于在异步线程中执行任务
 */
FOUNDATION_EXPORT PSPromiseContext *PSAsyncPromise(void (^)(PSResolver resolver));
NS_ASSUME_NONNULL_END