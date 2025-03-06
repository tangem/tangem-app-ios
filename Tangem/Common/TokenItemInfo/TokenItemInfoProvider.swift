//
//  TokenItemInfoProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import BlockchainSdk
import TangemFoundation

protocol TokenItemInfoProvider: AnyObject {
    var quote: WalletModel.Rate { get }
    var balance: TokenBalanceType { get }
    var balanceType: FormattedTokenBalanceType { get }
    var fiatBalanceType: FormattedTokenBalanceType { get }

    var quotePublisher: AnyPublisher<WalletModel.Rate, Never> { get }
    var balancePublisher: AnyPublisher<TokenBalanceType, Never> { get }
    var balanceTypePublisher: AnyPublisher<FormattedTokenBalanceType, Never> { get }
    var fiatBalanceTypePublisher: AnyPublisher<FormattedTokenBalanceType, Never> { get }

    var actionsUpdatePublisher: AnyPublisher<Void, Never> { get }
    var hasPendingTransactions: AnyPublisher<Bool, Never> { get }
    var isStakedPublisher: AnyPublisher<Bool, Never> { get }
}
