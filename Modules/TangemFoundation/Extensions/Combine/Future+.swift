//
//  Future+.swift
//  TangemFoundation
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

// MARK: - Async operation bridging

public extension Future where Failure == Error {
    static func async(
        _ operation: @escaping @Sendable () async throws -> Output
    ) -> some Publisher<Output, Failure> {
        let cancellableWrapper = ThreadSafeCancellableWrapper()

        return Future<Output, Failure> { promise in
            let task = Task {
                do {
                    let output = try await operation()
                    try Task.checkCancellation()
                    promise(.success(output))
                } catch {
                    promise(.failure(error))
                }
            }
            cancellableWrapper.set(task.eraseToAnyCancellable())
        }.handleEvents(receiveCancel: {
            cancellableWrapper.cancel()
        })
    }
}

public extension Future where Failure == Never {
    static func async(
        _ operation: @escaping @Sendable () async -> Output
    ) -> some Publisher<Output, Never> {
        let cancellableWrapper = ThreadSafeCancellableWrapper()

        return Future<Output, Never> { promise in
            let task = Task {
                let output = await operation()
                promise(.success(output))
            }
            cancellableWrapper.set(task.eraseToAnyCancellable())
        }.handleEvents(receiveCancel: {
            cancellableWrapper.cancel()
        })
    }
}

// MARK: - Async stream bridging

public extension Publishers {
    static func stream<Element>(
        _ makeStream: @escaping @Sendable () -> AsyncStream<Element>
    ) -> some Publisher<Element, Never> {
        Deferred {
            let subject = CurrentValueSubject<Element?, Never>(nil)
            let task = Task {
                for await element in makeStream() {
                    subject.send(element)
                }

                subject.send(completion: .finished)
            }

            return subject
                .compactMap(\.self)
                .handleEvents(receiveCancel: {
                    task.cancel()
                })
        }
    }
}
