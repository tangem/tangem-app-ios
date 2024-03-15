//
//  AnyPublisher+async.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine

extension Publisher where Failure: Error {
    func async() async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = first()
                .sink(receiveCompletion: { completion in
                    if case .failure(let failure) = completion {
                        continuation.resume(throwing: failure)
                    }
                }, receiveValue: { output in
                    continuation.resume(returning: output)
                    withExtendedLifetime(cancellable) {}
                })
        }
    }
}
