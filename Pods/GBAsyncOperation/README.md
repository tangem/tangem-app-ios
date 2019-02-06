# GBAsyncOperation

[![CI Status](https://img.shields.io/travis/aiwo/GBAsyncOperation.svg?style=flat)](https://travis-ci.org/aiwo/GBAsyncOperation)
[![Version](https://img.shields.io/cocoapods/v/GBAsyncOperation.svg?style=flat)](https://cocoapods.org/pods/GBAsyncOperation)
[![License](https://img.shields.io/cocoapods/l/GBAsyncOperation.svg?style=flat)](https://cocoapods.org/pods/GBAsyncOperation)
[![Platform](https://img.shields.io/cocoapods/p/GBAsyncOperation.svg?style=flat)](https://cocoapods.org/pods/GBAsyncOperation)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

None

## Installation

GBAsyncOperation is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'GBAsyncOperation'
```

## Usage

### Import
```swift
import GBAsyncOperation
```

### Subclassing a GBAsyncOperation

This is an example of a typical asynchronous operation subclass. For the proper operation lifecycle it is required to call ```finish()``` method upon async code completion. This will signal the operation that it should be finished, otherwise it will be stuck in the queue.

```swift
class MyAsyncOperation: GBAsyncOperation {

    // your properties
    
    var completion: () -> Void
    
    init(completion: @escaping () -> Void) {
        self.completion = completion 
    }

    override func main() {
        // your async code here, which eventually calls completeOperation()
    }

    func completeOperation() {
        guard !isCancelled else {
            return
        }
        
        completion()
        finish()
    }
}
```

### Bundling operations using a GBSerialGroupOperation

GBSerialGroupOperation class provides an ability of grouping asynchronous operations in a bundle and creating a dependency between them

```swift
```


## Author

Gennady Berezovsky

## License

GBAsyncOperation is available under the MIT license. See the LICENSE file for more info.
