//
//  UnfairLock.swift
//  APNSubGroupOperationQueue
//
//  Created by André Pacheco Neves on 15/09/2018.
//  Copyright © 2018 André Pacheco Neves. All rights reserved.
//

import Foundation
import os

/// Wrapper class around an `os_unfair_lock_t`.
final class UnfairLock {

    /// The wrapped unfair lock.
    private let _lock: os_unfair_lock_t

    /// Instantiates a new `UnfairLock`.
    init() {
        _lock = .allocate(capacity: 1)
        _lock.initialize(to: os_unfair_lock())
    }

    /// Locks the lock.
    func lock() {
        os_unfair_lock_lock(_lock)
    }

    /// Unlocks the lock.
    func unlock() {
        os_unfair_lock_unlock(_lock)
    }

    deinit {
        _lock.deinitialize(count: 1)
        _lock.deallocate()
    }
}
