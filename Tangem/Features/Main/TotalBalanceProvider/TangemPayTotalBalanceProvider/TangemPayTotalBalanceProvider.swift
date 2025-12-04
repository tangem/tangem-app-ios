//
//  TangemPayTotalBalanceProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemVisa

final class TangemPayTotalBalanceProvider {
    private let tangemPayAccountProvider: TangemPayAccountProvider
    private let tokenBalanceTypesCombiner: TokenBalanceTypesCombiner

    private let tokenItem = TangemPayUtilities.usdcTokenItem
    private let totalBalanceSubject: CurrentValueSubject<TotalBalanceState, Never> = .init(.empty)
    private var updateSubscription: AnyCancellable?

    init(
        tangemPayAccountProvider: TangemPayAccountProvider,
        tokenBalanceTypesCombiner: TokenBalanceTypesCombiner = .init()
    ) {
        self.tangemPayAccountProvider = tangemPayAccountProvider
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
        updateSubscription = tangemPayAccountProvider.tangemPayAccountPublisher
            .compactMap(\.self)
            .flatMapLatest { $0.fiatAvailableBalanceProvider.balanceTypePublisher }
            .withWeakCaptureOf(self)
            .map {
                $0.tokenBalanceTypesCombiner.mapToTotalBalance(
                    balances: [.init(item: $0.tokenItem, balance: $1)]
                )
            }
            .assign(to: \.totalBalanceSubject.value, on: self, ownership: .weak)
    }
}
