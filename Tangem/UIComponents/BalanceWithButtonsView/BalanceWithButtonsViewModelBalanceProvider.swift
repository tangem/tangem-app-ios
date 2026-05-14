//
//  BalanceWithButtonsViewModelBalanceProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Combine

// [REDACTED_INFO]: Delete when redesign toggle is removed
protocol BalanceWithButtonsViewModelBalanceProvider: AnyObject {
    var totalCryptoBalancePublisher: AnyPublisher<FormattedTokenBalanceType, Never> { get }
    var totalFiatBalancePublisher: AnyPublisher<FormattedTokenBalanceType, Never> { get }

    var availableCryptoBalancePublisher: AnyPublisher<FormattedTokenBalanceType, Never> { get }
    var availableFiatBalancePublisher: AnyPublisher<FormattedTokenBalanceType, Never> { get }
}

protocol BalanceTypeSelectorProvider: AnyObject {
    var showBalanceSelectorPublisher: AnyPublisher<Bool, Never> { get }
}
