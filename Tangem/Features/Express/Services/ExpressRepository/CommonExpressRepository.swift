//
//  CommonExpressRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import TangemFoundation

actor CommonExpressRepository {
    @Injected(\.expressPairsRepository)
    private var expressPairsRepository: ExpressPairsRepository

    private let expressAPIProvider: ExpressAPIProvider
    private var expressProviders: [ExpressProvider] = []

    init(expressAPIProvider: ExpressAPIProvider) {
        self.expressAPIProvider = expressAPIProvider
    }
}

// MARK: - ExpressRepository

extension CommonExpressRepository: ExpressRepository {
    func providers() async throws -> [TangemExpress.ExpressProvider] {
        if !expressProviders.isEmpty {
            return expressProviders
        }

        let providers = try await expressAPIProvider.providers(branch: .swap)
        expressProviders = providers
        return providers
    }

    func getAvailableProviders(for pair: ExpressManagerSwappingPair) async throws -> [ExpressProvider.Id] {
        try await expressPairsRepository.getAvailableProviders(for: pair)
    }
}

enum ExpressRepositoryError: Error {
    case availableProvidersDoesNotFound
}
