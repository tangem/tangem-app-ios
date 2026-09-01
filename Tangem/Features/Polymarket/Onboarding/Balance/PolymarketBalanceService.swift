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
    var balanceStatePublisher: AnyPublisher<PolymarketBalanceState?, Never> { get }

    func update(with result: LoadingResult<Decimal, Error>)

    func markUnavailable()
}

enum PolymarketBalanceState {
    case loading
    case loaded(Decimal)
    case failed(Error)
    case unavailable
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
    private let balanceSubject = CurrentValueSubject<PolymarketBalanceState?, Never>(nil)

    init(tokenBalancesRepository: TokenBalancesRepository) {
        self.tokenBalancesRepository = tokenBalancesRepository
    }
}

// MARK: - PolymarketBalanceService protocol conformance

extension CommonPolymarketBalanceService: PolymarketBalanceService {
    var balanceStatePublisher: AnyPublisher<PolymarketBalanceState?, Never> {
        balanceSubject.eraseToAnyPublisher()
    }

    func update(with result: LoadingResult<Decimal, Error>) {
        switch result {
        case .loading:
            balanceSubject.send(.loading)
        case .success(let balance):
            balanceSubject.send(.loaded(balance))
            fiatRateProvider.updateRate()
        case .failure(let error):
            balanceSubject.send(.failed(error))
        }
    }

    func markUnavailable() {
        balanceSubject.send(.unavailable)
    }
}
