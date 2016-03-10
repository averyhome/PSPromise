//
//  NSObject+PSPromist.m
//  PSPromise
//
//  Created by PoiSon on 16/2/21.
//  Copyright © 2016年 PoiSon. All rights reserved.
//

#import "PSPromise.h"
#import <libkern/OSAtomic.h>

#define isRejected(obj) [obj isKindOfClass:[NSError class]]
#define isPromise(obj) [obj isKindOfClass:[PSPromise class]]
#define isBlock(obj) [obj isKindOfClass:NSClassFromString(@"NSBlock")]

NSString * const PSPromiseInternalErrorsKey = @"PSPromiseInternalErrorsKey";
NSError *NSErrorMake(id _Nullable internalErrors, NSString *localizedDescription, ...){
    static NSString *domain = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        domain = [NSBundle mainBundle].infoDictionary[@"CFBundleName"];
        domain = domain ?: @"none domain";
    });
    
    va_list desc_args;
    va_start(desc_args, localizedDescription);
    NSString *desc = [[NSString alloc] initWithFormat:localizedDescription arguments:desc_args];
    va_end(desc_args);
    
    return [NSError errorWithDomain:domain code:-1000 userInfo:@{
                                                                 NSLocalizedDescriptionKey: desc,
                                                                 PSPromiseInternalErrorsKey: internalErrors ?: [NSNull null]
                                                                 }];
}

/**
 *  @see CTObjectiveCRuntimeAdditions https://github.com/ebf/CTObjectiveCRuntimeAdditions
 */
struct PSBlockLiteral {
    void *isa; // initialized to &_NSConcreteStackBlock or &_NSConcreteGlobalBlock
    int flags;
    int reserved;
    void (*invoke)(void *, ...);
    struct ps_block_descriptor {
        unsigned long int reserved;	// NULL
        unsigned long int size;         // sizeof(struct Block_literal_1)
        // optional helper functions
        void (*copy_helper)(void *dst, void *src);     // IFF (1<<25)
        void (*dispose_helper)(void *src);             // IFF (1<<25)
        // required ABI.2010.3.16
        const char *signature;                         // IFF (1<<30)
    } *descriptor;
    // imported variables
};

typedef NS_ENUM(NSUInteger, PSBlockDescriptionFlags) {
    PSBlockDescriptionFlagsHasCopyDispose = (1 << 25),
    PSBlockDescriptionFlagsHasCtor = (1 << 26), // helpers have C++ code
    PSBlockDescriptionFlagsIsGlobal = (1 << 28),
    PSBlockDescriptionFlagsHasStret = (1 << 29), // IFF BLOCK_HAS_SIGNATURE
    PSBlockDescriptionFlagsHasSignature = (1 << 30)
};

static NSMethodSignature *_signatureForBlock(id block) {
    if (!block)
        return nil;
    
    struct PSBlockLiteral *blockRef = (__bridge struct PSBlockLiteral *)block;
    PSBlockDescriptionFlags flags = (PSBlockDescriptionFlags)blockRef->flags;
    
    if (flags & PSBlockDescriptionFlagsHasSignature) {
        void *signatureLocation = blockRef->descriptor;
        signatureLocation += sizeof(unsigned long int);
        signatureLocation += sizeof(unsigned long int);
        
        if (flags & PSBlockDescriptionFlagsHasCopyDispose) {
            signatureLocation += sizeof(void (*)(void *dst, void *src));
            signatureLocation += sizeof(void (*)(void *src));
        }
        
        const char *signature = (*(const char **)signatureLocation);
        return [NSMethodSignature signatureWithObjCTypes:signature];
    }
    return nil;
}

static id _call_block(id block, id args){
    NSMethodSignature *signature = _signatureForBlock(block);
    
    const char returnType = signature.methodReturnType[0];
    if (returnType != '@' && returnType != 'v') {
        [NSException raise:NSInvalidArgumentException format:@"PSPromise无法处理非对象返回值，block返回值必须是OC对象"];
    }
    
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:[block copy]];
    if (args && signature.numberOfArguments > 1) {
        [invocation setArgument:&args atIndex:1];
    }
    
    @try {
        [invocation invoke];
        
        if (returnType == 'v') { return nil; }
        __unsafe_unretained id result;
        [invocation getReturnValue:&result];
        return result;
    }
    @catch (NSError *error) {// just catch NSError
        return error;
    }
}

@interface PSPromise()
@property (nonatomic) dispatch_queue_t barrier;
@property (nonatomic, strong) id value;
@property (nonatomic, strong) NSMutableArray<PSResolve> *handlers;
@end

@implementation PSPromise
- (dispatch_queue_t)barrier{
    return _barrier ?: (_barrier = dispatch_queue_create("cn.yerl.promise.barrier", DISPATCH_QUEUE_CONCURRENT));
}

- (NSMutableArray *)handlers{
    return _handlers ?: (_handlers = [NSMutableArray new]);
}

- (instancetype)initWithResolver:(void (^)(PSResolve))resolver{
    if (self = [super init]) {
        _state = PSPromiseStatePending;
        
        PSResolve __presolve = ^(id result){
            __block NSMutableArray *handlers;
            dispatch_barrier_sync(self.barrier, ^{
                //race
                if (self.state == PSPromiseStatePending) {
                    handlers = self.handlers;
                    
                    if (isRejected(result)) {
                        _state = PSPromiseStateRejected;
                    }else{
                        _state = PSPromiseStateFulfilled;
                    }
                    self.value = result;
                }
            });
            for (PSResolve handler in handlers) {
                handler(result);
            }
        };
        
        PSResolve __resolve = ^(id result){
            if (self.state & PSPromiseStatePending) {
                if (isPromise(result)) {
                    [result pipe:__presolve];
                }else{
                    __presolve(result);
                }
            }
        };
        
        dispatch_async(dispatch_get_main_queue(), ^{
            @try {
                resolver(__resolve);
            }
            @catch (NSError *error) {
                __resolve(error);
            }
        });
    }
    return self;
}

- (instancetype)initWithValue:(id)value{
    if (isPromise(value)) {
        return value;
    }
    if (self = [super init]) {
        if (isRejected(value)) {
            _state = PSPromiseStateRejected;
            self.value = value;
        }else{
            _state = PSPromiseStateFulfilled;
            self.value = value;
        }
    }
    return self;
}

- (void)pipe:(PSResolve)resolve{
    if (self.state == PSPromiseStatePending) {
        [self.handlers addObject:resolve];
    }else{
        resolve(self.value);
    }
}

static inline PSPromise *__promisePipe(PSPromise *self, void(^then)(id, PSResolve)){
    return [[PSPromise alloc] initWithResolver:^(PSResolve resolver) {
        [self pipe:^(id result) {
            then(result, resolver);//handle resule of previous promise
        }];
    }];
}

static inline PSPromise *__then(PSPromise *self, dispatch_queue_t queue, id block){
    return __promisePipe(self, ^(id result, PSResolve resolver) {
        if (isRejected(result)) {
            resolver(result);
        }else{
            dispatch_async(queue, ^{
                resolver(_call_block(block, result));
            });
        }
    });
}

static inline PSPromise *__catch(PSPromise *self, dispatch_queue_t queue, id block){
    return __promisePipe(self, ^(id result, PSResolve resolver) {
        if (isRejected(result)) {
            dispatch_async(queue, ^{
                resolver(_call_block(block, result));
            });
        }else{
            resolver(result);
        }
    });
}

@end

@implementation PSPromise (CommonJS)
+ (PSPromise *(^)(id))resolve{
    return ^(id value){
        return [[self alloc] initWithValue:value];
    };
}

+ (PSPromise *(^)(NSArray<PSPromise *> *))all{
    return ^(NSArray<PSPromise *> *promises){
        return [[PSPromise alloc] initWithResolver:^(PSResolve resolve) {
            __block int64_t totalCount = [promises count];
            for (__strong id promise in promises) {
                if (!isPromise(promise)) {
                    promise = PSPromise.resolve(promise);
                }
                [promise pipe:^(id result) {
                    if (isRejected(result)) {
                        resolve([NSError errorWithDomain:@"cn.yerl.promise"
                                                    code:-1000
                                                userInfo:@{NSLocalizedFailureReasonErrorKey: @"one of promise in promises were rejected",
                                                           NSLocalizedDescriptionKey: result}]);
                    }else if (OSAtomicDecrement64(&totalCount) == 0){
                        id results = [NSMutableArray new];
                        for (id promise in promises) {
                            id value = isPromise(promise) ? [promise value] : promise;
                            [results addObject:value ?: [NSNull null]];
                        }
                        resolve(results);
                    }
                }];
            }
        }];
    };
}

+ (PSPromise *(^)(NSArray<PSPromise *> *))race{
    return ^(NSArray<PSPromise *> *promises){
        return [[PSPromise alloc] initWithResolver:^(PSResolve resolve) {
            __block int64_t totalCount = [promises count];
            for (__strong id promise in promises) {
                if (!isPromise(promise)) {
                    promise = [[PSPromise alloc] initWithValue:promise];
                }
                [promise pipe:^(id result) {
                    if (!isRejected(result)) {
                        resolve(result);
                    }else if (OSAtomicDecrement64(&totalCount) == 0){
                        id errors = [NSMutableArray new];
                        for (id promise in promises) {
                            [errors addObject:isPromise(promise) ? [promise value] : promise];
                        }
                        resolve([NSError errorWithDomain:@"cn.yerl.promise"
                                                    code:-1000
                                                userInfo:@{NSLocalizedDescriptionKey: @"all promise were rejected",
                                                           PSPromiseInternalErrorsKey: errors}]);
                    }
                }];
            }
        }];
    };
}

- (PSPromise *(^)(id))then{
    return ^(id block){
        return __then(self, dispatch_get_main_queue(), block);
    };
}

- (PSPromise *(^)(id))catch{
    return ^(id block){
        return __catch(self, dispatch_get_main_queue(), block);
    };
}
@end

@implementation PSPromise (Extension)
- (PSPromise *(^)(id))thenAsync{
    return ^(id block){
        return __then(self, dispatch_get_global_queue(0, 0), block);
    };
}

- (PSPromise *(^)(dispatch_queue_t, id))thenOn{
    return ^(dispatch_queue_t queue, id block){
        return __then(self, queue, block);
    };
}

- (PSPromise * (^)(void (^)(id, PSResolve)))thenPromise{
    return ^(void (^resolver)(id, PSResolve)){
        return __promisePipe(self, ^(id result, PSResolve resolve) {
            if (!isRejected(result)) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    @try {
                        resolver(result, resolve);
                    }
                    @catch (NSError *error) {
                        resolve(error);
                    }
                });
            }else{
                resolve(result);
            }
        });
    };
}

- (PSPromise *(^)(id))catchAsync{
    return ^(id block){
        return __catch(self, dispatch_get_global_queue(0, 0), block);
    };
}

- (PSPromise *(^)(dispatch_queue_t, id))catchOn{
    return ^(dispatch_queue_t queue, id block){
        return __catch(self, queue, block);
    };
}

- (PSPromise *(^)(id))always{
    return ^(id block){
        return __promisePipe(self, ^(id result, PSResolve resolver) {
            dispatch_async(dispatch_get_main_queue(), ^{
                resolver(_call_block(block, result));
            });
        });
    };
}
@end

PSPromise *PSPromiseWithResolve(void (^resolver)(PSResolve)){
    return [[PSPromise alloc] initWithResolver:resolver];
}

PSPromise *PSPromiseWithBlock(id block){
    return PSPromise.resolve(nil).then(block);
}

PSPromise *PSPromiseAsyncWithBlock(id block){
    return PSPromise.resolve(nil).thenAsync(block);
}