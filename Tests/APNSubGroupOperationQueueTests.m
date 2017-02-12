//
//  APNSubGroupOperationQueueTests.m
//  APNSubGroupOperationQueue
//
//  Created by André Pacheco Neves on 03/04/16.
//  Copyright © 2016 André Pacheco Neves. All rights reserved.
//

#import <XCTest/XCTest.h>

@import APNSubGroupOperationQueue;

typedef void (^APNAppendingBlock)(void);

@interface APNSubGroupOperationQueueTests : XCTestCase

@property(nonatomic, strong) APNSubGroupOperationQueue *subGroupQueue;

@end

@implementation APNSubGroupOperationQueueTests

- (void)setUp {
    [super setUp];

    self.subGroupQueue = [APNSubGroupOperationQueue new];
}

- (void)tearDown {
    [super tearDown];
}

#pragma mark -
#pragma mark addOperation

- (void)testAddOperation_withSingleGroup_mustExecuteSerially {
    NSString *key = @"key";
    NSString *string = @"123456";
    NSArray<NSString *> *strings = [self splitString:string];
    NSMutableString *result = [NSMutableString string];

    NSArray<NSBlockOperation *> *ops = [self stringAppendingBlockOperationsForStrings:strings result:result];

    self.subGroupQueue.suspended = YES;

    for (NSBlockOperation *op in ops) {
        [self.subGroupQueue addOperation:op withKey:key];
    }

    self.subGroupQueue.suspended = NO;

    [self.subGroupQueue waitUntilAllOperationsAreFinished];

    XCTAssert([self.subGroupQueue subGroupOperationsForKey:key].count == 0);
    XCTAssert([result isEqualToString:string]);
}

- (void)testAddOperation_withMutipleGroups_mustExecuteEachGroupSerially {
    NSObject *keyA = @"A";
    NSObject *keyB = @1337;
    NSObject *keyC = [NSDate date];

    NSString *stringA = @"123456";
    NSString *stringB = @"abcdef";
    NSString *stringC = @"ABCDEF";

    NSArray<NSString *> *stringsA = [self splitString:stringA];
    NSArray<NSString *> *stringsB = [self splitString:stringB];
    NSArray<NSString *> *stringsC = [self splitString:stringC];

    NSMutableString *resultA = [NSMutableString string];
    NSMutableString *resultB = [NSMutableString string];
    NSMutableString *resultC = [NSMutableString string];

    NSArray<NSBlockOperation *> *opsA = [self stringAppendingBlockOperationsForStrings:stringsA result:resultA];
    NSArray<NSBlockOperation *> *opsB = [self stringAppendingBlockOperationsForStrings:stringsB result:resultB];
    NSArray<NSBlockOperation *> *opsC = [self stringAppendingBlockOperationsForStrings:stringsC result:resultC];

    self.subGroupQueue.suspended = YES;

    // schedule them in order *inside* each subgroup, but *shuffled* between subgroups
    [self.subGroupQueue addOperation:opsA[0] withKey:keyA];
    [self.subGroupQueue addOperation:opsB[0] withKey:keyB];
    [self.subGroupQueue addOperation:opsC[0] withKey:keyC];
    [self.subGroupQueue addOperation:opsA[1] withKey:keyA];
    [self.subGroupQueue addOperation:opsB[1] withKey:keyB];
    [self.subGroupQueue addOperation:opsB[2] withKey:keyB];
    [self.subGroupQueue addOperation:opsA[2] withKey:keyA];
    [self.subGroupQueue addOperation:opsC[1] withKey:keyC];
    [self.subGroupQueue addOperation:opsC[2] withKey:keyC];
    [self.subGroupQueue addOperation:opsA[3] withKey:keyA];
    [self.subGroupQueue addOperation:opsB[3] withKey:keyB];
    [self.subGroupQueue addOperation:opsA[4] withKey:keyA];
    [self.subGroupQueue addOperation:opsC[3] withKey:keyC];
    [self.subGroupQueue addOperation:opsB[4] withKey:keyB];
    [self.subGroupQueue addOperation:opsC[4] withKey:keyC];
    [self.subGroupQueue addOperation:opsA[5] withKey:keyA];
    [self.subGroupQueue addOperation:opsB[5] withKey:keyB];
    [self.subGroupQueue addOperation:opsC[5] withKey:keyC];

    self.subGroupQueue.suspended = NO;

    [self.subGroupQueue waitUntilAllOperationsAreFinished];

    XCTAssert([self.subGroupQueue subGroupOperationsForKey:keyA].count == 0);
    XCTAssert([self.subGroupQueue subGroupOperationsForKey:keyB].count == 0);
    XCTAssert([self.subGroupQueue subGroupOperationsForKey:keyC].count == 0);

    XCTAssert([resultA isEqualToString:stringA]);
    XCTAssert([resultB isEqualToString:stringB]);
    XCTAssert([resultC isEqualToString:stringC]);
}

#pragma mark -
#pragma mark addOperations

- (void)testAddOperations_withSingleGroup_mustExecuteSerially {
    NSString *key = @"key";
    NSString *string = @"123456";
    NSArray<NSString *> *strings = [self splitString:string];
    NSMutableString *result = [NSMutableString string];
    NSArray<NSBlockOperation *> *ops = [self stringAppendingBlockOperationsForStrings:strings result:result];

    [self.subGroupQueue addOperations:ops withKey:key waitUntilFinished:true];

    XCTAssert([self.subGroupQueue subGroupOperationsForKey:key].count == 0);
    XCTAssert([result isEqualToString:string], @"%@ didn't match expected value %@", result, string);
}

- (void)testAddOperations_withMutipleGroups_mustExecuteEachGroupSerially {
    NSObject *keyA = @"A";
    NSObject *keyB = @1337;
    NSObject *keyC = [NSDate date];

    NSString *stringA = @"123456";
    NSString *stringB = @"abcdef";
    NSString *stringC = @"ABCDEF";

    NSArray<NSString *> *stringsA = [self splitString:stringA];
    NSArray<NSString *> *stringsB = [self splitString:stringB];
    NSArray<NSString *> *stringsC = [self splitString:stringC];

    NSMutableString *resultA = [NSMutableString string];
    NSMutableString *resultB = [NSMutableString string];
    NSMutableString *resultC = [NSMutableString string];

    NSArray<NSBlockOperation *> *opsA = [self stringAppendingBlockOperationsForStrings:stringsA result:resultA];
    NSArray<NSBlockOperation *> *opsB = [self stringAppendingBlockOperationsForStrings:stringsB result:resultB];
    NSArray<NSBlockOperation *> *opsC = [self stringAppendingBlockOperationsForStrings:stringsC result:resultC];

    self.subGroupQueue.suspended = YES;

    [self.subGroupQueue addOperations:opsA withKey:keyA waitUntilFinished:false];
    [self.subGroupQueue addOperations:opsB withKey:keyB waitUntilFinished:false];
    [self.subGroupQueue addOperations:opsC withKey:keyC waitUntilFinished:false];

    self.subGroupQueue.suspended = NO;

    [self.subGroupQueue waitUntilAllOperationsAreFinished];

    XCTAssert([self.subGroupQueue subGroupOperationsForKey:keyA].count == 0);
    XCTAssert([self.subGroupQueue subGroupOperationsForKey:keyB].count == 0);
    XCTAssert([self.subGroupQueue subGroupOperationsForKey:keyC].count == 0);

    XCTAssert([resultA isEqualToString:stringA], @"%@ didn't match expected value %@", resultA, stringA);
    XCTAssert([resultB isEqualToString:stringB], @"%@ didn't match expected value %@", resultB, stringB);
    XCTAssert([resultC isEqualToString:stringC], @"%@ didn't match expected value %@", resultC, stringC);
}

#pragma mark -
#pragma mark addOperationWithBlock

- (void)testAddOperationWithBlock_withSingleGroup_mustExecuteSerially {
    NSString *key = @"key";
    NSString *string = @"123456";
    NSArray<NSString *> *strings = [self splitString:string];
    NSMutableString *result = [NSMutableString string];

    NSArray<APNAppendingBlock> *blocks = [self stringAppendingBlocksForStrings:strings result:result];

    self.subGroupQueue.suspended = YES;

    for (APNAppendingBlock block in blocks) {
        [self.subGroupQueue addOperationWithBlock:block andKey:key];
    }

    self.subGroupQueue.suspended = NO;

    [self.subGroupQueue waitUntilAllOperationsAreFinished];

    XCTAssert([self.subGroupQueue subGroupOperationsForKey:key].count == 0);
    XCTAssert([result isEqualToString:string], @"%@ didn't match expected value %@", result, string);
}

- (void)testAddOperationWithBlock_withMutipleGroups_mustExecuteEachGroupSerially {
    NSObject *keyA = @"A";
    NSObject *keyB = @1337;
    NSObject *keyC = [NSDate date];

    NSString *stringA = @"123456";
    NSString *stringB = @"abcdef";
    NSString *stringC = @"ABCDEF";

    NSArray<NSString *> *stringsA = [self splitString:stringA];
    NSArray<NSString *> *stringsB = [self splitString:stringB];
    NSArray<NSString *> *stringsC = [self splitString:stringC];

    NSMutableString *resultA = [NSMutableString string];
    NSMutableString *resultB = [NSMutableString string];
    NSMutableString *resultC = [NSMutableString string];

    NSArray<APNAppendingBlock> *blocksA = [self stringAppendingBlocksForStrings:stringsA result:resultA];
    NSArray<APNAppendingBlock> *blocksB = [self stringAppendingBlocksForStrings:stringsB result:resultB];
    NSArray<APNAppendingBlock> *blocksC = [self stringAppendingBlocksForStrings:stringsC result:resultC];

    self.subGroupQueue.suspended = YES;

    // schedule them in order *inside* each subgroup, but *shuffled* between subgroups
    [self.subGroupQueue addOperationWithBlock:blocksA[0] andKey:keyA];
    [self.subGroupQueue addOperationWithBlock:blocksB[0] andKey:keyB];
    [self.subGroupQueue addOperationWithBlock:blocksC[0] andKey:keyC];
    [self.subGroupQueue addOperationWithBlock:blocksA[1] andKey:keyA];
    [self.subGroupQueue addOperationWithBlock:blocksB[1] andKey:keyB];
    [self.subGroupQueue addOperationWithBlock:blocksB[2] andKey:keyB];
    [self.subGroupQueue addOperationWithBlock:blocksA[2] andKey:keyA];
    [self.subGroupQueue addOperationWithBlock:blocksC[1] andKey:keyC];
    [self.subGroupQueue addOperationWithBlock:blocksC[2] andKey:keyC];
    [self.subGroupQueue addOperationWithBlock:blocksA[3] andKey:keyA];
    [self.subGroupQueue addOperationWithBlock:blocksB[3] andKey:keyB];
    [self.subGroupQueue addOperationWithBlock:blocksA[4] andKey:keyA];
    [self.subGroupQueue addOperationWithBlock:blocksC[3] andKey:keyC];
    [self.subGroupQueue addOperationWithBlock:blocksB[4] andKey:keyB];
    [self.subGroupQueue addOperationWithBlock:blocksC[4] andKey:keyC];
    [self.subGroupQueue addOperationWithBlock:blocksA[5] andKey:keyA];
    [self.subGroupQueue addOperationWithBlock:blocksB[5] andKey:keyB];
    [self.subGroupQueue addOperationWithBlock:blocksC[5] andKey:keyC];

    self.subGroupQueue.suspended = NO;

    [self.subGroupQueue waitUntilAllOperationsAreFinished];

    XCTAssert([self.subGroupQueue subGroupOperationsForKey:keyA].count == 0);
    XCTAssert([self.subGroupQueue subGroupOperationsForKey:keyB].count == 0);
    XCTAssert([self.subGroupQueue subGroupOperationsForKey:keyC].count == 0);

    XCTAssert([resultA isEqualToString:stringA], @"%@ didn't match expected value %@", resultA, stringA);
    XCTAssert([resultB isEqualToString:stringB], @"%@ didn't match expected value %@", resultB, stringB);
    XCTAssert([resultC isEqualToString:stringC], @"%@ didn't match expected value %@", resultC, stringC);
}

#pragma mark -
#pragma mark mixed

- (void)testMixedAddOperations_withSingleGroup_mustExecuteEachGroupSerially {
    NSString *key = @"key";
    NSString *string = @"123456";
    NSArray<NSString *> *strings = [self splitString:string];
    NSMutableString *result = [NSMutableString string];

    NSArray<APNAppendingBlock> *blocks = [self stringAppendingBlocksForStrings:strings result:result];

    NSBlockOperation *op1 = [NSBlockOperation blockOperationWithBlock:blocks[0]];
    NSBlockOperation *op2 = [NSBlockOperation blockOperationWithBlock:blocks[1]];
    NSBlockOperation *op5 = [NSBlockOperation blockOperationWithBlock:blocks[4]];
    NSBlockOperation *op6 = [NSBlockOperation blockOperationWithBlock:blocks[5]];

    self.subGroupQueue.suspended = YES;

    [self.subGroupQueue addOperation:op1 withKey:key];
    [self.subGroupQueue addOperation:op2 withKey:key];

    [self.subGroupQueue addOperationWithBlock:blocks[2] andKey:key];
    [self.subGroupQueue addOperationWithBlock:blocks[3] andKey:key];

    [self.subGroupQueue addOperations:@[ op5, op6 ] withKey:key waitUntilFinished:false];

    self.subGroupQueue.suspended = NO;

    [self.subGroupQueue waitUntilAllOperationsAreFinished];

    XCTAssert([self.subGroupQueue subGroupOperationsForKey:key].count == 0);
    XCTAssert([result isEqualToString:string], @"%@ didn't match expected value %@", result, string);
}

- (void)testMixedAddOperations_withMutipleGroups_mustExecuteEachGroupSerially {
    NSObject *keyA = @"A";
    NSObject *keyB = @1337;
    NSObject *keyC = [NSDate date];

    NSString *stringA = @"123456";
    NSString *stringB = @"abcdef";
    NSString *stringC = @"ABCDEF";

    NSArray<NSString *> *stringsA = [self splitString:stringA];
    NSArray<NSString *> *stringsB = [self splitString:stringB];
    NSArray<NSString *> *stringsC = [self splitString:stringC];

    NSMutableString *resultA = [NSMutableString string];
    NSMutableString *resultB = [NSMutableString string];
    NSMutableString *resultC = [NSMutableString string];

    NSArray<APNAppendingBlock> *blocksA = [self stringAppendingBlocksForStrings:stringsA result:resultA];
    NSArray<APNAppendingBlock> *blocksB = [self stringAppendingBlocksForStrings:stringsB result:resultB];
    NSArray<APNAppendingBlock> *blocksC = [self stringAppendingBlocksForStrings:stringsC result:resultC];

    NSBlockOperation *opA1 = [NSBlockOperation blockOperationWithBlock:blocksA[0]];
    NSBlockOperation *opA2 = [NSBlockOperation blockOperationWithBlock:blocksA[1]];
    NSBlockOperation *opA5 = [NSBlockOperation blockOperationWithBlock:blocksA[4]];
    NSBlockOperation *opA6 = [NSBlockOperation blockOperationWithBlock:blocksA[5]];

    NSBlockOperation *opB3 = [NSBlockOperation blockOperationWithBlock:blocksB[2]];
    NSBlockOperation *opB4 = [NSBlockOperation blockOperationWithBlock:blocksB[3]];
    NSBlockOperation *opB5 = [NSBlockOperation blockOperationWithBlock:blocksB[4]];
    NSBlockOperation *opB6 = [NSBlockOperation blockOperationWithBlock:blocksB[5]];

    NSBlockOperation *opC1 = [NSBlockOperation blockOperationWithBlock:blocksC[0]];
    NSBlockOperation *opC2 = [NSBlockOperation blockOperationWithBlock:blocksC[1]];
    NSBlockOperation *opC3 = [NSBlockOperation blockOperationWithBlock:blocksC[2]];
    NSBlockOperation *opC4 = [NSBlockOperation blockOperationWithBlock:blocksC[3]];

    self.subGroupQueue.suspended = YES;

    // schedule them in order *inside* each subgroup, but *shuffled* between subgroups
    [self.subGroupQueue addOperation:opA1 withKey:keyA];
    [self.subGroupQueue addOperationWithBlock:blocksB[0] andKey:keyB];
    [self.subGroupQueue addOperations:@[ opC1, opC2 ] withKey:keyC waitUntilFinished:false];
    [self.subGroupQueue addOperation:opA2 withKey:keyA];
    [self.subGroupQueue addOperationWithBlock:blocksB[1] andKey:keyB];
    [self.subGroupQueue addOperations:@[ opB3, opB4 ] withKey:keyB waitUntilFinished:false];
    [self.subGroupQueue addOperationWithBlock:blocksA[2] andKey:keyA];
    [self.subGroupQueue addOperation:opC3 withKey:keyC];
    [self.subGroupQueue addOperationWithBlock:blocksA[3] andKey:keyA];
    [self.subGroupQueue addOperations:@[ opA5, opA6 ] withKey:keyA waitUntilFinished:false];
    [self.subGroupQueue addOperation:opC4 withKey:keyC];
    [self.subGroupQueue addOperation:opB5 withKey:keyB];
    [self.subGroupQueue addOperationWithBlock:blocksC[4] andKey:keyC];
    [self.subGroupQueue addOperation:opB6 withKey:keyB];
    [self.subGroupQueue addOperationWithBlock:blocksC[5] andKey:keyC];

    self.subGroupQueue.suspended = NO;

    [self.subGroupQueue waitUntilAllOperationsAreFinished];

    XCTAssert([self.subGroupQueue subGroupOperationsForKey:keyA].count == 0);
    XCTAssert([self.subGroupQueue subGroupOperationsForKey:keyB].count == 0);
    XCTAssert([self.subGroupQueue subGroupOperationsForKey:keyC].count == 0);

    XCTAssert([resultA isEqualToString:stringA], @"%@ didn't match expected value %@", resultA, stringA);
    XCTAssert([resultB isEqualToString:stringB], @"%@ didn't match expected value %@", resultB, stringB);
    XCTAssert([resultC isEqualToString:stringC], @"%@ didn't match expected value %@", resultC, stringC);
}

#pragma mark -
#pragma mark subGroupOperationsForKey

- (void)testSubGroupOperations_withExistingSubGroupOperations_shouldReturnOperations {
    NSString *key = @"key";

    NSBlockOperation *op1 = [NSBlockOperation new];
    NSBlockOperation *op2 = [NSBlockOperation new];
    NSBlockOperation *op3 = [NSBlockOperation new];
    NSBlockOperation *op4 = [NSBlockOperation new];
    NSBlockOperation *op5 = [NSBlockOperation new];
    NSBlockOperation *op6 = [NSBlockOperation new];

    NSArray<NSBlockOperation *> *expected = @[ op1 ];  // Xcode complains with array literals with more than 1 element 😓

    self.subGroupQueue.suspended = YES;

    [self.subGroupQueue addOperation:op1 withKey:key];
    XCTAssert([[self.subGroupQueue subGroupOperationsForKey:key] isEqualToArray:expected]);

    [self.subGroupQueue addOperation:op2 withKey:key];
    expected = @[ op1, op2 ];
    XCTAssert([[self.subGroupQueue subGroupOperationsForKey:key] isEqualToArray:expected]);

    [self.subGroupQueue addOperation:op3 withKey:key];
    expected = @[ op1, op2, op3 ];
    XCTAssert([[self.subGroupQueue subGroupOperationsForKey:key] isEqualToArray:expected]);

    [self.subGroupQueue addOperations:@[ op4, op5, op6 ] withKey:key waitUntilFinished:false];
    expected = @[ op1, op2, op3, op4, op5, op6 ];
    XCTAssert([[self.subGroupQueue subGroupOperationsForKey:key] isEqualToArray:expected]);

    self.subGroupQueue.suspended = NO;

    [self.subGroupQueue waitUntilAllOperationsAreFinished];

    XCTAssert([self.subGroupQueue subGroupOperationsForKey:key].count == 0);
}

- (void)testSubGroupOperations_withNonExistingSubGroupOperations_shouldReturnEmptyArray {
    XCTAssert([self.subGroupQueue subGroupOperationsForKey:@"key"].count == 0);
}

#pragma mark -
#pragma mark Auxiliary

- (NSArray<NSString *> *)splitString:(NSString *)string {
    NSParameterAssert(string);

    NSMutableArray<NSString *> *chars = [NSMutableArray array];

    for (int i = 0; i < string.length; i++) {
        [chars addObject:[string substringWithRange:NSMakeRange(i, 1)]];
    }
    return [chars copy];
}

- (NSArray<APNAppendingBlock> *)stringAppendingBlocksForStrings:(NSArray<NSString *> *)strings
                                                         result:(NSMutableString *)result {
    NSParameterAssert(strings.count);
    NSParameterAssert(result);

    NSMutableArray<APNAppendingBlock> *blocks = [NSMutableArray array];

    for (NSString *s in strings) {
        [blocks addObject:^{
            [result appendString:s];
        }];
    }

    return [blocks copy];
}

- (NSArray<NSBlockOperation *> *)stringAppendingBlockOperationsForStrings:(NSArray<NSString *> *)strings
                                                                   result:(NSMutableString *)result {
    NSParameterAssert(strings.count);
    NSParameterAssert(result);

    NSMutableArray<NSBlockOperation *> *ops = [NSMutableArray array];

    for (NSString *s in strings) {
        [ops addObject:[NSBlockOperation blockOperationWithBlock:^{
                 [result appendString:s];
             }]];
    }

    return [ops copy];
}

@end
