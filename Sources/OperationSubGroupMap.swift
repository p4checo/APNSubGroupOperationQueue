//
//  OperationSubGroupMap.swift
//  APNSubGroupOperationQueue
//
//  Created by André Pacheco Neves on 12/02/2017.
//  Copyright © 2017 André Pacheco Neves. All rights reserved.
//

import Foundation

/**
 `OperationSubGroupMap` is a class which contains an `OperationQueue`'s serial subgroups and synchronizes access to
 them.
 
 The subgroups are stored as a `[Key : [Operation]]`, and each subgroup array contains all the scheduled subgroup's
 operations which are pending and executing. Finished `Operation`s are automatically removed from the subgroup after
 completion.
 */
final class OperationSubGroupMap<Key: Hashable> {

    fileprivate let lock: UnfairLock
    fileprivate var subGroups: [Key : [Operation]]

    /**
     Instantiates a new `OperationSubGroupMap`.

     - returns: A new `OperationSubGroupMap` instance.
     */
    init() {
        lock = UnfairLock()
        subGroups = [:]
    }

    // MARK: - Public

    /**
     Register the specified operation in the subgroup identified by `key`, and create a `CompletionOperation` to ensure 
     the operation is removed from the subgroup on completion.

     Once added to the `OperationQueue`, the operation will only be executed after all currently existing operations in 
     the same subgroup finish executing (serial processing), but can be executed concurrently with other subgroups' 
     operations.

     - parameter op:  The `Operation` to be added to the queue.
     - parameter key: The subgroup's identifier key.
     
     - returns: An `[Operation]` containing the registered operation `op` and it's associated `CompletionOperation`, 
     which *must* both be added to the `OperationQueue`.
     */
    func register(_ op: Operation, withKey key: Key) -> [Operation] {
        return register([op], withKey: key)
    }

    /**
     Wrap the specified block in a `BlockOperation`, register it in the subgroup identified by `key`, and create a
     `CompletionOperation` to ensure the operation is removed from the subgroup on completion.

     Once added to the `OperationQueue`, the operation will only be executed after all currently existing operations in
     the same subgroup finish executing (serial processing), but can be executed concurrently with other subgroups'
     operations.

     - parameter op:  The `Operation` to be added to the queue.
     - parameter key: The subgroup's identifier key.

     - returns: An `[Operation]` containing the registered operation `op` and it's associated `CompletionOperation`,
     which both *must* be added to the `OperationQueue`.
     */
    func register(_ block: @escaping () -> Void, withKey key: Key) -> [Operation] {
        return register([BlockOperation(block: block)], withKey: key)
    }

    /**
     Register the specified operations in the subgroup identified by `key`, and creates `CompletionOperation`'s to 
     ensure the operations are removed from the subgroup on completion.

     Once added to the `OperationQueue`, the operations will be executed in order after all currently existing 
     operations in the same subgroup finish executing (serial processing), but can be executed concurrently with other 
     subgroup's operations.

     - parameter ops:  The `[Operation]` to be added to the queue.
     - parameter key: The subgroup's identifier key.

     - returns: An `[Operation]` containing the registered operation `ops` and their associated `CompletionOperation`,
     which *must* all be added to the `OperationQueue`.
     */
    func register(_ ops: [Operation], withKey key: Key) -> [Operation] {
        lock.lock()
        defer { lock.unlock() }

        var newOps = [Operation]()
        var subGroup = subGroups[key] ?? []

        ops.forEach { op in
            let completionOp = createCompletionOperation(for: op, withKey: key)
            setupDependencies(for: op, completionOp: completionOp, subGroup: subGroup)

            let opPair = [op, completionOp]
            newOps.append(contentsOf: opPair)
            subGroup.append(contentsOf: opPair)
        }

        subGroups[key] = subGroup

        return newOps
    }

    // MARK: SubGroup querying

    /**
     Return a snapshot of currently scheduled (i.e. non-finished) operations of the subgroup identified by `key`.

     - parameter key: The subgroup's identifier key.

     - returns: An `[Operation]` containing a snapshot of all currently scheduled (non-finished) subgroup operations.
     */
    public subscript(key: Key) -> [Operation] {
        return operations(forKey: key)
    }

    /**
     Return a snapshot of currently scheduled (i.e. non-finished) operations of the subgroup identified by `key`.

     - parameter key: The subgroup's identifier key.

     - returns: An `[Operation]` containing a snapshot of all currently scheduled (non-finished) subgroup operations.
     */
    public func operations(forKey key: Key) -> [Operation] {
        lock.lock()
        defer { lock.unlock() }

        return subGroups[key]?.filter { !($0 is CompletionOperation) } ?? []
    }

    // MARK: - Private

    private func setupDependencies(for op: Operation, completionOp: CompletionOperation, subGroup: [Operation]) {
        completionOp.addDependency(op)

        // new operations only need to depend on the group's last operation
        if let lastOp = subGroup.last {
            op.addDependency(lastOp)
        }
    }

    private func createCompletionOperation(for op: Operation, withKey key: Key) -> CompletionOperation {
        let completionOp = CompletionOperation()

        completionOp.addExecutionBlock { [unowned self, weak weakCompletionOp = completionOp] in
            self.lock.lock()
            defer { self.lock.unlock() }

            guard let completionOp = weakCompletionOp else {
                assertionFailure("💥: The completion operation must not be nil")
                return
            }

            guard var subGroup = self.subGroups[key] else {
                assertionFailure("💥: A group must exist in the dicionary for the finished operation's key!")
                return
            }

            assert([op, completionOp] == subGroup[0...1],
                   "💥: op and completionOp must be the first 2 elements in the subgroup's array")

            self.subGroups[key] = subGroup.count == 2 ? nil : {
                subGroup.removeFirst(2)
                return subGroup
                }()
        }
        
        return completionOp
    }
}
