all: iOS macOS tvOS watchOS

iOS:
	set -o pipefail && xcodebuild test -project APNSubGroupOperationQueue.xcodeproj -scheme 'APNSubGroupOperationQueue iOS' -sdk iphonesimulator -destination "platform=iOS Simulator,name=iPhone 6s" -enableCodeCoverage YES | xcpretty

macOS:
	set -o pipefail && xcodebuild test -project APNSubGroupOperationQueue.xcodeproj -scheme 'APNSubGroupOperationQueue macOS' | xcpretty

tvOS:
	set -o pipefail && xcodebuild test -project APNSubGroupOperationQueue.xcodeproj -scheme 'APNSubGroupOperationQueue tvOS' -sdk appletvsimulator -destination "platform=tvOS Simulator,name=Apple TV 1080p" | xcpretty

watchOS:
	set -o pipefail && xcodebuild -project APNSubGroupOperationQueue.xcodeproj -scheme 'APNSubGroupOperationQueue watchOS' -sdk watchsimulator -destination "platform=watchOS Simulator,name=Apple Watch - 42mm" | xcpretty
