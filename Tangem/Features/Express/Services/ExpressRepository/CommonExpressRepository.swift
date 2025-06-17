//
//  CommonExpressRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

actor CommonExpressRepository {
    private let walletModelsManager: WalletModelsManager
    private let expressAPIProvider: ExpressAPIProvider

    private var providers: [ExpressProvider] = []
    private var pairs: Set<ExpressPair> = []
    private var walletModels: [any WalletModel] {
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
    func providers() async throws -> [TangemExpress.ExpressProvider] {
        if !providers.isEmpty {
            return providers
        }

        let providers = try await expressAPIProvider.providers(branch: .swap)
        self.providers = providers
        return providers
    }

    func updatePairs(for wallet: TangemExpress.ExpressWallet) async throws {
        let currencies = walletModels
            .filter { $0.expressCurrency != wallet.expressCurrency }
            .map { $0.expressCurrency.asCurrency() }

        guard !currencies.isEmpty else { return }

        async let pairsTo = expressAPIProvider.pairs(from: [wallet.expressCurrency.asCurrency()], to: currencies)
        async let pairsFrom = expressAPIProvider.pairs(from: currencies, to: [wallet.expressCurrency.asCurrency()])

        try await pairs.formUnion(pairsTo.toSet())
        try await pairs.formUnion(pairsFrom.toSet())
    }

    func getAvailableProviders(for pair: ExpressManagerSwappingPair) async throws -> [ExpressProvider.Id] {
        if let availablePair = pairs.first(where: {
            $0.source == pair.source.currency.asCurrency() && $0.destination == pair.destination.currency.asCurrency()
        }) {
            return availablePair.providers
        }

        throw ExpressRepositoryError.availableProvidersDoesNotFound
    }

    func getPairs(to wallet: ExpressWallet) async -> [ExpressPair] {
        pairs.filter { $0.destination == wallet.expressCurrency.asCurrency() }.asArray
    }

    func getPairs(from wallet: ExpressWallet) async -> [ExpressPair] {
        pairs.filter { $0.source == wallet.expressCurrency.asCurrency() }.asArray
    }
}

enum ExpressRepositoryError: Error {
    case availableProvidersDoesNotFound
}
