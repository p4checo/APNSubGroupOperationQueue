//
//  CompletionOperation.swift
//  APNSubGroupOperationQueue
//
//  Created by André Pacheco Neves on 12/02/2017.
//  Copyright © 2017 André Pacheco Neves. All rights reserved.
//

import Foundation

/// `CompletionOperation` is a `BlockOperation` subclass which is used internally by the `SubGroupOperationQueue` to
/// remove completed operations from the subgroup dictionary.
///
/// For each operation submitted by the user to the queue, a `CompletionOperation` which depends on it is created
/// containing the logic to cleanup the subgroup dictionary. By doing this, the operation's `completionBlock` doesn't
/// have to be used, allowing the user full control over the operation, without introducing possible side-effects.
///
/// These operations aren't returned by either `subscript` or `subGroupOperations` even though they technically are in
/// the subgroup.
final class CompletionOperation: BlockOperation {}
