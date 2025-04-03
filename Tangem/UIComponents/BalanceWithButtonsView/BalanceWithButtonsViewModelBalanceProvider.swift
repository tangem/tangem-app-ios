//
//  BalanceWithButtonsViewModelBalanceProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine

protocol BalanceWithButtonsViewModelBalanceProvider {
    var totalCryptoBalancePublisher: AnyPublisher<FormattedTokenBalanceType, Never> { get }
    var totalFiatBalancePublisher: AnyPublisher<FormattedTokenBalanceType, Never> { get }

    var availableCryptoBalancePublisher: AnyPublisher<FormattedTokenBalanceType, Never> { get }
    var availableFiatBalancePublisher: AnyPublisher<FormattedTokenBalanceType, Never> { get }
}

protocol BalanceTypeSelectorProvider {
    var shouldShowBalanceSelector: Bool { get }
}
