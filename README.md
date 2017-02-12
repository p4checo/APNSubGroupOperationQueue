# APNSubGroupOperationQueue
[![license](https://img.shields.io/badge/license-MIT-lightgrey.svg)](https://raw.githubusercontent.com/p4checo/APNSubGroupOperationQueue/master/LICENSE)
[![release](https://img.shields.io/github/release/p4checo/APNSubGroupOperationQueue.svg)](https://github.com/p4checo/APNSubGroupOperationQueue/releases)
![platforms](https://img.shields.io/badge/platforms-iOS%20%7C%20OS%20X%20%7C%20tvOS%20%7C%20watchOS-lightgrey.svg)
[![Build Status](https://travis-ci.org/p4checo/APNSubGroupOperationQueue.svg?branch=master)](https://travis-ci.org/p4checo/APNSubGroupOperationQueue)
[![codecov.io](https://codecov.io/github/p4checo/APNSubGroupOperationQueue/coverage.svg?branch=master)](https://codecov.io/github/p4checo/APNSubGroupOperationQueue?branch=master)
[![Docs](https://img.shields.io/cocoapods/metrics/doc-percent/APNSubGroupOperationQueue.svg)](http://cocoadocs.org/docsets/APNSubGroupOperationQueue)
[![Carthage](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![CocoaPods](https://img.shields.io/cocoapods/v/APNSubGroupOperationQueue.svg)](https://cocoapods.org/)
[![Swift 3.0](https://img.shields.io/badge/Swift-3.0-orange.svg?style=flat)](https://developer.apple.com/swift/)

Swift & Obj-C µFramework consisting of `NSOperationQueue` subclasses which allow scheduling operations in serial subgroups inside concurrent queues.

In some scenarios, operations scheduled in an `NSOperationQueue` depend on a subset of other operations and should be processed in order, but don't depend on the remaining operations in the queue.

So far, this could be solved by:
  - using separate queues for each subset of dependent operations (can become unmanageable, wasteful)
  - defining the queue as serial (sub-optimal performance)

With this µFramework, a single operation queue can be used to schedule all operations and obtain the best of both worlds.

Dependent operations are grouped into "subgroups" which are guaranteed to be processed in a serial fashion inside each subgroup, while operations from other subgroups are processed concurrently (while serial inside their own subgroup) and regular operations (i.e. without defined subgroup) are processed concurrently with all others. This is done by leveraging `NSOperation`s dependencies and using an auxiliary data structure to store all subgroups' operations.

## Use

### Swift

#### Single SubGroup Key type 
```swift
@import APNSubGroupOperationQueue

let subGroupQueue = SubGroupOperationQueue<String>()

// schedule operations in subgroups "A", "B" and "C"
// these will run serially inside each subgroup, but concurrently with other subgroups' operations

subGroupQueue.addOperation(opA1, withKey: "A")
subGroupQueue.addOperation(opA2, withKey: "A")
subGroupQueue.addOperation(opA3, withKey: "A")

subGroupQueue.addOperations([opB1, opB2, opB3], withKey: "B")

subGroupQueue.addOperation({ /* opC1 */ }, withKey: "C")
subGroupQueue.addOperation({ /* opC2 */ }, withKey: "C")
subGroupQueue.addOperation({ /* opC3 */ }, withKey: "C")

// query current subgroup's operations (a snapshot)
let aOps = subGroupQueue["A"]
let bOps = subGroupQueue["B"]
let cOps = subGroupQueue.subGroupOperations(forKey: "C")
```

#### Multiple SubGroup Key types (must conform to `AnyHashable`)
```swift
@import APNSubGroupOperationQueue

let dynamicSubGroupQueue = SubGroupQueue<AnyHashable> // or simply a `DynamicSubGroupOperationQueue`

dynamicSubGroupQueue.addOperation(opX1, withKey: "X")
dynamicSubGroupQueue.addOperation(opX2, withKey: "X")
dynamicSubGroupQueue.addOperation(opX3, withKey: "X")

dynamicSubGroupQueue.addOperations([opN1, opN2, opN3], withKey: 1337)

let date = Date()
dynamicSubGroupQueue.addOperation({ /* opD1 */ }, withKey: date)
dynamicSubGroupQueue.addOperation({ /* opD2 */ }, withKey: date)
dynamicSubGroupQueue.addOperation({ /* opD3 */ }, withKey: date)

// query current subgroup's operations (a snapshot)
let xOps = subGroupQueue["X"]
let nOps = subGroupQueue[1337]
let dOps = subGroupQueue.subGroupOperations(forKey: date)
```

### Objective-C
```objc
@import APNSubGroupOperationQueue;

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

// Objective-C uses a `DynamicSubGroupOperationQueue` which allows a more flexible usage, since keys only need to be `NSObject`'s (`AnyHashable`)
[subGroupQueue addOperations:@[opN1, opN2, opN3] withKey:@1337 waitUntilFinished:false];

NSDate *date = [NSDate date];
[subGroupQueue addOperationWithBlock:^{ /* opD1 */ } andKey:date];
[subGroupQueue addOperationWithBlock:^{ /* opD2 */ } andKey:date];
```
## Integration

### CocoaPods
Add APNSubGroupOperationQueue to your `Podfile` and run `pod install`:

```ruby
# CocoaPods
pod 'APNSubGroupOperationQueue', '~> 2.0'
```

### Carthage

Add APNSubGroupOperationQueue to your `Cartfile` (package dependency) or `Cartfile.private`
(development dependency):

```
github "p4checo/APNSubGroupOperationQueue" ~> 2.0
```

### Swift Package Manager

Add APNSubGroupOperationQueue to your `Package.swift`:

```swift
import PackageDescription

let package = Package(
  name: "HelloWorld",
  dependencies: [
    .Package(url: "https://github.com/p4checo/APNSubGroupOperationQueue.git", majorVersion: 2),
  ]
)
```

### git Submodule

1. Add this repository as a submodule.
2. Drag APNSubGroupOperationQueue.xcodeproj into your project or workspace.
3. Link your target against APNSubGroupOperationQueue.framework of your platform.
4. If linking againts an Application target, ensure the framework gets copied into the bundle. If linking against a Framework target, the application linking to it should also include APNSubGroupOperationQueue.

## Contributing

See [CONTRIBUTING](https://github.com/p4checo/APNSubGroupOperationQueue/blob/master/CONTRIBUTING.md).

## Future work

Use a simpler (and faster) synchronization mechanism like a SpinLock when a safe one one becomes available for iOS. Sources: [[1]](http://engineering.postmates.com/Spinlocks-Considered-Harmful-On-iOS/) [[2]](https://lists.swift.org/pipermail/swift-dev/Week-of-Mon-20151214/000321.html)
