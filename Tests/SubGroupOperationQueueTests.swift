//
//  SubGroupOperationQueueTests.swift
//  APNSubGroupOperationQueue
//
//  Created by André Pacheco Neves on 27/03/16.
//  Copyright © 2016 André Pacheco Neves. All rights reserved.
//

import XCTest
@testable import APNSubGroupOperationQueue

class SubGroupOperationQueueTestsTests: XCTestCase  {

    var subGroupQueue: SubGroupOperationQueue<String>!

    override func setUp() {
        super.setUp()

        subGroupQueue = SubGroupOperationQueue<String>()
        subGroupQueue.maxConcurrentOperationCount = OperationQueue.defaultMaxConcurrentOperationCount
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - addOperation

    func testAddOperation_withSingleGroup_mustExecuteSerially() {
        let (key, value, result) = ("key", "123456", Box<String>(""))

        let ops = stringAppendingBlockOperations(for: splitString(value), sharedBox: result)

        subGroupQueue.isSuspended = true

        ops.forEach { subGroupQueue.addOperation($0, withKey: key) }

        subGroupQueue.isSuspended = false

        subGroupQueue.waitUntilAllOperationsAreFinished()

        XCTAssert(subGroupQueue[key].count == 0)
        XCTAssert(result.value == value, "\(result.value) didn't match expected value \(value)")
    }

    func testAddOperation_withMutipleGroups_mustExecuteEachGroupSerially() {
        let (keyA, valueA, resultA) = ("keyA", "123456", Box<String>(""))
        let (keyB, valueB, resultB) = ("keyB", "abcdef", Box<String>(""))
        let (keyC, valueC, resultC) = ("keyC", "ABCDEF", Box<String>(""))

        let opsA = stringAppendingBlockOperations(for: splitString(valueA), sharedBox: resultA)
        let opsB = stringAppendingBlockOperations(for: splitString(valueB), sharedBox: resultB)
        let opsC = stringAppendingBlockOperations(for: splitString(valueC), sharedBox: resultC)

        subGroupQueue.isSuspended = true

        // schedule them in order *inside* each subgroup, but *shuffled* between subgroups
        subGroupQueue.addOperation(opsA[0], withKey: keyA)
        subGroupQueue.addOperation(opsB[0], withKey: keyB)
        subGroupQueue.addOperation(opsC[0], withKey: keyC)
        subGroupQueue.addOperation(opsA[1], withKey: keyA)
        subGroupQueue.addOperation(opsB[1], withKey: keyB)
        subGroupQueue.addOperation(opsB[2], withKey: keyB)
        subGroupQueue.addOperation(opsA[2], withKey: keyA)
        subGroupQueue.addOperation(opsC[1], withKey: keyC)
        subGroupQueue.addOperation(opsC[2], withKey: keyC)
        subGroupQueue.addOperation(opsA[3], withKey: keyA)
        subGroupQueue.addOperation(opsB[3], withKey: keyB)
        subGroupQueue.addOperation(opsA[4], withKey: keyA)
        subGroupQueue.addOperation(opsC[3], withKey: keyC)
        subGroupQueue.addOperation(opsB[4], withKey: keyB)
        subGroupQueue.addOperation(opsC[4], withKey: keyC)
        subGroupQueue.addOperation(opsA[5], withKey: keyA)
        subGroupQueue.addOperation(opsB[5], withKey: keyB)
        subGroupQueue.addOperation(opsC[5], withKey: keyC)

        subGroupQueue.isSuspended = false

        subGroupQueue.waitUntilAllOperationsAreFinished()

        XCTAssert(subGroupQueue[keyA].count == 0)
        XCTAssert(subGroupQueue[keyB].count == 0)
        XCTAssert(subGroupQueue[keyC].count == 0)
        XCTAssert(resultA.value == valueA, "\(resultA.value) didn't match expected value \(valueA)")
        XCTAssert(resultB.value == valueB, "\(resultB.value) didn't match expected value \(valueB)")
        XCTAssert(resultC.value == valueC, "\(resultC.value) didn't match expected value \(valueC)")
    }

    // MARK: - addOperations

    func testAddOperations_withSingleGroup_mustExecuteSerially() {
        let (key, value, result) = ("key", "123456", Box<String>(""))

        let ops = stringAppendingBlockOperations(for: splitString(value), sharedBox: result)

        subGroupQueue.addOperations(ops, withKey: key, waitUntilFinished: true)

        XCTAssert(subGroupQueue[key].count == 0)
        XCTAssert(result.value == value, "\(result) didn't match expected value \(value)")
    }

    func testAddOperations_withMutipleGroups_mustExecuteEachGroupSerially() {
        let (keyA, valueA, resultA) = ("keyA", "123456", Box<String>(""))
        let (keyB, valueB, resultB) = ("keyB", "abcdef", Box<String>(""))
        let (keyC, valueC, resultC) = ("keyC", "ABCDEF", Box<String>(""))

        let opsA = stringAppendingBlockOperations(for: splitString(valueA), sharedBox: resultA)
        let opsB = stringAppendingBlockOperations(for: splitString(valueB), sharedBox: resultB)
        let opsC = stringAppendingBlockOperations(for: splitString(valueC), sharedBox: resultC)

        subGroupQueue.isSuspended = true

        subGroupQueue.addOperations(opsA, withKey: keyA, waitUntilFinished: false)
        subGroupQueue.addOperations(opsB, withKey: keyB, waitUntilFinished: false)
        subGroupQueue.addOperations(opsC, withKey: keyC, waitUntilFinished: false)

        subGroupQueue.isSuspended = false

        subGroupQueue.waitUntilAllOperationsAreFinished()

        XCTAssert(subGroupQueue[keyA].count == 0)
        XCTAssert(subGroupQueue[keyB].count == 0)
        XCTAssert(subGroupQueue[keyC].count == 0)
        XCTAssert(resultA.value == valueA, "\(resultA.value) didn't match expected value \(valueA)")
        XCTAssert(resultB.value == valueB, "\(resultB.value) didn't match expected value \(valueB)")
        XCTAssert(resultC.value == valueC, "\(resultC.value) didn't match expected value \(valueC)")
    }

    // MARK: - addOperation

    func testAddOperationWithBlock_withSingleGroup_mustExecuteSerially() {
        let (key, value, result) = ("key", "123456", Box<String>(""))

        let blocks = stringAppendingBlocks(for: splitString(value), sharedBox: result)

        subGroupQueue.isSuspended = true

        blocks.forEach { subGroupQueue.addOperation($0, withKey: key) }

        subGroupQueue.isSuspended = false

        subGroupQueue.waitUntilAllOperationsAreFinished()

        XCTAssert(subGroupQueue[key].count == 0)
        XCTAssert(result.value == value, "\(result.value) didn't match expected value \(value)")
    }

    func testAddOperationWithBlock_withMutipleGroups_mustExecuteEachGroupSerially() {
        let (keyA, valueA, resultA) = ("keyA", "123456", Box<String>(""))
        let (keyB, valueB, resultB) = ("keyB", "abcdef", Box<String>(""))
        let (keyC, valueC, resultC) = ("keyC", "ABCDEF", Box<String>(""))

        let blocksA = stringAppendingBlocks(for: splitString(valueA), sharedBox: resultA)
        let blocksB = stringAppendingBlocks(for: splitString(valueB), sharedBox: resultB)
        let blocksC = stringAppendingBlocks(for: splitString(valueC), sharedBox: resultC)

        subGroupQueue.isSuspended = true

        // schedule them in order *inside* each subgroup, but *shuffled* between subgroups
        subGroupQueue.addOperation(blocksA[0], withKey: keyA)
        subGroupQueue.addOperation(blocksB[0], withKey: keyB)
        subGroupQueue.addOperation(blocksC[0], withKey: keyC)
        subGroupQueue.addOperation(blocksA[1], withKey: keyA)
        subGroupQueue.addOperation(blocksB[1], withKey: keyB)
        subGroupQueue.addOperation(blocksB[2], withKey: keyB)
        subGroupQueue.addOperation(blocksA[2], withKey: keyA)
        subGroupQueue.addOperation(blocksC[1], withKey: keyC)
        subGroupQueue.addOperation(blocksC[2], withKey: keyC)
        subGroupQueue.addOperation(blocksA[3], withKey: keyA)
        subGroupQueue.addOperation(blocksB[3], withKey: keyB)
        subGroupQueue.addOperation(blocksA[4], withKey: keyA)
        subGroupQueue.addOperation(blocksC[3], withKey: keyC)
        subGroupQueue.addOperation(blocksB[4], withKey: keyB)
        subGroupQueue.addOperation(blocksC[4], withKey: keyC)
        subGroupQueue.addOperation(blocksA[5], withKey: keyA)
        subGroupQueue.addOperation(blocksB[5], withKey: keyB)
        subGroupQueue.addOperation(blocksC[5], withKey: keyC)

        subGroupQueue.isSuspended = false

        subGroupQueue.waitUntilAllOperationsAreFinished()

        XCTAssert(subGroupQueue[keyA].count == 0)
        XCTAssert(subGroupQueue[keyB].count == 0)
        XCTAssert(subGroupQueue[keyC].count == 0)
        XCTAssert(resultA.value == valueA, "\(resultA.value) didn't match expected value \(valueA)")
        XCTAssert(resultB.value == valueB, "\(resultB.value) didn't match expected value \(valueB)")
        XCTAssert(resultC.value == valueC, "\(resultC.value) didn't match expected value \(valueC)")
    }

    // MARK: - mixed

    func testMixedAddOperations_withSingleGroup_mustExecuteEachGroupSerially() {
        let (key, value, result) = ("key", "123456", Box<String>(""))

        let blocks = stringAppendingBlocks(for: splitString(value), sharedBox: result)

        subGroupQueue.isSuspended = true

        subGroupQueue.addOperation(BlockOperation(block: blocks[0]), withKey: key)
        subGroupQueue.addOperation(BlockOperation(block: blocks[1]), withKey: key)

        subGroupQueue.addOperation(blocks[2], withKey: key)
        subGroupQueue.addOperation(blocks[3], withKey: key)

        let op5 = BlockOperation(block: blocks[4])
        let op6 = BlockOperation(block: blocks[5])
        subGroupQueue.addOperations([op5, op6], withKey: key, waitUntilFinished: false)

        subGroupQueue.isSuspended = false

        subGroupQueue.waitUntilAllOperationsAreFinished()

        XCTAssert(subGroupQueue[key].count == 0)
        XCTAssert(result.value == value, "\(result.value) didn't match expected value \(value)")
    }

    func testMixedAddOperations_withMutipleGroups_mustExecuteEachGroupSerially() {
        let (keyA, valueA, resultA) = ("keyA", "123456", Box<String>(""))
        let (keyB, valueB, resultB) = ("keyB", "abcdef", Box<String>(""))
        let (keyC, valueC, resultC) = ("keyC", "ABCDEF", Box<String>(""))

        let blocksA = stringAppendingBlocks(for: splitString(valueA), sharedBox: resultA)
        let blocksB = stringAppendingBlocks(for: splitString(valueB), sharedBox: resultB)
        let blocksC = stringAppendingBlocks(for: splitString(valueC), sharedBox: resultC)

        let opA5 = BlockOperation(block: blocksA[4])
        let opA6 = BlockOperation(block: blocksA[5])

        let opB3 = BlockOperation(block: blocksB[2])
        let opB4 = BlockOperation(block: blocksB[3])

        let opC1 = BlockOperation(block: blocksC[0])
        let opC2 = BlockOperation(block: blocksC[1])

        subGroupQueue.isSuspended = true

        // schedule them in order *inside* each subgroup, but *shuffled* between subgroups
        subGroupQueue.addOperation(BlockOperation(block: blocksA[0]), withKey: keyA)
        subGroupQueue.addOperation(blocksB[0], withKey: keyB)
        subGroupQueue.addOperations([opC1, opC2], withKey: keyC, waitUntilFinished: false)
        subGroupQueue.addOperation(BlockOperation(block: blocksA[1]), withKey: keyA)
        subGroupQueue.addOperation(blocksB[1], withKey: keyB)
        subGroupQueue.addOperations([opB3, opB4], withKey: keyB, waitUntilFinished: false)
        subGroupQueue.addOperation(blocksA[2], withKey: keyA)
        subGroupQueue.addOperation(BlockOperation(block: blocksC[2]), withKey: keyC)
        subGroupQueue.addOperation(blocksA[3], withKey: keyA)
        subGroupQueue.addOperations([opA5, opA6], withKey: keyA, waitUntilFinished: false)
        subGroupQueue.addOperation(BlockOperation(block: blocksC[3]), withKey: keyC)
        subGroupQueue.addOperation(BlockOperation(block: blocksB[4]), withKey: keyB)
        subGroupQueue.addOperation(blocksC[4], withKey: keyC)
        subGroupQueue.addOperation(BlockOperation(block: blocksB[5]), withKey: keyB)
        subGroupQueue.addOperation(blocksC[5], withKey: keyC)

        subGroupQueue.isSuspended = false

        subGroupQueue.waitUntilAllOperationsAreFinished()

        XCTAssert(subGroupQueue[keyA].count == 0)
        XCTAssert(subGroupQueue[keyB].count == 0)
        XCTAssert(subGroupQueue[keyC].count == 0)
        XCTAssert(resultA.value == valueA, "\(resultA.value) didn't match expected value \(valueA)")
        XCTAssert(resultB.value == valueB, "\(resultB.value) didn't match expected value \(valueB)")
        XCTAssert(resultC.value == valueC, "\(resultC.value) didn't match expected value \(valueC)")
    }

    // MARK: - subGroupOperations

    func testSubGroupOperations_withExistingSubGroupOperations_shouldReturnOperations() {
        let key = "key"

        let ops = stringAppendingBlockOperations(for: splitString("123456"), sharedBox: Box<String>(""))

        subGroupQueue.isSuspended = true

        subGroupQueue.addOperation(ops[0], withKey: key)
        XCTAssert(subGroupQueue.subGroupOperations(forKey: key) == Array(ops[0..<1]))

        subGroupQueue.addOperation(ops[1], withKey: key)
        XCTAssert(subGroupQueue.subGroupOperations(forKey: key) == Array(ops[0..<2]))

        subGroupQueue.addOperation(ops[2], withKey: key)
        XCTAssert(subGroupQueue.subGroupOperations(forKey: key) == Array(ops[0..<3]))
        
        subGroupQueue.addOperations(Array(ops[3...5]), withKey: key, waitUntilFinished: false)
        XCTAssert(subGroupQueue.subGroupOperations(forKey: key) == ops)
        
        XCTAssert(subGroupQueue[key].count == 6)
    }
    
    func testSubGroupOperations_withNonExistingSubGroupOperations_shouldReturnEmptyArray() {
        let key = "key"
        
        XCTAssert(subGroupQueue.subGroupOperations(forKey: key) == [])
        XCTAssert(subGroupQueue[key].count == 0)
    }
    
}

