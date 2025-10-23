//
//  CommonExpressPairsRepository.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress

actor CommonExpressPairsRepository {
    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository

    private var providers: [UserWalletInfo: any ExpressAPIProvider] = [:]
    private var pairs: Set<ExpressPair> = []

    private var userCurrencies: Set<ExpressWalletCurrency> {
        let walletModels = if FeatureProvider.isAvailable(.accounts) {
            userWalletRepository.models.compactMap {
                $0.accountModelsManager.accountModels.standard()
            }
            .flatMap { accountModel in
                switch accountModel {
                case .standard(.single(let cryptoAccountModel)): [cryptoAccountModel]
                case .standard(.multiple(let cryptoAccountModels)): cryptoAccountModels
                }
            }
            .flatMap { cryptoAccountModel in
                cryptoAccountModel.walletModelsManager.walletModels
            }
        } else {
            userWalletRepository.models.flatMap { userWalletModel in
                userWalletModel.walletModelsManager.walletModels
            }
        }

        return walletModels.map { $0.tokenItem.expressCurrency }.toSet()
    }

    init() {}

    private func provider(userWalletInfo: UserWalletInfo) -> any ExpressAPIProvider {
        if let provider = providers[userWalletInfo] {
            return provider
        }

        let provider = ExpressAPIProviderFactory().makeExpressAPIProvider(
            userWalletId: userWalletInfo.id,
            refcode: userWalletInfo.refcode
        )

        providers[userWalletInfo] = provider
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
