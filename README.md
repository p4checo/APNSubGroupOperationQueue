# APNSubGroupOperationQueue
[![license](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://raw.githubusercontent.com/p4checo/APNSubGroupOperationQueue/master/LICENSE)
[![release](https://img.shields.io/github/release/p4checo/APNSubGroupOperationQueue.svg)](https://github.com/p4checo/APNSubGroupOperationQueue/releases)
![platforms](https://img.shields.io/badge/platforms-iOS%20%7C%20OS%20X%20%7C%20tvOS%20%7C%20watchOS-lightgrey.svg)
[![Build Status](https://travis-ci.org/p4checo/APNSubGroupOperationQueue.svg?branch=master)](https://travis-ci.org/p4checo/APNSubGroupOperationQueue)
[![codecov.io](https://codecov.io/github/p4checo/APNSubGroupOperationQueue/coverage.svg?branch=master)](https://codecov.io/github/p4checo/APNSubGroupOperationQueue?branch=master)
[![Carthage](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![CocoaPods](https://img.shields.io/cocoapods/v/APNSubGroupOperationQueue.svg)](https://cocoapods.org/)
[![Swift 2.0](https://img.shields.io/badge/Swift-2.0-orange.svg?style=flat)](https://developer.apple.com/swift/)

Swift & Obj-C µFramework consisting of `NSOperationQueue` subclasses which allow scheduling operations in serial subgroups inside concurrent queues.

In some scenarios, operations scheduled in an `NSOperationQueue` depend on a subset of other operations and should be processed in order, but don't depend on the remaining operations in the queue.

So far, this could be solved by:
  - using separate queues for each subset of dependent operations (can become unmanageable, wasteful)
  - defining the queue as serial (sub-optimal performance)

With this µFramework, a single operation queue can be used to schedule all operations and obtain the best of both worlds.

Dependent operations are grouped into "subgroups" which are guaranteed to be processed in a serial fashion inside each subgroup, while operations from other subgroups are processed concurrently (while serial inside their own subgroup) and regular operations (i.e. without defined subgroup) are processed concurrently with all others. This is done by leveraging `NSOperation`s dependencies and using an auxiliary data structure to store all subgroups' operations.

## Use

### Swift
```swift
let subGroupQueue = SubGroupOperationQueue<String>()

// schedule operations in subgroups "A", "B" and "C"
// these will run serially inside each subgroup, but concurrently with other subgroups' operations

subGroupQueue.addOperation(opA1, key: "A")
subGroupQueue.addOperation(opA2, key: "A")
subGroupQueue.addOperation(opA3, key: "A")

subGroupQueue.addOperations([opB1, opB2, opB3], key: "B")

subGroupQueue.addOperationWithBlock({ /* opC1 */ }, key: "C")
subGroupQueue.addOperationWithBlock({ /* opC2 */ }, key: "C")
subGroupQueue.addOperationWithBlock({ /* opC3 */ }, key: "C")

// query current subgroup's operations (a snapshot)
let aOps = subGroupQueue["A"]
let bOps = subGroupQueue["B"]
let cOps = subGroupQueue.subGroupOperations("C")
```

### Objective-C
```objc
APNSubGroupOperationQueue *subGroupQueue = [APNSubGroupOperationQueue new];

// schedule operations in subgroups "A", "B" and "C"
// these will run serially inside each subgroup, but concurrently with other subgroups' operations
[subGroupQueue addOperation:opA1 withKey:@"A"];
[subGroupQueue addOperation:opA2 withKey:@"A"];
[subGroupQueue addOperation:opA2 withKey:@"A"];

[subGroupQueue addOperations::@[opB1, opB2, opB3] withKey:@"B" waitUntilFinished:false];

[subGroupQueue addOperationWithBlock:^{ /* opC1 */ } andKey:@"C"];
[subGroupQueue addOperationWithBlock:^{ /* opC2 */ } andKey:@"C"];
[subGroupQueue addOperationWithBlock:^{ /* opC3 */ } andKey:@"C"];

// query current subgroup's operations (a snapshot)
NSArray<NSOperation*> *aOps = [subGroupQueue subGroupOperationsForKey:@"A"];
NSArray<NSOperation*> *bOps = [subGroupQueue subGroupOperationsForKey:@"B"];
NSArray<NSOperation*> *cOps = [subGroupQueue subGroupOperationsForKey:@"C"];

// Objective-C implementation allows a more dynamic usage, since keys only need to be `id<NSCopying>`
[subGroupQueue addOperations::@[opN1, opN2, opN3] withKey:@1337 waitUntilFinished:false];

NSDate *date = [NSDate date];
[subGroupQueue addOperationWithBlock:^{ /* opD1 */ } andKey:date];
[subGroupQueue addOperationWithBlock:^{ /* opD2 */ } andKey:date];
```
## Integration

### CocoaPods
Add APNSubGroupOperationQueue to your `Podfile` and run `pod install`:

```ruby
# CocoaPods
pod 'APNSubGroupOperationQueue', '~> 1.0.0'
```

### Carthage

Add APNSubGroupOperationQueue to your `Cartfile` (package dependency) or `Cartfile.private`
(development dependency):

```
github "p4checo/APNSubGroupOperationQueue" ~> 1.0.0
```

### Swift Package Manager

TODO

### git Submodule

1. Add this repository as a submodule.
2. Drag APNSubGroupOperationQueue.xcodeproj into your project or workspace.
3. Link your target against APNSubGroupOperationQueue.framework of your platform.
4. If linking againts an Application target, ensure the framework gets copied into the bundle. If linking against a Framework target, the application linking to it should also include APNSubGroupOperationQueue.

## Future work

Use a simpler (and faster) synchronization mechanism like a SpinLock when a safe one one becomes available for iOS. Sources: [[1]](http://engineering.postmates.com/Spinlocks-Considered-Harmful-On-iOS/) [[2]](https://lists.swift.org/pipermail/swift-dev/Week-of-Mon-20151214/000321.html)