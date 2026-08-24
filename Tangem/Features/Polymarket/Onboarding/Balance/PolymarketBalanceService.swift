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
import TangemPolymarket

protocol PolymarketBalanceService {
    var fiatTotalTokenBalanceProvider: TokenBalanceProvider { get }

    func update(with result: LoadingResult<Decimal, Error>)
}

final class CommonPolymarketBalanceService {
    lazy var fiatTotalTokenBalanceProvider: TokenBalanceProvider = FiatTokenBalanceProvider(
        input: fiatRateProvider,
        cryptoBalanceProvider: collateralBalanceProvider
    )

    private lazy var collateralBalanceProvider: TokenBalanceProvider = PolymarketCollateralBalanceProvider(
        tokenItem: tokenItem,
        tokenBalancesRepository: tokenBalancesRepository,
        balanceSubject: balanceSubject
    )

    private lazy var fiatRateProvider: FiatRateProvider = CommonFiatRateProvider(tokenItem: tokenItem)

    private let tokenItem = PolymarketUtilities.collateralTokenItem
    private let tokenBalancesRepository: TokenBalancesRepository
    private let balanceSubject = CurrentValueSubject<LoadingResult<Decimal, Error>?, Never>(nil)

    init(tokenBalancesRepository: TokenBalancesRepository) {
        self.tokenBalancesRepository = tokenBalancesRepository
    }
}

// MARK: - PolymarketBalanceService protocol conformance

extension CommonPolymarketBalanceService: PolymarketBalanceService {
    func update(with result: LoadingResult<Decimal, Error>) {
        balanceSubject.send(result)

        if case .success = result {
            fiatRateProvider.updateRate()
        }
    }
}
