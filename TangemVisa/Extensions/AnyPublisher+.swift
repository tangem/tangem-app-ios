//
//  AnyPublisher+.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine

extension AnyPublisher where Failure == Never {
    func async() async -> Output {
        await withCheckedContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = first()
                .sink(receiveValue: { output in
                    continuation.resume(returning: output)
                    withExtendedLifetime(cancellable) {}
                })
        }
    }
}

extension AnyPublisher where Failure == Error {
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
