//
//  ExpressPairsRepository.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemExpress

protocol ExpressPairsRepository {
    func updatePairs(
        from wallet: ExpressWalletCurrency,
        to currencies: [ExpressWalletCurrency],
        userWalletInfo: UserWalletInfo
    ) async throws

    func updatePairs(for wallet: ExpressWalletCurrency, userWalletInfo: UserWalletInfo) async throws

    func getAvailableProviders(for pair: ExpressManagerSwappingPair) async throws -> [ExpressProvider.Id]

    func getPairs(from wallet: ExpressWalletCurrency) async -> [ExpressPair]
    func getPairs(to wallet: ExpressWalletCurrency) async -> [ExpressPair]
}

private struct ExpressPairsRepositoryKey: InjectionKey {
    static var currentValue: ExpressPairsRepository = CommonExpressPairsRepository()
}

extension InjectedValues {
    var expressPairsRepository: ExpressPairsRepository {
        get { Self[ExpressPairsRepositoryKey.self] }
        set { Self[ExpressPairsRepositoryKey.self] = newValue }
    }
}
