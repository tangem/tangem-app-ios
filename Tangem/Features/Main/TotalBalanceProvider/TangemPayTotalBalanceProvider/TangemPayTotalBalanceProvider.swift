//
//  TangemPayTotalBalanceProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemVisa
import TangemPay

final class TangemPayTotalBalanceProvider {
    private let tangemPayManager: TangemPayManager
    private let tokenBalanceTypesCombiner: TokenBalanceTypesCombiner

    private let tokenItem = TangemPayUtilities.usdcTokenItem
    private let totalBalanceSubject: CurrentValueSubject<TotalBalanceState, Never> = .init(.empty)
    private var updateSubscription: AnyCancellable?

    init(
        tangemPayManager: TangemPayManager,
        tokenBalanceTypesCombiner: TokenBalanceTypesCombiner = .init()
    ) {
        self.tangemPayManager = tangemPayManager
        self.tokenBalanceTypesCombiner = tokenBalanceTypesCombiner

        bind()
    }
}

// MARK: - TotalBalanceProvider

extension TangemPayTotalBalanceProvider: TotalBalanceProvider {
    var totalBalance: TotalBalanceState {
        totalBalanceSubject.value
    }

    var totalBalancePublisher: AnyPublisher<TotalBalanceState, Never> {
        totalBalanceSubject.eraseToAnyPublisher()
    }
}

// MARK: - Private implementation

private extension TangemPayTotalBalanceProvider {
    func bind() {
        updateSubscription = tangemPayManager.statePublisher
            .map(\.tangemPayAccount)
            .withWeakCaptureOf(self)
            .flatMapLatest { provider, tangemPayAccount -> AnyPublisher<TotalBalanceState, Never> in
                guard let tangemPayAccount else {
                    // If tangemPayAccount doesn't exist just return 0 as total balance
                    // That do not break a full total balance
                    return .just(output: .loaded(balance: 0))
                }

                return tangemPayAccount
                    .balancesProvider
                    .fiatTotalTokenBalanceProvider
                    .balanceTypePublisher
                    .map { balanceType in
                        let balance = TokenBalanceTypesCombiner.Balance(item: provider.tokenItem, balance: balanceType)
                        return provider.tokenBalanceTypesCombiner.mapToTotalBalance(balances: [balance])
                    }
                    .eraseToAnyPublisher()
            }
            .assign(to: \.totalBalanceSubject.value, on: self, ownership: .weak)
    }
}
