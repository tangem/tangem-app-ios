//
//  PolymarketBalanceService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemMacro
import TangemPolymarket

protocol PolymarketBalanceService {
    var fiatTotalTokenBalanceProvider: TokenBalanceProvider { get }
    var collateralTokenBalanceProvider: TokenBalanceProvider { get }
    var state: PolymarketBalanceState? { get }

    func update(_ state: PolymarketBalanceState)
}

@CaseFlagable
enum PolymarketBalanceState {
    case loading
    case loaded(Decimal)
    case failed(Error)
    case unavailable
}

final class CommonPolymarketBalanceService {
    lazy var fiatTotalTokenBalanceProvider: TokenBalanceProvider = FiatTokenBalanceProvider(
        input: fiatRateProvider,
        cryptoBalanceProvider: collateralTokenBalanceProvider
    )

    lazy var collateralTokenBalanceProvider: TokenBalanceProvider = PolymarketCollateralBalanceProvider(
        tokenItem: tokenItem,
        tokenBalancesRepository: tokenBalancesRepository,
        balanceSubject: balanceSubject
    )

    private lazy var fiatRateProvider: FiatRateProvider = CommonFiatRateProvider(tokenItem: tokenItem)

    private let tokenItem = PolymarketUtilities.collateralTokenItem
    private let tokenBalancesRepository: TokenBalancesRepository
    private let balanceSubject = CurrentValueSubject<PolymarketBalanceState?, Never>(nil)

    init(tokenBalancesRepository: TokenBalancesRepository) {
        self.tokenBalancesRepository = tokenBalancesRepository
    }
}

// MARK: - PolymarketBalanceService protocol conformance

extension CommonPolymarketBalanceService: PolymarketBalanceService {
    var state: PolymarketBalanceState? {
        balanceSubject.value
    }

    func update(_ state: PolymarketBalanceState) {
        balanceSubject.send(state)

        if state.isLoaded {
            fiatRateProvider.updateRate()
        }
    }
}
