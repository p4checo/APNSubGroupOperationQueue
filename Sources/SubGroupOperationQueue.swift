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

/**
 `CompletionOperation` is an `NSBlockOperation` subclass which is used internally by the `SubGroupOperationQueue` to 
 remove completed operations from the subgroup dictionary.
 
 For each operation submitted by the user to the queue, a `CompletionOperation` which depends on it is created 
 containing the logic to cleanup the subgroup dictionary. By doing this, the operation's `completionBlock` doesn't have 
 to be used, allowing the user full control over the operation, without introducing possible side-effects.
 
 These operations aren't returned by either `subscript` or `subGroupOperations` even though they technically are in the 
 subgroup.
 */
private final class CompletionOperation: BlockOperation {}

/** 
 `SubGroupOperationQueue` is an `NSOperation` subclass which allows scheduling operations in serial subgroups inside
 a concurrent queue. 
 
 The subgroups are stored as a `[Key : [NSOperation]]`, and each subgroup array contains all the scheduled subgroup's 
 operations which are pending and executing. Finished `NSOperation`s are automatically removed from the subgroup after 
 completion.
*/
public final class SubGroupOperationQueue<Key: Hashable>: OperationQueue {
    
    fileprivate let queue: DispatchQueue
    fileprivate var subGroups: [Key : [Operation]]
    
    /** 
     The maximum number of queued operations that can execute at the same time.
     
     - warning: This value should be `!= 1` (serial queue), otherwise this class provides no benefit.
    */
    override public var maxConcurrentOperationCount: Int {
        get {
            return super.maxConcurrentOperationCount
        }
        set {
            assert(newValue != 1, "`SubGroupQueue` must be concurrent to provide any benefit over a serial queue! 🙃")
            super.maxConcurrentOperationCount = newValue
        }
    }

    /**
     Instantiates a new `SubGroupOperationQueue`.
     
     - returns: A new `SubGroupOperationQueue` instance.
     */
    override public init() {
        queue = DispatchQueue(label: "com.p4checo.\(type(of: self)).queue", attributes: DispatchQueue.Attributes.concurrent)
        subGroups = [:]
        
        super.init()
    }
    
    // MARK: - Public

    /**
     Adds the specified operation to the queue, and registers it the subgroup identified by `key`.
     
     Once added, the operation will only be executed after all currently existing operations in the same subgroup finish
     * executing (serial processing), but can be executed concurrently with other subgroup's operations.
     
     - parameter op:  The `NSOperation` to be added to the queue.
     - parameter key: The subgroup's identifier key.
     */
    public func addOperation(_ op: Operation, key: Key) {
        var opPair = [Operation]()
        
        queue.sync(flags: .barrier, execute: {
            var subGroup = self.subGroups[key] ?? []
            let completionOp = self.addOperationDependencies(op, key: key, subGroup: subGroup)
            opPair = [op, completionOp]
            
                subGroup.append(contentsOf: opPair)
            self.subGroups[key] = subGroup
        }) 
        
        addOperations(opPair, waitUntilFinished: false)
    }
    
    /**
     Adds the specified operations to the queue, and registers them the subgroup identified by `key`. 
     The order in which the operations are processed is the same as the array's.
     
     Once added, the operations will be executed in order after all currently existing operations in the same subgroup
     finish executing (serial processing), but can be executed concurrently with other subgroup's operations.
     
     - parameter ops:  The `[NSOperation]` to be added to the queue
     - parameter key:  The subgroup's identifier key
     - parameter wait: If `true`, the current thread is blocked until all of the specified operations finish executing. 
     If `false`, the operations are added to the queue and control returns immediately to the caller.
     */
    public func addOperations(_ ops: [Operation], key: Key, waitUntilFinished wait: Bool) {
        var newOps = [Operation]()
        
        queue.sync(flags: .barrier, execute: {
            var subGroup = self.subGroups[key] ?? []
            
            ops.forEach { op in
                let completionOp = self.addOperationDependencies(op, key: key, subGroup: subGroup)
                let opPair = [op, completionOp]
                    newOps.append(contentsOf: opPair)
                    subGroup.append(contentsOf: opPair)
            }
            
            self.subGroups[key] = subGroup
        }) 
        
        addOperations(newOps, waitUntilFinished: wait)
    }
    
    /**
     Wraps the specified block in an operation object, adds it to the queue and and registers it the subgroup identified
     by `key`.
     
     Once added, the operation will only be executed after all currently existing operations in the same subgroup finish
     executing (serial processing), but can be executed concurrently with other subgroup's operations.
     
     - parameter block: The block to execute from the operation.
     - parameter key:   The subgroup's identifier key.
     */
    public func addOperationWithBlock(_ block: @escaping () -> Void, key: Key) {
        addOperation(BlockOperation(block: block), key: key)
    }
    
    // MARK: SubGroup querying
    
    /**
     Return a snapshot of currently scheduled (i.e. non-finished) operations of the subgroup identified by `key`.
     
     - parameter key: The subgroup's identifier key.
     
     - returns: An `[NSOperation]` containing a snapshot of all currently scheduled (non-finished) subgroup operations.
     */
    public subscript(key: Key) -> [Operation] {
        return subGroupOperations(key)
    }
    
    /**
     Return a snapshot of currently scheduled (i.e. non-finished) operations of the subgroup identified by `key`.
     
     - parameter key: The subgroup's identifier key.
     
     - returns: An `[NSOperation]` containing a snapshot of all currently scheduled (non-finished) subgroup operations.
     */
    public func subGroupOperations(_ key: Key) -> [Operation] {
        var ops: [Operation]?
        
        queue.sync {
            ops = self.subGroups[key]?.filter{ !($0 is CompletionOperation) }
        }
        
        return ops ?? []
    }
    
    // MARK: - Private
    
    fileprivate func addOperationDependencies(_ op: Operation, key: Key, subGroup: [Operation]) -> CompletionOperation {
        let completionOp = completionOperation(op, key: key)
        completionOp.addDependency(op)
        
        // new operations only need to depend on the group's last operation
        if let lastOp = subGroup.last {
            op.addDependency(lastOp)
        }
        
        return completionOp
    }
    
    fileprivate func completionOperation(_ op: Operation, key: Key) -> CompletionOperation {
        let completionOp = CompletionOperation()
        
        completionOp.addExecutionBlock({ [weak weakCompletionOp = completionOp] in
            self.queue.sync(flags: .barrier, execute: {
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
                
                self.subGroups[key] = subGroup.count == 2 ? nil : {
                    subGroup.removeFirst(2)
                    return subGroup
                }()
            }) 
        })
        
        return completionOp
    }
}
