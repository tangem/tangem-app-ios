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
        let cancellableWrapper = ThreadSafeCancellableWrapper()

        return try await withTaskCancellationHandler {
            return try await withCheckedThrowingContinuation { continuation in
                let continuationWrapper = ResumableOnceCheckedContinuationWrapper(continuation)

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
                    .store(in: cancellableWrapper)
            }
        } onCancel: {
            cancellableWrapper.cancel()
        }
    }
}

// MARK: - Auxiliary types

enum AsyncError: Error {
    case valueWasNotEmittedBeforeCompletion
}
