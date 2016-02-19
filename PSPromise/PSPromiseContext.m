//
//  PSPromiseContext.m
//  PSPromise
//
//  Created by PoiSon on 16/2/15.
//  Copyright © 2016年 PoiSon. All rights reserved.
//

#import "PSPromiseContext.h"
#import "PSPromise.h"
#import <libkern/OSAtomic.h>

typedef NS_ENUM(NSUInteger, PSPromiseState) {
    PSPromiseStatePedding,
    PSPromiseStateSealed
};

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

@interface PSPromiseContext ()
@property (nonatomic, assign) PSPromiseState state;/**< whether promise is sealed. */

@property (nonatomic, strong) id result;/**< Sealed result */
@property (nonatomic, strong) NSMutableArray *handlers;/**< Pedding Handlers */

@property (nonatomic) dispatch_queue_t barrier;
@end

@implementation PSPromiseContext
- (dispatch_queue_t)barrier{
    return _barrier ?: (_barrier = dispatch_queue_create("cn.yerl.promise.barrier", DISPATCH_QUEUE_CONCURRENT));
}

- (NSMutableArray *)handlers{
    return _handlers ?: (_handlers = [NSMutableArray new]);
}

- (instancetype)initWithResolver:(void (^)(PSResolver))resolver{
    if (self = [super init]) {
        self.state = PSPromiseStatePedding;
        //presolver
        PSResolver __presolver = ^(id obj){
            __block NSMutableArray *handlers;
            dispatch_barrier_sync(self.barrier, ^{
                if (self.state == PSPromiseStatePedding) {
                    handlers = self.handlers;
                    
                    self.state = PSPromiseStateSealed;
                    self.result = obj;
                }
            });
            for (id handler in handlers) {
                _call_block(handler, obj);
            }
            [handlers removeAllObjects];
        };
        //real resolver
        PSResolver __resolver = ^(id result){
            if ([result isKindOfClass:[PSPromiseContext class]]) {
                [result pipe:__presolver];
            } else {
                __presolver(result);
            }
        };
        resolver(__resolver);
    }
    return self;
}

- (instancetype)initWithValue:(id)value{
    if (self = [super init]) {
        self.state = PSPromiseStateSealed;
        self.result = value;
    }
    return self;
}

- (void)pipe:(void (^)(id))handler{
    if (self.state == PSPromiseStatePedding) {
        [self.handlers addObject:handler];
    }else{
        handler(self.result);
    }
}

#pragma mark - then
- (PSPromiseContext * (^)(id block))then{
    return ^(id block){
        return __then(self, nil, block);
    };
}

- (PSPromiseContext * (^)(id block))thenSync{
    return ^(id block){
        return __then(self, dispatch_get_main_queue(), block);
    };
}

- (PSPromiseContext * (^)(id block))thenAsync{
    return ^(id block){
        return __then(self, dispatch_get_global_queue(0, 0), block);
    };
}

- (PSPromiseContext * (^)(dispatch_queue_t queue, id block))thenOn{
    return ^(dispatch_queue_t queue, id block){
        return __then(self, queue, block);
    };
}

static inline PSPromiseContext *__then(PSPromiseContext *self, dispatch_queue_t queue, id block){
    return ContextWith(self, ^(id obj, PSResolver resolver) {
        if ([obj isKindOfClass:[NSError class]]) {
            resolver(obj);
        }else{
            if (queue) {
                dispatch_async(queue, ^{
                    resolver(_call_block(block, obj));
                });
            }else{
                resolver(_call_block(block, obj));
            }
        }
    });
};

- (PSPromiseContext * (^)(void (^)(id, PSResolver)))thenAsyncWithResolver{
    return ^(void (^promise)(id, PSResolver)){
        return PSAsyncPromise(^(PSResolver resolver) {
            [self pipe:^(id result) {
                promise(result, resolver);
            }];
        });
    };
}

- (PSPromiseContext * (^)(void (^)(id, PSResolver)))thenSyncWithResolver{
    return ^(void (^promise)(id, PSResolver)){
        return PSSyncPromise(^(PSResolver resolver) {
            [self pipe:^(id result) {
                promise(result, resolver);
            }];
        });
    };
}

#pragma mark - catch
- (PSPromiseContext * (^)(id block))catch{
    return ^(id block){
        return __catch(self, dispatch_get_main_queue(), block);
    };
}

static inline PSPromiseContext *__catch(PSPromiseContext *self, dispatch_queue_t queue, id block){
    return ContextWith(self, ^(id obj, PSResolver resolver) {
        if ([obj isKindOfClass:[NSError class]]) {
            dispatch_async(queue, ^{
                resolver(_call_block(block, obj));
            });
        }else{
            resolver(obj);
        }
    });
}

#pragma mark - finally
- (PSPromiseContext * _Nonnull (^)(id _Nonnull))finally{
    return ^(id block){
        return __finally(self, dispatch_get_main_queue(), block);
    };
}

- (PSPromiseContext * (^)(dispatch_queue_t, id))finallyOn{
    return ^(dispatch_queue_t queue, id block){
        return __finally(self, queue, block);
    };
}

static inline PSPromiseContext *__finally(PSPromiseContext *self, dispatch_queue_t queue, id block){
    return ContextWith(self, ^(id obj, PSResolver resolver) {
        dispatch_async(queue, ^{
            _call_block(block, nil);
            resolver(obj);
        });
    });
}

static inline PSPromiseContext *ContextWith(PSPromiseContext *context, void(^then)(id, PSResolver)){
    return [[PSPromiseContext alloc] initWithResolver:^(PSResolver resolver) {
        [context pipe:^(id obj) {
            then(obj, resolver);//handle resule of previous promise with context
        }];
    }];
}
#pragma mark - block caller
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
    @catch (id error) {
        return _warp_error(error);
    }
}

#pragma mark - PSPromise
static id _warp_error(id error){
    if ([error isKindOfClass:[NSError class]]) {
        return error;
    }else{
        return [NSError errorWithDomain:@"PSPromise" code:-1000 userInfo:@{NSLocalizedDescriptionKey: error}];
    }
}

#pragma mark - block signature
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
@end

static inline PSPromiseContext *_context_with_resolver(void (^promise)(PSResolver)){
    return [[PSPromiseContext alloc] initWithResolver:promise];
}
static inline PSPromiseContext *_context_with_value(id value){
    return [[PSPromiseContext alloc] initWithValue:value];
}

PSPromiseContext *PSPromise(id promise){
    if ([promise isKindOfClass:NSClassFromString(@"NSBlock")]){
        return _context_with_resolver(^(PSResolver resolver) {
            @try {
                resolver(_call_block(promise, nil));
            }
            @catch (id error) {
                resolver(_warp_error(error));
            }
        });
    }else if (([promise isKindOfClass:[NSArray class]] || [promise isKindOfClass:[NSDictionary class]]) && [promise count] > 0){
        //break
    }else if ([promise isKindOfClass:[PSPromiseContext class]]){
        promise = @[promise];
    }else {
        return _context_with_value(promise);
    }
    
    __block int64_t totalCount = [promise count];
    //handle promise array or dictionary
    return _context_with_resolver(^(PSResolver resolver) {
        BOOL isDic = [promise isKindOfClass:[NSDictionary class]];
        NSUInteger index = 0;
        for (__strong id key in promise) {
            PSPromiseContext *context = isDic ? promise[key] : key;
            if (![context isKindOfClass:[PSPromiseContext class]]) {
                context = _context_with_value(context);
            }
            if (!isDic) {
                key = @(index);
            }
            
            [context pipe:^(id obj) {
                if ([obj isKindOfClass:[NSError class]]) {
                    resolver(obj);
                }else if(OSAtomicDecrement64(&totalCount) == 0) {
                    id results = nil;
                    if (isDic) {
                        results = [NSMutableDictionary dictionary];
                        for (id key in promise) {
                            id result = promise[key];
                            results[key] = [result isKindOfClass:[PSPromiseContext class]] ? [result result] : result;
                        }
                    }else{
                        results = [NSMutableArray new];
                        for (id result in promise) {
                            [results addObject:[result isKindOfClass:[PSPromiseContext class]] ? [result result] : result];
                        }
                    }
                    resolver(results);
                }
            }];
        }
    });
}

PSPromiseContext *PSSyncPromise(void (^promise)(PSResolver)){
    return [[PSPromiseContext alloc] initWithResolver:^(PSResolver resolver) {
        dispatch_async(dispatch_get_main_queue(), ^{
            promise(resolver);
        });
    }];
}

PSPromiseContext *PSAsyncPromise(void (^promise)(PSResolver)){
    return [[PSPromiseContext alloc] initWithResolver:^(PSResolver resolver) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            promise(resolver);
        });
    }];
}
