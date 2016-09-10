//
//  SubGroupOperationQueue.m
//  APNSubGroupOperationQueue
//
//  Created by André Pacheco Neves on 03/04/16.
//  Copyright © 2016 André Pacheco Neves. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

#import "SubGroupOperationQueue.h"

#pragma mark -
#pragma mark APNCompletionOperation

@interface APNCompletionOperation : NSBlockOperation
@end

@implementation APNCompletionOperation
@end

#pragma mark -
#pragma mark APNSubGroupOperationQueue

@interface APNSubGroupOperationQueue ()

@property(nonatomic, strong) dispatch_queue_t queue;
@property(nonatomic, strong) NSMutableDictionary<id<NSCopying>, NSArray<__kindof NSOperation *> *> *subGroups;

@end

@implementation APNSubGroupOperationQueue

- (instancetype)init {
    self = [super init];
    if (self) {
        self.queue = dispatch_queue_create("com.p4checo.APNSubGroupOperationQueue.queue", DISPATCH_QUEUE_CONCURRENT);
        self.subGroups = [NSMutableDictionary new];
    }
    return self;
}

#pragma mark -
#pragma mark Public

#pragma mark -
#pragma mark SubGroup operation scheduling

- (void)addOperation:(NSOperation *)op withKey:(id<NSCopying>)key {
    NSParameterAssert(op);
    NSParameterAssert(key);

    __block NSArray<NSOperation *> *opPair;

    dispatch_barrier_sync(self.queue, ^{
        NSArray<NSOperation *> *subGroup = self.subGroups[key] ?: @[];

        APNCompletionOperation *competionOp = [self addDependenciesOnOperation:op withKey:key inSubGroup:subGroup];

        opPair = @[ op, competionOp ];

        self.subGroups[key] = [subGroup arrayByAddingObjectsFromArray:opPair];
    });

    [self addOperations:opPair waitUntilFinished:false];
}

- (void)addOperations:(NSArray<__kindof NSOperation *> *)ops withKey:(id<NSCopying>)key waitUntilFinished:(BOOL)wait {
    NSParameterAssert(ops.count);
    NSParameterAssert(key);

    __block NSMutableArray<NSOperation *> *newOps = [NSMutableArray array];

    dispatch_barrier_sync(self.queue, ^{
        NSMutableArray<NSOperation *> *subGroup = [self.subGroups[key] ?: @[] mutableCopy];

        for (NSOperation *op in ops) {
            APNCompletionOperation *competionOp = [self addDependenciesOnOperation:op withKey:key inSubGroup:subGroup];

            NSArray<NSOperation *> *opPair = @[ op, competionOp ];
            [newOps addObjectsFromArray:opPair];
            [subGroup addObjectsFromArray:opPair];
        }

        self.subGroups[key] = [subGroup copy];
    });

    [self addOperations:newOps waitUntilFinished:wait];
}

- (void)addOperationWithBlock:(void (^)(void))block andKey:(id<NSCopying>)key {
    NSParameterAssert(block);
    NSParameterAssert(key);

    [self addOperation:[NSBlockOperation blockOperationWithBlock:block] withKey:key];
}

#pragma mark -
#pragma mark SubGroup querying

- (NSArray<__kindof NSOperation *> *)subGroupOperationsForKey:(id<NSCopying>)key {
    NSParameterAssert(key);

    static NSPredicate *classPredicate;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        classPredicate = [NSPredicate predicateWithFormat:@"class != %@", [APNCompletionOperation class]];
    });

    __block NSArray<NSOperation *> *ops;

    dispatch_sync(self.queue, ^{
        ops = [self.subGroups[key] filteredArrayUsingPredicate:classPredicate];
    });

    return ops ?: @[];
}

#pragma mark -
#pragma mark Setters

- (void)setMaxConcurrentOperationCount:(NSInteger)maxConcurrentOperationCount {
    NSAssert(maxConcurrentOperationCount != 1,
             @"`APNSubGroupOperationQueue` must be concurrent to provide any benefit over a serial queue! 🙃");

    super.maxConcurrentOperationCount = maxConcurrentOperationCount;
}

#pragma mark -
#pragma mark Private

NS_ASSUME_NONNULL_BEGIN

- (APNCompletionOperation *)addDependenciesOnOperation:(NSOperation *)op
                                               withKey:(id<NSCopying>)key
                                            inSubGroup:(NSArray<__kindof NSOperation *> *)subGroup {
    NSParameterAssert(op);
    NSParameterAssert(key);
    NSParameterAssert(subGroup);

    APNCompletionOperation *completionOp = [self completionOperationForOperation:op withKey:key];
    [completionOp addDependency:op];

    // new operations only need to depend on the group's last operation
    NSOperation *lastOp = subGroup.lastObject;
    lastOp ? [op addDependency:lastOp] : nil;

    return completionOp;
}

- (APNCompletionOperation *)completionOperationForOperation:(NSOperation *)op withKey:(id<NSCopying>)key {
    NSParameterAssert(op);
    NSParameterAssert(key);

    APNCompletionOperation *completionOp = [APNCompletionOperation new];

    __weak typeof(completionOp) weakCompletionOp = completionOp;

    [completionOp addExecutionBlock:^{
        dispatch_barrier_sync(self.queue, ^(void) {
            __strong typeof(weakCompletionOp) strongCompletionOp = weakCompletionOp;

            if (!strongCompletionOp) {
                NSAssert(NO, @"💥: completion operation must not be nil");
                return;
            }

            NSArray<NSOperation *> *subGroup = self.subGroups[key];

            NSAssert(subGroup, @"💥: A subgroup must exist in the dicionary for the finished operation's key!");
            NSAssert([op isEqual:subGroup[0]],
                     @"💥: Finished operation must be the first element in the subgroup's array");
            NSAssert([strongCompletionOp isEqual:subGroup[1]],
                     @"💥: completionOp must be the second element in the subgroup's array");

            self.subGroups[key] = subGroup.count == 2 ? nil : ({
                NSMutableArray<NSOperation *> *newSubGroup = [subGroup mutableCopy];
                [newSubGroup removeObjectsInRange:NSMakeRange(0, 2)];
                [newSubGroup copy];
            });
        });
    }];

    return completionOp;
}

NS_ASSUME_NONNULL_END

@end
