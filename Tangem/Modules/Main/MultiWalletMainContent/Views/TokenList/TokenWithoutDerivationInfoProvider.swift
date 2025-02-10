//
//  TokenWithoutDerivationInfoProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

class TokenWithoutDerivationInfoProvider: TokenItemInfoProvider {
    let hasPendingTransactions: Bool = false
    var isZeroBalanceValue: Bool { true }
    var balance: TokenBalanceType { .empty(.noDerivation) }

    var quotePublisher: AnyPublisher<TokenQuote?, Never> { .just(output: .none) }
    var balancePublisher: AnyPublisher<TokenBalanceType, Never> { .just(output: balance) }
    var balanceTypePublisher: AnyPublisher<FormattedTokenBalanceType, Never> { .just(output: .loaded("-")) }
    var fiatBalanceTypePublisher: AnyPublisher<FormattedTokenBalanceType, Never> { .just(output: .loaded("-")) }
    var actionsUpdatePublisher: AnyPublisher<Void, Never> { .just(output: ()) }
    var isStakedPublisher: AnyPublisher<Bool, Never> { .just(output: false) }
}
