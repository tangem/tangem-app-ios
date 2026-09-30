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
    var fiatAvailableBalanceProvider: TokenBalanceProvider { get }
    var fiatTotalTokenBalanceProvider: TokenBalanceProvider { get }
    var collateralTokenBalanceProvider: TokenBalanceProvider { get }
    var collateralTotalBalanceProvider: TokenBalanceProvider { get }
    var state: PolymarketBalanceState? { get }

    func update(_ state: PolymarketBalanceState)
}

@CaseFlagable
enum PolymarketBalanceState {
    case loading
    case loaded(PolymarketBalance)
    case failed(Error)
    case unavailable
}

struct PolymarketBalance {
    enum PositionsValue {
        case loaded(Decimal)
        case reused(Decimal)
        case unknown
    }

    let available: Decimal

    private let positionsValue: PositionsValue

    var total: Decimal? {
        switch positionsValue {
        case .loaded(let value), .reused(let value): available + value
        case .unknown: nil
        }
    }

    var freshTotal: Decimal? {
        switch positionsValue {
        case .loaded(let value): available + value
        case .reused, .unknown: nil
        }
    }

    init(available: Decimal, positionsValue: PositionsValue) {
        self.available = available
        self.positionsValue = positionsValue
    }
}

final class CommonPolymarketBalanceService {
    let fiatAvailableBalanceProvider: TokenBalanceProvider
    let fiatTotalTokenBalanceProvider: TokenBalanceProvider
    let collateralTokenBalanceProvider: TokenBalanceProvider
    let collateralTotalBalanceProvider: TokenBalanceProvider

    private let fiatRateProvider: FiatRateProvider

    private let tokenBalancesRepository: TokenBalancesRepository
    private let balanceSubject: CurrentValueSubject<PolymarketBalanceState?, Never>

    init(tokenBalancesRepository: TokenBalancesRepository) {
        let tokenItem = PolymarketUtilities.collateralTokenItem
        let balanceSubject = CurrentValueSubject<PolymarketBalanceState?, Never>(nil)
        let fiatRateProvider = CommonFiatRateProvider(tokenItem: tokenItem)

        let collateralTokenBalanceProvider = PolymarketAccountBalanceProvider(
            kind: .available,
            tokenItem: tokenItem,
            tokenBalancesRepository: tokenBalancesRepository,
            balanceSubject: balanceSubject
        )

        let collateralTotalBalanceProvider = PolymarketAccountBalanceProvider(
            kind: .total,
            tokenItem: tokenItem,
            tokenBalancesRepository: tokenBalancesRepository,
            balanceSubject: balanceSubject
        )

        self.tokenBalancesRepository = tokenBalancesRepository
        self.balanceSubject = balanceSubject
        self.fiatRateProvider = fiatRateProvider
        self.collateralTokenBalanceProvider = collateralTokenBalanceProvider
        self.collateralTotalBalanceProvider = collateralTotalBalanceProvider

        fiatAvailableBalanceProvider = FiatTokenBalanceProvider(
            input: fiatRateProvider,
            cryptoBalanceProvider: collateralTokenBalanceProvider
        )

        fiatTotalTokenBalanceProvider = FiatTokenBalanceProvider(
            input: fiatRateProvider,
            cryptoBalanceProvider: collateralTotalBalanceProvider
        )
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
