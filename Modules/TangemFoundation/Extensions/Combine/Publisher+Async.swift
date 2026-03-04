//
//  Publisher+Async.swift
//  TangemFoundation
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine
import Foundation

public extension Publisher {
    func async() async throws -> Output {
        let subscriptionCancellableWrapper = ThreadSafeCancellableWrapper()
        let continuationCancellableWrapper = ThreadSafeCancellableWrapper()

        return try await withTaskCancellationHandler {
            return try await withCheckedThrowingContinuation { continuation in
                let continuationWrapper = ResumableOnceCheckedContinuationWrapper(continuation)

                // Prevents a potential race condition when Combine subscription is cancelled
                // immediately after creation (race between `onCancel` and `.store()` calls).
                // Without it, the cancellation may leak without resuming the continuation, which ultimately will hang the task.
                continuationCancellableWrapper.set(
                    AnyCancellable { continuationWrapper.resumeIfNeeded(throwing: CancellationError()) }
                )

                // This check is necessary in case this code runs after the task was
                // cancelled. In which case we want to bail right away.
                guard !Task.isCancelled else {
                    continuationWrapper.resumeIfNeeded(throwing: CancellationError())
                    return
                }

                return first()
                    .handleEvents(receiveCancel: {
                        // We don't get a cancel error when cancelling a publisher, so we need
                        // to handle if the publisher was cancelled from the
                        // `withTaskCancellationHandler` here.
                        continuationWrapper.resumeIfNeeded(throwing: CancellationError())
                    })
                    .sink(
                        receiveCompletion: { completion in
                            switch completion {
                            case .finished:
                                continuationWrapper.resumeIfNeeded(throwing: AsyncError.valueWasNotEmittedBeforeCompletion)
                            case .failure(let error):
                                continuationWrapper.resumeIfNeeded(throwing: error)
                            }
                        },
                        receiveValue: { value in
                            continuationWrapper.resumeIfNeeded(returning: value)
                        }
                    )
                    .store(in: subscriptionCancellableWrapper)
            }
        } onCancel: {
            subscriptionCancellableWrapper.cancel()
            continuationCancellableWrapper.cancel()
        }
    }
}

// MARK: - Auxiliary types

enum AsyncError: Error {
    case valueWasNotEmittedBeforeCompletion
}
