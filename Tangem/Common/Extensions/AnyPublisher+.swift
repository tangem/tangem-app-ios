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
    func async() async throws -> Output {
        try await withCheckedThrowingContinuation({ continuation in
            var cancellable: AnyCancellable?

            cancellable = first()
                .sink(receiveCompletion: { result in
                    switch result {
                    case .finished:
                        break
                    case let .failure(error):
                        continuation.resume(throwing: error)
                    }
                    cancellable?.cancel()
                }, receiveValue: { output in
                    continuation.resume(returning: output)
                })
        })
    }
}
