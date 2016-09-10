//
//  APNSubGroupOperationQueueTests.swift
//  APNSubGroupOperationQueue
//
//  Created by André Pacheco Neves on 27/03/16.
//  Copyright © 2016 André Pacheco Neves. All rights reserved.
//

import XCTest
@testable import APNSubGroupOperationQueue

private class Box<T>{
    var value: T
    init(_ v: T) { value = v }
}

class APNSubGroupOperationQueueTests: XCTestCase {
    
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
        let (key, string, result) = ("key", "123456", Box<String>(""))
        
        let ops = stringAppendingBlockOperations(splitString(string), sharedBox: result)
        
        subGroupQueue.isSuspended = true
        
        ops.forEach { subGroupQueue.addOperation($0, key: key) }
        
        subGroupQueue.isSuspended = false
        
        subGroupQueue.waitUntilAllOperationsAreFinished()
        
        XCTAssert(subGroupQueue[key].count == 0)
        XCTAssert(result.value == string, "\(result.value) didn't match expected value \(string)")
    }
    
    func testAddOperation_withMutipleGroups_mustExecuteEachGroupSerially() {
        let (keyA, stringA, resultA) = ("keyA", "123456", Box<String>(""))
        let (keyB, stringB, resultB) = ("keyB", "abcdef", Box<String>(""))
        let (keyC, stringC, resultC) = ("keyC", "ABCDEF", Box<String>(""))
        
        let opsA = stringAppendingBlockOperations(splitString(stringA), sharedBox: resultA)
        let opsB = stringAppendingBlockOperations(splitString(stringB), sharedBox: resultB)
        let opsC = stringAppendingBlockOperations(splitString(stringC), sharedBox: resultC)

        subGroupQueue.isSuspended = true
        
        // schedule them in order *inside* each subgroup, but *shuffled* between subgroups
        subGroupQueue.addOperation(opsA[0], key: keyA)
        subGroupQueue.addOperation(opsB[0], key: keyB)
        subGroupQueue.addOperation(opsC[0], key: keyC)
        subGroupQueue.addOperation(opsA[1], key: keyA)
        subGroupQueue.addOperation(opsB[1], key: keyB)
        subGroupQueue.addOperation(opsB[2], key: keyB)
        subGroupQueue.addOperation(opsA[2], key: keyA)
        subGroupQueue.addOperation(opsC[1], key: keyC)
        subGroupQueue.addOperation(opsC[2], key: keyC)
        subGroupQueue.addOperation(opsA[3], key: keyA)
        subGroupQueue.addOperation(opsB[3], key: keyB)
        subGroupQueue.addOperation(opsA[4], key: keyA)
        subGroupQueue.addOperation(opsC[3], key: keyC)
        subGroupQueue.addOperation(opsB[4], key: keyB)
        subGroupQueue.addOperation(opsC[4], key: keyC)
        subGroupQueue.addOperation(opsA[5], key: keyA)
        subGroupQueue.addOperation(opsB[5], key: keyB)
        subGroupQueue.addOperation(opsC[5], key: keyC)
        
        subGroupQueue.isSuspended = false
        
        subGroupQueue.waitUntilAllOperationsAreFinished()
        
        XCTAssert(subGroupQueue[keyA].count == 0)
        XCTAssert(subGroupQueue[keyB].count == 0)
        XCTAssert(subGroupQueue[keyC].count == 0)
        XCTAssert(resultA.value == stringA, "\(resultA.value) didn't match expected value \(stringA)")
        XCTAssert(resultB.value == stringB, "\(resultB.value) didn't match expected value \(stringB)")
        XCTAssert(resultC.value == stringC, "\(resultC.value) didn't match expected value \(stringC)")
    }
    
    // MARK: - addOperations
    
    func testAddOperations_withSingleGroup_mustExecuteSerially() {
        let (key, string, result) = ("key", "123456", Box<String>(""))
        
        let ops = stringAppendingBlockOperations(splitString(string), sharedBox: result)
        
        subGroupQueue.addOperations(ops, key: key, waitUntilFinished: true)
        
        XCTAssert(subGroupQueue[key].count == 0)
        XCTAssert(result.value == string, "\(result) didn't match expected value \(string)")
    }
    
    func testAddOperations_withMutipleGroups_mustExecuteEachGroupSerially() {
        let (keyA, stringA, resultA) = ("keyA", "123456", Box<String>(""))
        let (keyB, stringB, resultB) = ("keyB", "abcdef", Box<String>(""))
        let (keyC, stringC, resultC) = ("keyC", "ABCDEF", Box<String>(""))
        
        let opsA = stringAppendingBlockOperations(splitString(stringA), sharedBox: resultA)
        let opsB = stringAppendingBlockOperations(splitString(stringB), sharedBox: resultB)
        let opsC = stringAppendingBlockOperations(splitString(stringC), sharedBox: resultC)
        
        subGroupQueue.isSuspended = true
        
        subGroupQueue.addOperations(opsA, key: keyA, waitUntilFinished: false)
        subGroupQueue.addOperations(opsB, key: keyB, waitUntilFinished: false)
        subGroupQueue.addOperations(opsC, key: keyC, waitUntilFinished: false)
        
        subGroupQueue.isSuspended = false
        
        subGroupQueue.waitUntilAllOperationsAreFinished()
        
        XCTAssert(subGroupQueue[keyA].count == 0)
        XCTAssert(subGroupQueue[keyB].count == 0)
        XCTAssert(subGroupQueue[keyC].count == 0)
        XCTAssert(resultA.value == stringA, "\(resultA.value) didn't match expected value \(stringA)")
        XCTAssert(resultB.value == stringB, "\(resultB.value) didn't match expected value \(stringB)")
        XCTAssert(resultC.value == stringC, "\(resultC.value) didn't match expected value \(stringC)")
    }
    
    // MARK: - addOperationWithBlock
    
    func testAddOperationWithBlock_withSingleGroup_mustExecuteSerially() {
        let (key, string, result) = ("key", "123456", Box<String>(""))
        
        let blocks = stringAppendingBlocks(splitString(string), sharedBox: result)
        
        subGroupQueue.isSuspended = true
        
        blocks.forEach { subGroupQueue.addOperationWithBlock($0, key: key) }
        
        subGroupQueue.isSuspended = false
        
        subGroupQueue.waitUntilAllOperationsAreFinished()
        
        XCTAssert(subGroupQueue[key].count == 0)
        XCTAssert(result.value == string, "\(result.value) didn't match expected value \(string)")
    }
    
    func testAddOperationWithBlock_withMutipleGroups_mustExecuteEachGroupSerially() {
        let (keyA, stringA, resultA) = ("keyA", "123456", Box<String>(""))
        let (keyB, stringB, resultB) = ("keyB", "abcdef", Box<String>(""))
        let (keyC, stringC, resultC) = ("keyC", "ABCDEF", Box<String>(""))
        
        let blocksA = stringAppendingBlocks(splitString(stringA), sharedBox: resultA)
        let blocksB = stringAppendingBlocks(splitString(stringB), sharedBox: resultB)
        let blocksC = stringAppendingBlocks(splitString(stringC), sharedBox: resultC)
        
        subGroupQueue.isSuspended = true
        
        // schedule them in order *inside* each subgroup, but *shuffled* between subgroups
        subGroupQueue.addOperationWithBlock(blocksA[0], key: keyA)
        subGroupQueue.addOperationWithBlock(blocksB[0], key: keyB)
        subGroupQueue.addOperationWithBlock(blocksC[0], key: keyC)
        subGroupQueue.addOperationWithBlock(blocksA[1], key: keyA)
        subGroupQueue.addOperationWithBlock(blocksB[1], key: keyB)
        subGroupQueue.addOperationWithBlock(blocksB[2], key: keyB)
        subGroupQueue.addOperationWithBlock(blocksA[2], key: keyA)
        subGroupQueue.addOperationWithBlock(blocksC[1], key: keyC)
        subGroupQueue.addOperationWithBlock(blocksC[2], key: keyC)
        subGroupQueue.addOperationWithBlock(blocksA[3], key: keyA)
        subGroupQueue.addOperationWithBlock(blocksB[3], key: keyB)
        subGroupQueue.addOperationWithBlock(blocksA[4], key: keyA)
        subGroupQueue.addOperationWithBlock(blocksC[3], key: keyC)
        subGroupQueue.addOperationWithBlock(blocksB[4], key: keyB)
        subGroupQueue.addOperationWithBlock(blocksC[4], key: keyC)
        subGroupQueue.addOperationWithBlock(blocksA[5], key: keyA)
        subGroupQueue.addOperationWithBlock(blocksB[5], key: keyB)
        subGroupQueue.addOperationWithBlock(blocksC[5], key: keyC)
        
        subGroupQueue.isSuspended = false
        
        subGroupQueue.waitUntilAllOperationsAreFinished()
        
        XCTAssert(subGroupQueue[keyA].count == 0)
        XCTAssert(subGroupQueue[keyB].count == 0)
        XCTAssert(subGroupQueue[keyC].count == 0)
        XCTAssert(resultA.value == stringA, "\(resultA.value) didn't match expected value \(stringA)")
        XCTAssert(resultB.value == stringB, "\(resultB.value) didn't match expected value \(stringB)")
        XCTAssert(resultC.value == stringC, "\(resultC.value) didn't match expected value \(stringC)")
    }
    
    // MARK: - mixed
    
    func testMixedAddOperations_withSingleGroup_mustExecuteEachGroupSerially() {
        let (key, string, result) = ("key", "123456", Box<String>(""))
        
        let blocks = stringAppendingBlocks(splitString(string), sharedBox: result)
        
        subGroupQueue.isSuspended = true
        
        subGroupQueue.addOperation(BlockOperation(block: blocks[0]), key: key)
        subGroupQueue.addOperation(BlockOperation(block: blocks[1]), key: key)
        
        subGroupQueue.addOperationWithBlock(blocks[2], key: key)
        subGroupQueue.addOperationWithBlock(blocks[3], key: key)
        
        let op5 = BlockOperation(block: blocks[4])
        let op6 = BlockOperation(block: blocks[5])
        subGroupQueue.addOperations([op5, op6], key: key, waitUntilFinished: false)
        
        subGroupQueue.isSuspended = false
        
        subGroupQueue.waitUntilAllOperationsAreFinished()
        
        XCTAssert(subGroupQueue[key].count == 0)
        XCTAssert(result.value == string, "\(result.value) didn't match expected value \(string)")
    }
    
    func testMixedAddOperations_withMutipleGroups_mustExecuteEachGroupSerially() {
        let (keyA, stringA, resultA) = ("keyA", "123456", Box<String>(""))
        let (keyB, stringB, resultB) = ("keyB", "abcdef", Box<String>(""))
        let (keyC, stringC, resultC) = ("keyC", "ABCDEF", Box<String>(""))
        
        let blocksA = stringAppendingBlocks(splitString(stringA), sharedBox: resultA)
        let blocksB = stringAppendingBlocks(splitString(stringB), sharedBox: resultB)
        let blocksC = stringAppendingBlocks(splitString(stringC), sharedBox: resultC)
        
        let opA5 = BlockOperation(block: blocksA[4])
        let opA6 = BlockOperation(block: blocksA[5])
        
        let opB3 = BlockOperation(block: blocksB[2])
        let opB4 = BlockOperation(block: blocksB[3])
        
        let opC1 = BlockOperation(block: blocksC[0])
        let opC2 = BlockOperation(block: blocksC[1])
        
        subGroupQueue.isSuspended = true
        
        // schedule them in order *inside* each subgroup, but *shuffled* between subgroups
        subGroupQueue.addOperation(BlockOperation(block: blocksA[0]), key: keyA)
        subGroupQueue.addOperationWithBlock(blocksB[0], key: keyB)
        subGroupQueue.addOperations([opC1, opC2], key: keyC, waitUntilFinished: false)
        subGroupQueue.addOperation(BlockOperation(block: blocksA[1]), key: keyA)
        subGroupQueue.addOperationWithBlock(blocksB[1], key: keyB)
        subGroupQueue.addOperations([opB3, opB4], key: keyB, waitUntilFinished: false)
        subGroupQueue.addOperationWithBlock(blocksA[2], key: keyA)
        subGroupQueue.addOperation(BlockOperation(block: blocksC[2]), key: keyC)
        subGroupQueue.addOperationWithBlock(blocksA[3], key: keyA)
        subGroupQueue.addOperations([opA5, opA6], key: keyA, waitUntilFinished: false)
        subGroupQueue.addOperation(BlockOperation(block: blocksC[3]), key: keyC)
        subGroupQueue.addOperation(BlockOperation(block: blocksB[4]), key: keyB)
        subGroupQueue.addOperationWithBlock(blocksC[4], key: keyC)
        subGroupQueue.addOperation(BlockOperation(block: blocksB[5]), key: keyB)
        subGroupQueue.addOperationWithBlock(blocksC[5], key: keyC)
        
        subGroupQueue.isSuspended = false
        
        subGroupQueue.waitUntilAllOperationsAreFinished()
        
        XCTAssert(subGroupQueue[keyA].count == 0)
        XCTAssert(subGroupQueue[keyB].count == 0)
        XCTAssert(subGroupQueue[keyC].count == 0)
        XCTAssert(resultA.value == stringA, "\(resultA.value) didn't match expected value \(stringA)")
        XCTAssert(resultB.value == stringB, "\(resultB.value) didn't match expected value \(stringB)")
        XCTAssert(resultC.value == stringC, "\(resultC.value) didn't match expected value \(stringC)")
    }
    
    // MARK: - subGroupOperations
    
    func testSubGroupOperations_withExistingSubGroupOperations_shouldReturnOperations() {
        let key = "key"
        
        let ops = stringAppendingBlockOperations(splitString("123456"), sharedBox: Box<String>(""))
        
        subGroupQueue.isSuspended = true
        
        subGroupQueue.addOperation(ops[0], key: key)
        XCTAssert(subGroupQueue.subGroupOperations(key) == Array(ops[0..<1]))
        
        subGroupQueue.addOperation(ops[1], key: key)
        XCTAssert(subGroupQueue.subGroupOperations(key) == Array(ops[0..<2]))
        
        subGroupQueue.addOperation(ops[2], key: key)
        XCTAssert(subGroupQueue.subGroupOperations(key) == Array(ops[0..<3]))
        
        subGroupQueue.addOperations(Array(ops[3...5]), key: key, waitUntilFinished: false)
        XCTAssert(subGroupQueue.subGroupOperations(key) == ops)
        
        XCTAssert(subGroupQueue[key].count == 6)
    }
    
    func testSubGroupOperations_withNonExistingSubGroupOperations_shouldReturnEmptyArray() {
        let key = "key"
        
        XCTAssert(subGroupQueue.subGroupOperations(key) == [])
        XCTAssert(subGroupQueue[key].count == 0)
    }
    
    // MARK: - Auxiliary
    
    fileprivate func splitString(_ string: String) -> [String] {
        return string.characters.map { String($0) }
    }
    
    fileprivate func stringAppendingBlocks(_ strings: [String], sharedBox: Box<String>) -> [() -> Void] {
        return strings.map { s in return { sharedBox.value += s } }
    }
    
    fileprivate func stringAppendingBlockOperations(_ strings: [String], sharedBox: Box<String>) -> [BlockOperation] {
        return strings.map { s in BlockOperation(block: { sharedBox.value += s }) }
    }
}
