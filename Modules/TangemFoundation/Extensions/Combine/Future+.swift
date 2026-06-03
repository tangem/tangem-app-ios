//
//  Future+.swift
//  TangemFoundation
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

public extension Future where Failure == Error {
    static func async(operation: @escaping () async throws -> Output) -> some Publisher<Output, Failure> {
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
    static func async(operation: @escaping @Sendable () async -> Output) -> some Publisher<Output, Never> {
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
