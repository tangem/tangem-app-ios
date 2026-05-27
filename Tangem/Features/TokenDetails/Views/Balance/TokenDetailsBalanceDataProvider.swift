//
//  TokenDetailsBalanceDataProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

protocol TokenDetailsBalanceDataProvider: AnyObject {
    var totalCryptoBalancePublisher: AnyPublisher<FormattedTokenBalanceType, Never> { get }
    var totalFiatBalancePublisher: AnyPublisher<FormattedTokenBalanceType, Never> { get }

    var availableCryptoBalancePublisher: AnyPublisher<FormattedTokenBalanceType, Never> { get }
    var availableFiatBalancePublisher: AnyPublisher<FormattedTokenBalanceType, Never> { get }

    var stakingBalanceTypePublisher: AnyPublisher<TokenBalanceType, Never> { get }
    var yieldModuleState: AnyPublisher<YieldModuleManagerStateInfo, Never> { get }

    var isTokenCustom: Bool { get }
}
