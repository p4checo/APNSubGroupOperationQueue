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

    fileprivate let queue: DispatchQueue
    fileprivate var subGroups: [Key : [Operation]]

    /**
     Instantiates a new `OperationSubGroupMap`.

     - returns: A new `OperationSubGroupMap` instance.
     */
    init() {
        queue = DispatchQueue(label: "com.p4checo.\(type(of: self)).queue",
                              attributes: DispatchQueue.Attributes.concurrent)
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
        var newOps = [Operation]()

        queue.sync(flags: .barrier, execute: { [unowned self] in
            var subGroup = self.subGroups[key] ?? []

            ops.forEach { op in
                let completionOp = self.createCompletionOperation(forOperation: op, withKey: key)
                self.setupDependencies(forOperation: op, completionOp: completionOp, subGroup: subGroup)

                let opPair = [op, completionOp]
                newOps.append(contentsOf: opPair)
                subGroup.append(contentsOf: opPair)
            }

            self.subGroups[key] = subGroup
        })

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
        var ops: [Operation]?

        queue.sync { [unowned self] in
            ops = self.subGroups[key]?.filter{ !($0 is CompletionOperation) }
        }

        return ops ?? []
    }

    // MARK: - Private

    fileprivate func setupDependencies(forOperation op: Operation,
                                       completionOp: CompletionOperation,
                                       subGroup: [Operation]) {
        completionOp.addDependency(op)

        // new operations only need to depend on the group's last operation
        if let lastOp = subGroup.last {
            op.addDependency(lastOp)
        }
    }

    fileprivate func createCompletionOperation(forOperation op: Operation, withKey key: Key) -> CompletionOperation {
        let completionOp = CompletionOperation()

        completionOp.addExecutionBlock({ [unowned self, weak weakCompletionOp = completionOp] in
            self.queue.sync(flags: .barrier, execute: { [unowned self] in
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
