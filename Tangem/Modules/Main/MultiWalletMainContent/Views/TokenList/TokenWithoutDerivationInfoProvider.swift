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
    var quote: WalletModel.Rate { .failure(cached: .none) }
    var balance: TokenBalanceType { .empty(.noDerivation) }
    var balanceType: FormattedTokenBalanceType { .loaded("-") }
    var fiatBalanceType: FormattedTokenBalanceType { .loaded("-") }

    var quotePublisher: AnyPublisher<WalletModel.Rate, Never> { .just(output: quote) }
    var balancePublisher: AnyPublisher<TokenBalanceType, Never> { .just(output: balance) }
    var balanceTypePublisher: AnyPublisher<FormattedTokenBalanceType, Never> { .just(output: balanceType) }
    var fiatBalanceTypePublisher: AnyPublisher<FormattedTokenBalanceType, Never> { .just(output: fiatBalanceType) }
    var actionsUpdatePublisher: AnyPublisher<Void, Never> { .just(output: ()) }
    var isStakedPublisher: AnyPublisher<Bool, Never> { .just(output: false) }
}
