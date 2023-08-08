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

    var tokenItemStatePublisher: AnyPublisher<TokenItemViewState, Never> { .just(output: .noDerivation) }

    var tokenItem: TokenItem
    var hasPendingTransactions: Bool = false
    var balance: String = BalanceFormatter.defaultEmptyBalanceString
    var fiatBalance: String = BalanceFormatter.defaultEmptyBalanceString

    init(tokenItem: TokenItem) {
        self.tokenItem = tokenItem
        id = tokenItem.hashValue
    }
}
