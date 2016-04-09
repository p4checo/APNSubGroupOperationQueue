//
//  SubGroupOperationQueue.swift
//  APNSubGroupOperationQueue
//
//  Created by André Pacheco Neves on 27/03/16.
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

import Foundation

@objc(APNCompletionOperation)
public class CompletionOperation: NSBlockOperation {}

public class SubGroupOperationQueue<Key: Hashable>: NSOperationQueue {
    
    private let queue: dispatch_queue_t
    private var subGroups: [Key : [NSOperation]]
    
    override public var maxConcurrentOperationCount: Int {
        get {
            return super.maxConcurrentOperationCount
        }
        set {
            assert(newValue != 1, "`SubGroupQueue` must be concurrent to provide any benefit over a serial queue! 🙃")
            super.maxConcurrentOperationCount = newValue
        }
    }

    override public init() {
        queue = dispatch_queue_create("com.p4checo.\(self.dynamicType).queue", DISPATCH_QUEUE_SERIAL)
        subGroups = [:]
    }
    
    // MARK: - Public
    
    public func addOperation(op: NSOperation, key: Key) {
        var opPair = [NSOperation]()
        
        dispatch_sync(queue) {
            var subGroup = self.subGroups[key] ?? []
            let completionOp = self.addOperationDependencies(op, key: key, subGroup: subGroup)
            opPair = [op, completionOp]
            
            subGroup.appendContentsOf(opPair)
            self.subGroups[key] = subGroup
        }
        
        addOperations(opPair, waitUntilFinished: false)
    }
    
    public func addOperations(ops: [NSOperation], key: Key, waitUntilFinished wait: Bool) {
        var newOps = [NSOperation]()
        
        dispatch_sync(queue) {
            var subGroup = self.subGroups[key] ?? []
            
            ops.forEach { op in
                let completionOp = self.addOperationDependencies(op, key: key, subGroup: subGroup)
                let opPair = [op, completionOp]
                newOps.appendContentsOf(opPair)
                subGroup.appendContentsOf(opPair)
            }
            
            self.subGroups[key] = subGroup
        }
        
        addOperations(newOps, waitUntilFinished: wait)
    }
    
    public func addOperationWithBlock(block: () -> Void, key: Key) {
        addOperation(NSBlockOperation(block: block), key: key)
    }
    
    // MARK: SubGroup querying
    
    public subscript(key: Key) -> [NSOperation] {
        return subGroupOperations(key)
    }
    
    public func subGroupOperations(key: Key) -> [NSOperation] {
        var ops: [NSOperation]?
        
        dispatch_sync(queue) {
            ops = self.subGroups[key]?.filter{ !($0 is CompletionOperation) }
        }
        
        return ops ?? []
    }
    
    // MARK: - Private
    
    private func addOperationDependencies(op: NSOperation, key: Key, subGroup: [NSOperation]) -> CompletionOperation {
        let completionOp = completionOperation(op, key: key)
        completionOp.addDependency(op)
        
        // new operations only need to depend on the group's last operation
        if let lastOp = subGroup.last {
            op.addDependency(lastOp)
        }
        
        return completionOp
    }
    
    private func completionOperation(op: NSOperation, key: Key) -> CompletionOperation {
        let completionOp = CompletionOperation()
        
        completionOp.addExecutionBlock({ [weak weakCompletionOp = completionOp] in
            dispatch_async(self.queue) {
                guard let completionOp = weakCompletionOp else {
                    assertionFailure("💥: The completion operation must not be nil")
                    return
                }
                
                guard var subGroup = self.subGroups[key] else {
                    assertionFailure("💥: A group must exist in the dicionary for the finished operation's key!")
                    return
                }
                
                guard [op, completionOp] == subGroup[0...1] else {
                    assertionFailure("💥: op and completionOp must be the first 2 elements in the subgroup's array")
                    return
                }
                
                subGroup.removeFirst(2)
                self.subGroups[key] = subGroup
            }
        })
        
        return completionOp
    }
}