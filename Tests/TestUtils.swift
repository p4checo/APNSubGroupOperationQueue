//
//  TestUtils.swift
//  APNSubGroupOperationQueue
//
//  Created by André Pacheco Neves on 12/02/2017.
//  Copyright © 2017 André Pacheco Neves. All rights reserved.
//

import Foundation

class Box<T> {
    var value: T
    init(_ v: T) { value = v }
}

func splitString(_ string: String) -> [String] {
    return string.map { String($0) }
}

func stringAppendingBlocks(for strings: [String], sharedBox: Box<String>) -> [() -> Void] {
    return strings.map { s in { sharedBox.value += s } }
}

func stringAppendingBlockOperations(for strings: [String], sharedBox: Box<String>) -> [BlockOperation] {
    return strings.map { s in BlockOperation(block: { sharedBox.value += s }) }
}
