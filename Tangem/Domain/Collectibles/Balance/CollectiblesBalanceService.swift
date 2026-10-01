//
//  CollectiblesBalanceService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemCollectibles
import Combine
import TangemFoundation

protocol CollectiblesBalanceService: CollectiblesBalanceUpdater {
    var fiatTotalTokenBalanceProvider: TokenBalanceProvider { get }
    var usdcTokenBalanceProvider: TokenBalanceProvider { get }
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
