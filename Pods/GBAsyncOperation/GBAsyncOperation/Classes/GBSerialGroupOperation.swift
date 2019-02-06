//
//  GBSerialGroupOperation.swift
//  GBAsyncOperation
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation

/// A class that provides an ability of grouping asynchronous operations in a bundle and creating a dependency between them

open class GBSerialGroupOperation: GBAsyncOperation {

    let internalQueue = OperationQueue()

    /**
     initializes the group with an operation array.

     - Parameter operations: Operations collection. Operations will be queue in the order of the array.
     */
    public init(operations: [GBBaseOperation]) {
        internalQueue.isSuspended = true

        super.init()

        operations.forEach({ self.addOperation(operation: $0) })
    }

    /**
     Adds an operation into a serial group

     - Parameter operation: The operation that will be queued.
     */
    public func addOperation(operation: GBBaseOperation) {
        guard !isExecuting, !isCancelled else {
            assertionFailure("You cannot add operations to already running or cancelled group")
            return
        }

        if !internalQueue.operations.isEmpty {
            guard let lastOperation = internalQueue.operations.last as? GBBaseOperation else {
                assertionFailure("Only `GBBaseOperation` instances are allowed to be running in the internal queue")
                return
            }
            operation.addCancellableDependency(operation: lastOperation)
        }

        internalQueue.addOperation(operation)
    }

    open override func start() {
        guard !isCancelled else {
            return
        }

        // This operation acts as a signal of either
        // the internal queue depletion or the cancellation of the group
        
        let completionOperation = GBBlockOperation {
            self.finish()
        }
        completionOperation.cancellationBlock = {
            self.cancel()
        }
        addOperation(operation: completionOperation)

        super.start()
    }

    open override func main() {
        guard !isCancelled else {
            return
        }

        internalQueue.isSuspended = false
    }

    open override func cancel() {
        internalQueue.cancelAllOperations()
        super.cancel()
    }
}
