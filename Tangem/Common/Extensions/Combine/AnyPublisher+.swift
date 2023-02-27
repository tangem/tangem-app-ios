//
//  AnyPublisher+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import Combine

extension AnyPublisher {
    static func just(output: Output) -> AnyPublisher<Output, Never> {
        Just(output).eraseToAnyPublisher()
    }

    func async() async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?

            cancellable = first()
                .sink { completion in
                    if case .failure(let error) = completion {
                        continuation.resume(throwing: error)
                    }
                    cancellable?.cancel()
                } receiveValue: { output in
                    continuation.resume(returning: output)
                }
        }
    }
}
