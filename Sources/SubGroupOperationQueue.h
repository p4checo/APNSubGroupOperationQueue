//
//  SubGroupOperationQueue.h
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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 \c APNSubGroupOperationQueue is an \c NSOperation subclass which allows scheduling operations in serial subgroups
 inside a concurrent queue.

 The subgroups are stored as a: \code NSMutableDictionary<id<NSCopying>, NSArray<NSOperation *> *> * \endcode, and each
 subgroup array contains all the scheduled subgroup's operations which are pending and executing. Finished
 \c NSOperation are automatically removed from the subgroup after completion.
 */
@interface APNSubGroupOperationQueue : NSOperationQueue

#pragma mark -
#pragma mark SubGroup operation scheduling

/**
 *  Adds the specified operation to the queue, and registers it the subgroup identified by \c key.
 *
 *  Once added, the operation will only be executed after all currently existing operations in the same subgroup finish
 * executing (serial processing), but can be executed concurrently with other subgroup's operations.
 *
 *  @param op  The \c NSOperation to be added to the queue.
 *  @param key The subgroup's identifier key.
 */
- (void)addOperation:(NSOperation *)op withKey:(id<NSCopying>)key;

/**
 *  Adds the specified operations to the queue, and registers them the subgroup identified by \c key. The order in which
 * the operations are processed is the same as the array's.
 *
 *  Once added, the operations will be executed in order after all currently existing operations in the same subgroup
 * finish executing (serial processing), but can be executed concurrently with other subgroup's operations.
 *
 *  @param ops  The array of \c NSOperation 's to be added to the queue
 *  @param key  The subgroup's identifier key
 *  @param wait If \c YES, the current thread is blocked until all of the specified operations finish executing. If \c
 * NO, the operations are added to the queue and control returns immediately to the caller.
 */
- (void)addOperations:(NSArray<NSOperation *> *)ops withKey:(id<NSCopying>)key waitUntilFinished:(BOOL)wait;

/**
 *  Wraps the specified block in an operation object, adds it to the queue and and registers it the subgroup identified
 * by \c key.
 *
 *  Once added, the operation will only be executed after all currently existing operations in the same subgroup finish
 * executing (serial processing), but can be executed concurrently with other subgroup's operations.
 *
 *  @param block The block to execute from the operation.
 *  @param key   The subgroup's identifier key.
 */
- (void)addOperationWithBlock:(void (^)(void))block andKey:(id<NSCopying>)key;

#pragma mark -
#pragma mark SubGroup querying

/**
 *  Return a snapshot of currently scheduled (i.e. non-finished) operations of the subgroup identified by \c key.
 *
 *  @param key The subgroup's identifier key.
 *
 *  @return An \c NSOperation array containing a snapshot of all currently scheduled (non-finished) subgroup operations.
 */
- (NSArray<NSOperation *> *)subGroupOperationsForKey:(id<NSCopying>)key;

@end

NS_ASSUME_NONNULL_END
