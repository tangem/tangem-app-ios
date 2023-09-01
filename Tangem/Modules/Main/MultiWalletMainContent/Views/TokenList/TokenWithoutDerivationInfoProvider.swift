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
    var id: Int
    var tokenItem: TokenItem

    var hasPendingTransactions: Bool = false
    var balance: String = Localization.walletBalanceMissingDerivation
    var fiatBalance: String = BalanceFormatter.defaultEmptyBalanceString
    var quote: TokenQuote? { nil }

    var tokenItemStatePublisher: AnyPublisher<TokenItemViewState, Never> { .just(output: .noDerivation) }

    init(id: Int, tokenItem: TokenItem) {
        self.id = id
        self.tokenItem = tokenItem
    }
}
