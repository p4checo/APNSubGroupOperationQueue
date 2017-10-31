//
//  DynamicSubGroupOperationQueue.swift
//  APNSubGroupOperationQueue
//
//  Created by André Pacheco Neves on 12/02/2017.
//  Copyright © 2017 André Pacheco Neves. All rights reserved.
//

import Foundation

/**
 `DynamicSubGroupOperationQueue` is an `OperationQueue` subclass which allows scheduling operations in serial subgroups 
 inside a concurrent queue.

 The subgroups are stored as a `[AnyHashable : [Operation]]`, and each subgroup array contains all the scheduled 
 subgroup's operations which are pending and executing. Finished `Operation`s are automatically removed from the
 subgroup after completion.
 */
@objc(APNSubGroupOperationQueue)
public final class DynamicSubGroupOperationQueue: OperationQueue {

    fileprivate let subGroups = OperationSubGroupMap<AnyHashable>()

    /**
     The maximum number of queued operations that can execute at the same time.

     - warning: This value should be `!= 1` (serial queue), otherwise this class provides no benefit.
     */
    override public var maxConcurrentOperationCount: Int {
        get { return super.maxConcurrentOperationCount }
        set {
            assert(newValue != 1, "`\(type(of:self))` must be concurrent to provide any benefit over a serial queue! 🙃")
            super.maxConcurrentOperationCount = newValue
        }
    }

    // MARK: - Public

    /**
     Adds the specified operation to the queue, and registers it the subgroup identified by `key`.

     Once added, the operation will only be executed after all currently existing operations in the same subgroup finish
     * executing (serial processing), but can be executed concurrently with other subgroup's operations.

     - parameter op:  The `NSOperation` to be added to the queue.
     - parameter key: The subgroup's identifier key.
     */
    @objc
    public func addOperation(_ op: Operation, withKey key: AnyHashable) {
        addOperations(subGroups.register(op, withKey: key), waitUntilFinished: false)
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
    @objc
    public func addOperations(_ ops: [Operation], withKey key: AnyHashable, waitUntilFinished wait: Bool) {
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
    @objc(addOperationWithBlock:andKey:)
    public func addOperation(_ block: @escaping () -> Void, withKey key: AnyHashable) {
        addOperations(subGroups.register(block, withKey: key), waitUntilFinished: false)
    }

    // MARK: SubGroup querying

    /**
     Return a snapshot of currently scheduled (i.e. non-finished) operations of the subgroup identified by `key`.

     - parameter key: The subgroup's identifier key.

     - returns: An `[NSOperation]` containing a snapshot of all currently scheduled (non-finished) subgroup operations.
     */
    public subscript(key: AnyHashable) -> [Operation] {
        return subGroups[key]
    }

    /**
     Return a snapshot of currently scheduled (i.e. non-finished) operations of the subgroup identified by `key`.

     - parameter key: The subgroup's identifier key.

     - returns: An `[NSOperation]` containing a snapshot of all currently scheduled (non-finished) subgroup operations.
     */
    @objc
    public func subGroupOperations(forKey key: AnyHashable) -> [Operation] {
        return subGroups[key]
    }
}
