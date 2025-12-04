//
//  TangemPayAwareTotalBalanceProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

final class TangemPayAwareTotalBalanceProvider {
    private let totalBalanceProvider: any TotalBalanceProvider
    private let tangemPayTotalBalanceProvider: any TotalBalanceProvider
    private let totalBalanceStatesCombiner: TotalBalanceStatesCombiner

    private let totalBalanceSubject: CurrentValueSubject<TotalBalanceState, Never> = .init(.loading(cached: .none))
    private var updateSubscription: AnyCancellable?

    init(
        totalBalanceProvider: any TotalBalanceProvider,
        tangemPayTotalBalanceProvider: any TotalBalanceProvider,
        totalBalanceStatesCombiner: TotalBalanceStatesCombiner = .init()
    ) {
        self.totalBalanceProvider = totalBalanceProvider
        self.tangemPayTotalBalanceProvider = tangemPayTotalBalanceProvider
        self.totalBalanceStatesCombiner = totalBalanceStatesCombiner

        bind()
    }
}

// MARK: - TotalBalanceProvider

extension TangemPayAwareTotalBalanceProvider: TotalBalanceProvider {
    var totalBalance: TotalBalanceState {
        totalBalanceSubject.value
    }

    var totalBalancePublisher: AnyPublisher<TotalBalanceState, Never> {
        totalBalanceSubject.eraseToAnyPublisher()
    }
}

// MARK: - Private

private extension TangemPayAwareTotalBalanceProvider {
    func bind() {
        updateSubscription = [
            totalBalanceProvider.totalBalancePublisher,
            tangemPayTotalBalanceProvider.totalBalancePublisher,
        ]
        .combineLatest()
        .withWeakCaptureOf(self)
        .map { $0.totalBalanceStatesCombiner.mapToTotalBalanceState(states: $1) }
        .assign(to: \.totalBalanceSubject.value, on: self, ownership: .weak)
    }
}
