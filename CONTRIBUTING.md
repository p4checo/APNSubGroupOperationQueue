# Contributing

All contributions are welcomed for this project! Nothing is off limits.

If you found a problem, [file an issue](https://github.com/p4checo/APNSubGroupOperationQueue/issues/new).

If you just want to contribute, feel free to look through the [issues
list](https://github.com/p4checo/APNSubGroupOperationQueue/issues), or
simply submit a PR with your idea!

## Reporting Bugs

As swift evolves, this project may become out date. Feel free to file
issues to report problems. Be sure to include:

- What platform are you building for? (eg - iOS 9.3, Xcode 7.3)
- What package manager are you using? (eg - Cocoapods 0.39.0)
    - Swift Package Manager based on what version of swift you're using
    - Cocoapods version can be retrieved via: `pod --version`
    - Carthage version can be retrieved via: `carthage version`
- What is your target configuration? (iOS App, OS X Framework, etc.)

## Pull Requests

Please try to minimize the amount of commits in your pull request. 
The goal is to keep the history readable.

Always rebase your changes onto master before submitting your PR's.

Please write [good](http://chris.beams.io/posts/git-commit/) commit messages:

  - Separate subject from body with a blank line
  - Limit the subject line to 50 characters
  - Capitalize the subject line
  - Do not end the subject line with a period
  - Use the imperative mood in the subject line
  - Wrap the body at 72 characters
  - Use the body to explain what and why vs. how

If you need to modify/squash existing commits you've made, use [rebase
interactive](https://git-scm.com/book/en/v2/Git-Tools-Rewriting-History).

If your PR includes Objective-C code, please apply [`clang-format`](http://clang.llvm.org/docs/ClangFormat.html) to it.
You can use the awesome [ClangFormat-Xcode](https://github.com/travisjeffery/ClangFormat-Xcode) plugin to make it easier.
