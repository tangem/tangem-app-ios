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
    private var userCurrencies: [ExpressWalletCurrency] {
        walletModelsManager.walletModels.filter { !$0.isCustom }.map { $0.tokenItem.expressCurrency }
    }

    init(
        walletModelsManager: WalletModelsManager,
        expressAPIProvider: ExpressAPIProvider,
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

    func updatePairs(from wallet: ExpressWalletCurrency, to currencies: [ExpressWalletCurrency]) async throws {
        guard !currencies.isEmpty else { return }

        let pairsTo = try await expressAPIProvider.pairs(from: [wallet], to: currencies)
        pairs.formUnion(pairsTo.toSet())
    }

    func updatePairs(for wallet: TangemExpress.ExpressWalletCurrency) async throws {
        let currencies = userCurrencies.filter { $0 != wallet }

        guard !currencies.isEmpty else { return }

        async let pairsTo = expressAPIProvider.pairs(from: [wallet], to: currencies)
        async let pairsFrom = expressAPIProvider.pairs(from: currencies, to: [wallet])

        try await pairs.formUnion(pairsTo.toSet())
        try await pairs.formUnion(pairsFrom.toSet())
    }

    func getAvailableProviders(for pair: ExpressManagerSwappingPair) async throws -> [ExpressProvider.Id] {
        if let availablePair = pairs.first(where: {
            $0.source == pair.source.currency.asCurrency && $0.destination == pair.destination.currency.asCurrency
        }) {
            return availablePair.providers
        }

        throw ExpressRepositoryError.availableProvidersDoesNotFound
    }

    func getPairs(to wallet: ExpressWalletCurrency) async -> [ExpressPair] {
        pairs.filter { $0.destination == wallet.asCurrency }.asArray
    }

    func getPairs(from wallet: ExpressWalletCurrency) async -> [ExpressPair] {
        pairs.filter { $0.source == wallet.asCurrency }.asArray
    }
}

enum ExpressRepositoryError: Error {
    case availableProvidersDoesNotFound
}
