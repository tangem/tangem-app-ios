//
//  LegacyTotalBalanceProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

final class LegacyTotalBalanceProvider {
    private let walletModelsTotalBalanceProvider: any TotalBalanceProvider
    private let tangemPayTotalBalanceProvider: any TotalBalanceProvider
    private let totalBalanceStatesCombiner: TotalBalanceStatesCombiner

    private let totalBalanceSubject: CurrentValueSubject<TotalBalanceState, Never> = .init(.loading(cached: .none))
    private var updateSubscription: AnyCancellable?

    init(
        walletModelsTotalBalanceProvider: any TotalBalanceProvider,
        tangemPayTotalBalanceProvider: any TotalBalanceProvider,
        totalBalanceStatesCombiner: TotalBalanceStatesCombiner = .init()
    ) {
        self.walletModelsTotalBalanceProvider = walletModelsTotalBalanceProvider
        self.tangemPayTotalBalanceProvider = tangemPayTotalBalanceProvider
        self.totalBalanceStatesCombiner = totalBalanceStatesCombiner

        bind()
    }
}

// MARK: - TotalBalanceProvider

extension LegacyTotalBalanceProvider: TotalBalanceProvider {
    var totalBalance: TotalBalanceState {
        totalBalanceSubject.value
    }

    var totalBalancePublisher: AnyPublisher<TotalBalanceState, Never> {
        totalBalanceSubject.eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension LegacyTotalBalanceProvider {
    func bind() {
        updateSubscription = [
            walletModelsTotalBalanceProvider.totalBalancePublisher,
            tangemPayTotalBalanceProvider.totalBalancePublisher,
        ]
        .combineLatest()
        .withWeakCaptureOf(self)
        .map { $0.totalBalanceStatesCombiner.mapToTotalBalanceState(states: $1) }
        .assign(to: \.totalBalanceSubject.value, on: self, ownership: .weak)
    }
}
