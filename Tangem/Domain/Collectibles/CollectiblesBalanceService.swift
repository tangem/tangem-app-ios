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

    private let fiatRateProvider: FiatRateProvider
    private let balanceSubject = CurrentValueSubject<CollectiblesBalanceState?, Never>(nil)

    init(tokenBalancesRepository: TokenBalancesRepository) {
        let tokenItem = CollectiblesChainEnvironment.usdcTokenItem
        let fiatRateProvider = CommonFiatRateProvider(tokenItem: tokenItem)

        self.fiatRateProvider = fiatRateProvider

        fiatTotalTokenBalanceProvider = FiatTokenBalanceProvider(
            input: fiatRateProvider,
            cryptoBalanceProvider: CollectiblesUsdcBalanceProvider(
                tokenItem: tokenItem,
                tokenBalancesRepository: tokenBalancesRepository,
                balanceSubject: balanceSubject
            )
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
