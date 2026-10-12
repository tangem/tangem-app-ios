//
//  CompositeAccountModelsProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import CombineExt
import TangemFoundation

/// Presents several providers as one, so `AccountModelsManager` keeps a single slot however many feature
/// accounts are synthesized locally rather than served by a repository.
struct CompositeAccountModelsProvider {
    private let providers: [any AccountModelsProvider]

    init(_ providers: [any AccountModelsProvider]) {
        self.providers = providers
    }
}

// MARK: - AccountModelsProvider protocol conformance

extension CompositeAccountModelsProvider: AccountModelsProvider {
    var accountModelsPublisher: AnyPublisher<[AccountModel], Never> {
        guard !providers.isEmpty else {
            return .just(output: [])
        }

        return providers
            .map(\.accountModelsPublisher)
            .combineLatest()
            .map { $0.flatMap { $0 } }
            .eraseToAnyPublisher()
    }
}
