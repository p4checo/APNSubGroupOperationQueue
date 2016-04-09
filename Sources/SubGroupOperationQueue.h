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

@interface APNSubGroupOperationQueue : NSOperationQueue

#pragma mark -
#pragma mark SubGroup operation scheduling

- (void)addOperation:(NSOperation *)op withKey:(id<NSCopying>)key;

- (void)addOperations:(NSArray<NSOperation *> *)ops withKey:(id<NSCopying>)key waitUntilFinished:(BOOL)wait;

- (void)addOperationWithBlock:(void (^)(void))block andKey:(id<NSCopying>)key;

#pragma mark -
#pragma mark SubGroup querying

- (NSArray<NSOperation *> *)subGroupOperationsForKey:(id<NSCopying>)key;

@end

NS_ASSUME_NONNULL_END
