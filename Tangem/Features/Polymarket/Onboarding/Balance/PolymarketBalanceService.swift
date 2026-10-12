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
    lazy var fiatAvailableBalanceProvider: TokenBalanceProvider = FiatTokenBalanceProvider(
        input: fiatRateProvider,
        cryptoBalanceProvider: collateralTokenBalanceProvider
    )

    lazy var fiatTotalTokenBalanceProvider: TokenBalanceProvider = FiatTokenBalanceProvider(
        input: fiatRateProvider,
        cryptoBalanceProvider: totalBalanceProvider
    )

    lazy var collateralTokenBalanceProvider: TokenBalanceProvider = PolymarketAccountBalanceProvider(
        kind: .available,
        tokenItem: tokenItem,
        tokenBalancesRepository: tokenBalancesRepository,
        balanceSubject: balanceSubject
    )

    private lazy var totalBalanceProvider: TokenBalanceProvider = PolymarketAccountBalanceProvider(
        kind: .total,
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
