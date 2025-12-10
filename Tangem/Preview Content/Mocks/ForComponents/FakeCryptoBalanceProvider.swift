//
//  FakeCryptoBalanceProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

class FakeTokenBalanceProvider {
    typealias BalanceFormatted = (crypto: String, fiat: String)

    private let buttons: [FixedSizeButtonWithIconInfo]
    private let delay: TimeInterval
    private let cryptoBalanceInfo: BalanceFormatted

    private let valueSubject = CurrentValueSubject<LoadingResult<BalanceFormatted?, Never>, Never>(.loading)
    private let buttonsSubject: CurrentValueSubject<[FixedSizeButtonWithIconInfo], Never>

    var buttonsPublisher: AnyPublisher<[FixedSizeButtonWithIconInfo], Never> { buttonsSubject.eraseToAnyPublisher() }

    init(buttons: [FixedSizeButtonWithIconInfo], delay: TimeInterval, cryptoBalanceInfo: BalanceFormatted) {
        self.buttons = buttons
        buttonsSubject = .init(buttons)
        self.delay = delay
        self.cryptoBalanceInfo = cryptoBalanceInfo
    }
}

extension FakeTokenBalanceProvider: BalanceWithButtonsViewModelBalanceProvider {
    var totalCryptoBalancePublisher: AnyPublisher<FormattedTokenBalanceType, Never> {
        valueSubject
            .withWeakCaptureOf(self)
            .map { $0.mapToFormattedTokenBalanceType(balance: $1, isCrypto: true) }
            .eraseToAnyPublisher()
    }

    var totalFiatBalancePublisher: AnyPublisher<FormattedTokenBalanceType, Never> {
        valueSubject
            .withWeakCaptureOf(self)
            .map { $0.mapToFormattedTokenBalanceType(balance: $1, isCrypto: false) }
            .eraseToAnyPublisher()
    }

    var availableCryptoBalancePublisher: AnyPublisher<FormattedTokenBalanceType, Never> {
        valueSubject
            .withWeakCaptureOf(self)
            .map { $0.mapToFormattedTokenBalanceType(balance: $1, isCrypto: true) }
            .eraseToAnyPublisher()
    }

    var availableFiatBalancePublisher: AnyPublisher<FormattedTokenBalanceType, Never> {
        valueSubject
            .withWeakCaptureOf(self)
            .map { $0.mapToFormattedTokenBalanceType(balance: $1, isCrypto: false) }
            .eraseToAnyPublisher()
    }

    private func mapToFormattedTokenBalanceType(balance: LoadingResult<BalanceFormatted?, Never>, isCrypto: Bool) -> FormattedTokenBalanceType {
        switch balance {
        case .loading: .loading(.empty("-"))
        case .success(let value): .loaded(isCrypto ? (value?.crypto ?? "-") : (value?.fiat ?? "-"))
        case .failure: .failure(.empty("-"))
        }
    }
}

extension FakeTokenBalanceProvider: BalanceTypeSelectorProvider {
    var showBalanceSelectorPublisher: AnyPublisher<Bool, Never> { .just(output: true) }
}

extension FakeTokenBalanceProvider: YieldModuleStatusProvider {
    var yieldModuleState: AnyPublisher<YieldModuleManagerStateInfo, Never> {
        Empty(completeImmediately: true).eraseToAnyPublisher()
    }
}

extension FakeTokenBalanceProvider: RefreshStatusProvider {
    var isRefreshing: AnyPublisher<Bool, Never> {
        .just(output: false)
    }
}
