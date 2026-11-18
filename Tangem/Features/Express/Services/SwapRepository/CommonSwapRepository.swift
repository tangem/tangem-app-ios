//
//  CommonSwapRepository.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress
import TangemFoundation

actor CommonSwapRepository {
    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository

    private let cachingExpressAPIProviderFactory: CachingExpressAPIProviderFactory

    private var pairsByWalletId: [String: Set<ExpressPair>] = [:]
    private var cachedExpressProvidersByWalletId: [String: [ExpressProvider]] = [:]

    init(
        providerFactory: @escaping CachingExpressAPIProviderFactory.Factory = { userWalletId, refcode in
            ExpressAPIProviderFactory().makeExpressAPIProvider(userId: userWalletId, refcode: refcode)
        }
    ) {
        cachingExpressAPIProviderFactory = CachingExpressAPIProviderFactory(providerFactory: providerFactory)
    }

    private var userCurrencies: Set<ExpressWalletCurrency> {
        let tokenItems = AccountTokenItemsAggregator.tokenItems(from: userWalletRepository.models)

        return tokenItems.map(\.expressCurrency).toSet()
    }
}

// MARK: - SwapRepository

extension CommonSwapRepository: SwapRepository {
    func updatePairs(
        from wallet: ExpressWalletCurrency,
        to currencies: [ExpressWalletCurrency],
        userWalletInfo: UserWalletInfo
    ) async throws {
        guard !currencies.isEmpty else { return }

        let walletId = userWalletInfo.id.stringValue
        let provider = cachingExpressAPIProviderFactory.provider(for: walletId, refcode: userWalletInfo.refcode)
        let pairsTo = try await provider.pairs(from: [wallet], to: currencies.toSet())
        pairsByWalletId[walletId, default: []].formUnion(pairsTo.toSet())
    }

    func updatePairs(for wallet: ExpressWalletCurrency, userWalletInfo: UserWalletInfo) async throws {
        let currencies = userCurrencies.filter { $0 != wallet }

        guard !currencies.isEmpty else { return }

        let walletId = userWalletInfo.id.stringValue
        let provider = cachingExpressAPIProviderFactory.provider(for: walletId, refcode: userWalletInfo.refcode)
        async let pairsTo = provider.pairs(from: [wallet], to: currencies)
        async let pairsFrom = provider.pairs(from: currencies, to: [wallet])

        try await pairsByWalletId[walletId, default: []].formUnion(pairsTo.toSet())
        try await pairsByWalletId[walletId, default: []].formUnion(pairsFrom.toSet())
    }

    func getAvailableProvidersIds(
        for pair: ExpressManagerSwappingPair,
        rateType: ExpressProviderRateType?
    ) async -> [ExpressProvider.Id] {
        let providers = getAvailableProviders(for: pair, rateType: rateType)

        return providers.map(\.id)
    }

    func getPairs(from wallet: ExpressWalletCurrency, userWalletInfo: UserWalletInfo) async -> [ExpressPair] {
        pairs(walletId: userWalletInfo.id.stringValue).filter { $0.source == wallet.asCurrency }
    }

    func providers(userWalletInfo: UserWalletInfo) async throws -> [ExpressProvider] {
        try await fetchProvidersIfNeeded(walletId: userWalletInfo.id.stringValue, refcode: userWalletInfo.refcode)
    }

    // MARK: - ExpressRepository

    func updateProvidersIds(for pair: ExpressManagerSwappingPair) async throws {
        let walletInfo = pair.source.walletInfo
        let wallet = pair.source.currency
        let destination = pair.destination.currency
        let currencies = userCurrencies.filter { $0 != wallet }

        guard !currencies.isEmpty else { return }

        let cachedPairs = pairs(walletId: walletInfo.id).filter { $0.source == wallet.asCurrency }
        let isPairCached = cachedPairs.contains { $0.destination == destination.asCurrency }

        let refcode = walletInfo.refcode.flatMap { Refcode(rawValue: $0) }
        let provider = cachingExpressAPIProviderFactory.provider(for: walletInfo.id, refcode: refcode)
        cachedExpressProvidersByWalletId[walletInfo.id] = nil

        if isPairCached {
            return
        }

        async let pairsTo = provider.pairs(from: [wallet], to: currencies)
        async let pairsFrom = provider.pairs(from: currencies, to: [wallet])

        try await pairsByWalletId[walletInfo.id, default: []].formUnion(pairsTo.toSet())
        try await pairsByWalletId[walletInfo.id, default: []].formUnion(pairsFrom.toSet())
    }

    func providers(for pair: ExpressManagerSwappingPair) async throws -> [ExpressProvider] {
        let walletInfo = pair.source.walletInfo
        let refcode = walletInfo.refcode.flatMap { Refcode(rawValue: $0) }
        return try await fetchProvidersIfNeeded(walletId: walletInfo.id, refcode: refcode)
    }
}

private extension CommonSwapRepository {
    func pairs(walletId: String) -> Set<ExpressPair> {
        pairsByWalletId[walletId] ?? []
    }

    func fetchProvidersIfNeeded(walletId: String, refcode: Refcode?) async throws -> [ExpressProvider] {
        if let cachedExpressProviders = cachedExpressProvidersByWalletId[walletId], !cachedExpressProviders.isEmpty {
            return cachedExpressProviders
        }

        let provider = cachingExpressAPIProviderFactory.provider(for: walletId, refcode: refcode)
        let providers = try await provider.providers(branch: ExpressBranch.swap)
        cachedExpressProvidersByWalletId[walletId] = providers
        return providers
    }

    func getAvailableProviders(
        for pair: ExpressManagerSwappingPair,
        rateType: ExpressProviderRateType?
    ) -> [ExpressPairProvider] {
        let source = pair.source.currency.asCurrency
        let destination = pair.destination.currency.asCurrency

        let availablePair = pairs(walletId: pair.source.walletInfo.id)
            .first(where: { $0.source == source && $0.destination == destination })

        guard let availablePair else {
            return []
        }

        let providers = availablePair.providers

        if let rateType {
            return providers.filter { $0.rates.contains(rateType) }
        }

        return providers
    }
}
