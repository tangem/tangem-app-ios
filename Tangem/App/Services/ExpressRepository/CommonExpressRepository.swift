//
//  CommonExpressRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSwapping

actor CommonExpressRepository {
    private let walletModelsManager: WalletModelsManager
    private let expressAPIProvider: ExpressAPIProvider

    private var providers: [ExpressProvider] = []
    private var pairs: Set<ExpressPair> = []

    private var updateTask: Task<Void, Error>?
    private var walletModels: [WalletModel] {
        walletModelsManager.walletModels.filter { !$0.isCustom }
    }

    init(
        walletModelsManager: WalletModelsManager,
        expressAPIProvider: ExpressAPIProvider

    ) {
        self.walletModelsManager = walletModelsManager
        self.expressAPIProvider = expressAPIProvider
    }
}

extension CommonExpressRepository: ExpressRepository {
    func providers() async throws -> [TangemSwapping.ExpressProvider] {
        if !providers.isEmpty {
            return providers
        }

        let providers = try await expressAPIProvider.providers()
        self.providers = providers
        return providers
    }

    func updatePairs(for wallet: TangemSwapping.ExpressWallet) async throws {
        let currencies = walletModels
            .filter { $0.expressCurrency != wallet.expressCurrency }
            .map { $0.expressCurrency }

        guard !currencies.isEmpty else { return }

        async let pairsTo = expressAPIProvider.pairs(from: [wallet.expressCurrency], to: currencies)
        async let pairsFrom = expressAPIProvider.pairs(from: currencies, to: [wallet.expressCurrency])

        try await pairsTo.toSet().forEach { pairs.insert($0) }
        try await pairsFrom.toSet().forEach { pairs.insert($0) }
    }

    func getAvailableProviders(for pair: ExpressManagerSwappingPair) async throws -> [ExpressProvider.Id] {
        if let availablePair = pairs.first(where: { $0.source == pair.source.expressCurrency && $0.destination == pair.destination.expressCurrency }) {
            return availablePair.providers
        }

        throw ExpressRepositoryError.availablePairNotFound
    }
}

enum ExpressRepositoryError: Error {
    case availablePairNotFound
}
