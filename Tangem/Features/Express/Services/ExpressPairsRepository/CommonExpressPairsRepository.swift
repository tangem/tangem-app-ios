//
//  CommonExpressPairsRepository.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress
import TangemFoundation

actor CommonExpressPairsRepository {
    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository

    private var providers: [UserWalletId: any ExpressAPIProvider] = [:]
    private var pairs: Set<ExpressPair> = []

    private var userCurrencies: Set<ExpressWalletCurrency> {
        let walletModels = AccountsFeatureAwareWalletModelsResolver
            .walletModels(for: userWalletRepository.models)

        return walletModels.map { $0.tokenItem.expressCurrency }.toSet()
    }

    private func provider(userWalletInfo: UserWalletInfo) -> any ExpressAPIProvider {
        let key = userWalletInfo.id

        if let provider = providers[key] {
            return provider
        }

        let provider = ExpressAPIProviderFactory().makeExpressAPIProvider(
            userWalletId: userWalletInfo.id,
            refcode: userWalletInfo.refcode
        )

        providers[key] = provider
        return provider
    }
}

// MARK: - ExpressPairsRepository

extension CommonExpressPairsRepository: ExpressPairsRepository {
    func updatePairs(from wallet: ExpressWalletCurrency, to currencies: [ExpressWalletCurrency], userWalletInfo: UserWalletInfo) async throws {
        guard !currencies.isEmpty else { return }

        let provider = provider(userWalletInfo: userWalletInfo)
        let pairsTo = try await provider.pairs(from: [wallet], to: currencies.toSet())
        pairs.formUnion(pairsTo.toSet())
    }

    func updatePairs(for wallet: ExpressWalletCurrency, userWalletInfo: UserWalletInfo) async throws {
        let currencies = userCurrencies.filter { $0 != wallet }

        guard !currencies.isEmpty else { return }

        let provider = provider(userWalletInfo: userWalletInfo)
        async let pairsTo = provider.pairs(from: [wallet], to: currencies)
        async let pairsFrom = provider.pairs(from: currencies, to: [wallet])

        try await pairs.formUnion(pairsTo.toSet())
        try await pairs.formUnion(pairsFrom.toSet())
    }

    func getAvailableProviders(for pair: ExpressManagerSwappingPair) async throws -> [ExpressProvider.Id] {
        if let availablePair = pairs.first(where: {
            $0.source == pair.source.currency.asCurrency &&
                $0.destination == pair.destination.currency.asCurrency
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
