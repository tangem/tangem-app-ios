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
        var task: Task<Void, Failure>?

        return Future<Output, Failure> { promise in
            task = Task {
                do {
                    let output = try await operation()
                    try Task.checkCancellation()
                    promise(.success(output))
                } catch {
                    promise(.failure(error))
                }
            }
        }.handleEvents(receiveCancel: {
            task?.cancel()
        })
    }
}

public extension Future where Failure == Never {
    static func async(operation: @escaping @Sendable () async -> Output) -> some Publisher<Output, Never> {
        var task: Task<Void, Never>?

        return Future<Output, Never> { promise in
            task = Task {
                let output = await operation()
                promise(.success(output))
            }
        }.handleEvents(receiveCancel: {
            task?.cancel()
        })
    }
}
