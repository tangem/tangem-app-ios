//
//  CollectiblesBalanceService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemMacro

protocol CollectiblesBalanceService {
    var fiatTotalTokenBalanceProvider: TokenBalanceProvider { get }
    var usdcTokenBalanceProvider: TokenBalanceProvider { get }

    func update(_ state: CollectiblesBalanceState)
}

@CaseFlagable
enum CollectiblesBalanceState {
    case loading
    case loaded(UInt64)
    case failed(Error)
    /// No vault, so no account to hold anything — distinct from a balance of zero.
    case unavailable
}

final class CommonCollectiblesBalanceService {
    let fiatTotalTokenBalanceProvider: TokenBalanceProvider
    let usdcTokenBalanceProvider: TokenBalanceProvider

    private let fiatRateProvider: FiatRateProvider
    private let balanceSubject = CurrentValueSubject<CollectiblesBalanceState?, Never>(nil)

    init(tokenBalancesRepository: TokenBalancesRepository) {
        let tokenItem = CollectiblesChainEnvironment.usdcTokenItem
        let fiatRateProvider = CommonFiatRateProvider(tokenItem: tokenItem)
        let usdcTokenBalanceProvider = CollectiblesUsdcBalanceProvider(
            tokenItem: tokenItem,
            tokenBalancesRepository: tokenBalancesRepository,
            balanceSubject: balanceSubject
        )

        self.fiatRateProvider = fiatRateProvider
        self.usdcTokenBalanceProvider = usdcTokenBalanceProvider

        fiatTotalTokenBalanceProvider = FiatTokenBalanceProvider(
            input: fiatRateProvider,
            cryptoBalanceProvider: usdcTokenBalanceProvider
        )
    }
}

// MARK: - CollectiblesBalanceService protocol conformance

extension CommonCollectiblesBalanceService: CollectiblesBalanceService {
    func update(_ state: CollectiblesBalanceState) {
        balanceSubject.send(state)

        if state.isLoaded {
            fiatRateProvider.updateRate()
        }
    }
}
