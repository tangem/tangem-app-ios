//
//  SwapRepository.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemExpress

protocol SwapRepository: ExpressRepository {
    func updatePairs(
        from wallet: ExpressWalletCurrency,
        to currencies: [ExpressWalletCurrency],
        userWalletInfo: UserWalletInfo
    ) async throws

    func updatePairs(for wallet: ExpressWalletCurrency, userWalletInfo: UserWalletInfo) async throws

    // getAvailableProvidersIds is inherited from ExpressRepository

    func getPairs(from wallet: ExpressWalletCurrency) async -> [ExpressPair]
    func getPairs(to wallet: ExpressWalletCurrency) async -> [ExpressPair]

    func providers(userWalletInfo: UserWalletInfo) async throws -> [ExpressProvider]
}

private struct SwapRepositoryKey: InjectionKey {
    static var currentValue: SwapRepository = CommonSwapRepository()
}

extension InjectedValues {
    var swapRepository: SwapRepository {
        get { Self[SwapRepositoryKey.self] }
        set { Self[SwapRepositoryKey.self] = newValue }
    }
}
