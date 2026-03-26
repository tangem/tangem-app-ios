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

    private lazy var expressAPIProviderResolver = ExpressAPIProviderResolver(
        providerFactory: { userWalletId, refcode in
            ExpressAPIProviderFactory().makeExpressAPIProvider(userId: userWalletId, refcode: refcode)
        }
    )

    private var pairs: Set<ExpressPair> = []

    private var userCurrencies: Set<ExpressWalletCurrency> {
        let walletModels = AccountsFeatureAwareWalletModelsResolver
            .walletModels(for: userWalletRepository.models)

        return walletModels.map { $0.tokenItem.expressCurrency }.toSet()
    }
}

// MARK: - ExpressPairsRepository

extension CommonExpressPairsRepository: ExpressPairsRepository {
    func updatePairs(from wallet: ExpressWalletCurrency, to currencies: [ExpressWalletCurrency], userWalletInfo: UserWalletInfo) async throws {
        guard !currencies.isEmpty else { return }

        let provider = expressAPIProviderResolver.provider(for: userWalletInfo.id.stringValue, refcode: userWalletInfo.refcode)
        let pairsTo = try await provider.pairs(from: [wallet], to: currencies.toSet())
        pairs.formUnion(pairsTo.toSet())
    }

    func updatePairs(for wallet: ExpressWalletCurrency, userWalletInfo: UserWalletInfo) async throws {
        let t0 = CFAbsoluteTimeGetCurrent()
        let currencies = userCurrencies.filter { $0 != wallet }
        let t1 = CFAbsoluteTimeGetCurrent()

        guard !currencies.isEmpty else { return }

        let provider = expressAPIProviderResolver.provider(for: userWalletInfo.id.stringValue, refcode: userWalletInfo.refcode)
        async let pairsTo = provider.pairs(from: [wallet], to: currencies)
        async let pairsFrom = provider.pairs(from: currencies, to: [wallet])

        let resolvedPairsTo = try await pairsTo
        let resolvedPairsFrom = try await pairsFrom
        let t2 = CFAbsoluteTimeGetCurrent()

        pairs.formUnion(resolvedPairsTo.toSet())
        pairs.formUnion(resolvedPairsFrom.toSet())
        let t3 = CFAbsoluteTimeGetCurrent()

        ExpressLogger.info("[Timing] updatePairs: currencies=\(currencies.count), userCurrencies=\(String(format: "%.3f", t1 - t0))s, network=\(String(format: "%.3f", t2 - t1))s, formUnion=\(String(format: "%.3f", t3 - t2))s, totalPairs=\(pairs.count)")
    }

    func getAvailableProviders(for pair: ExpressManagerSwappingPair, rateType: ExpressProviderRateType) async throws -> [ExpressProvider.Id] {
        let source = pair.source.currency.asCurrency
        let destination = pair.destination.currency.asCurrency

        let availablePair = pairs
            .first(where: { $0.source == source && $0.destination == destination })

        guard let availablePair else {
            return []
        }

        return availablePair.providers
            .filter { $0.rates.contains(rateType) }
            .map { $0.id }
    }

    func getPairs(to wallet: ExpressWalletCurrency) async -> [ExpressPair] {
        pairs.filter { $0.destination == wallet.asCurrency }.asArray
    }

    func getPairs(from wallet: ExpressWalletCurrency) async -> [ExpressPair] {
        pairs.filter { $0.source == wallet.asCurrency }.asArray
    }
}
