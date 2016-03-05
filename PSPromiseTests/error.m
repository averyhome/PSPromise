//
//  error.m
//  PSPromise
//
//  Created by PoiSon on 16/3/5.
//  Copyright © 2016年 PoiSon. All rights reserved.
//

#import "error.h"

NSError *NSErrorWithLocalizedDescription(NSString *description){
    return [NSError errorWithDomain:@"cn.yerl.Promise" code:-1000 userInfo:@{NSLocalizedDescriptionKey: description}];
}
