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
 `SubGroupOperationQueue` is an `OperationQueue` subclass which allows scheduling operations in serial subgroups inside
 a concurrent queue. 
 
 The subgroups are stored as a `[Key : [Operation]]`, and each subgroup array contains all the scheduled subgroup's
 operations which are pending and executing. Finished `Operation`s are automatically removed from the subgroup after 
 completion.
*/
public class SubGroupOperationQueue<Key: Hashable>: OperationQueue {

    fileprivate let subGroups = OperationSubGroupMap<AnyHashable>()
    
    /** 
     The maximum number of queued operations that can execute at the same time.
     
     - warning: This value should be `!= 1` (serial queue), otherwise this class provides no benefit.
    */
    override public var maxConcurrentOperationCount: Int {
        get { return super.maxConcurrentOperationCount }
        set {
            assert(newValue != 1, "`SubGroupQueue` must be concurrent to provide any benefit over a serial queue! 🙃")
            super.maxConcurrentOperationCount = newValue
        }
    }

    // MARK: - Public

    /**
     Adds the specified operation to the queue, and registers it the subgroup identified by `key`.
     
     Once added, the operation will only be executed after all currently existing operations in the same subgroup finish
     * executing (serial processing), but can be executed concurrently with other subgroup's operations.
     
     - parameter op:  The `Operation` to be added to the queue.
     - parameter key: The subgroup's identifier key.
     */
    public func addOperation(_ op: Operation, withKey key: Key) {
        addOperations(subGroups.register(op, withKey: key), waitUntilFinished: false)
    }
    
    /**
     Adds the specified operations to the queue, and registers them the subgroup identified by `key`. 
     The order in which the operations are processed is the same as the array's.
     
     Once added, the operations will be executed in order after all currently existing operations in the same subgroup
     finish executing (serial processing), but can be executed concurrently with other subgroup's operations.
     
     - parameter ops:  The `[Operation]` to be added to the queue
     - parameter key:  The subgroup's identifier key
     - parameter wait: If `true`, the current thread is blocked until all of the specified operations finish executing. 
     If `false`, the operations are added to the queue and control returns immediately to the caller.
     */
    public func addOperations(_ ops: [Operation], withKey key: Key, waitUntilFinished wait: Bool) {
        addOperations(subGroups.register(ops, withKey: key), waitUntilFinished: wait)
    }
    
    /**
     Wraps the specified block in an operation object, adds it to the queue and and registers it the subgroup identified
     by `key`.
     
     Once added, the operation will only be executed after all currently existing operations in the same subgroup finish
     executing (serial processing), but can be executed concurrently with other subgroup's operations.
     
     - parameter block: The block to execute from the operation.
     - parameter key:   The subgroup's identifier key.
     */
    public func addOperation(_ block: @escaping () -> Void, withKey key: Key) {
        addOperations(subGroups.register(block, withKey: key), waitUntilFinished: false)
    }
    
    // MARK: SubGroup querying
    
    /**
     Return a snapshot of currently scheduled (i.e. non-finished) operations of the subgroup identified by `key`.
     
     - parameter key: The subgroup's identifier key.
     
     - returns: An `[Operation]` containing a snapshot of all currently scheduled (non-finished) subgroup operations.
     */
    public subscript(key: Key) -> [Operation] {
        return subGroups[key]
    }
    
    /**
     Return a snapshot of currently scheduled (i.e. non-finished) operations of the subgroup identified by `key`.
     
     - parameter key: The subgroup's identifier key.
     
     - returns: An `[Operation]` containing a snapshot of all currently scheduled (non-finished) subgroup operations.
     */
    public func subGroupOperations(forKey key: Key) -> [Operation] {
        return subGroups[key]
    }
}
