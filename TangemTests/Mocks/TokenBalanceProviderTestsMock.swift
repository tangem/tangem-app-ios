//
//  MockTokenBalanceProvider.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
@testable import Tangem

final class TokenBalanceProviderTestsMock: TokenBalanceProvider {
    private let balance: Decimal

    init(balance: Decimal) {
        self.balance = balance
    }

    var balanceType: TokenBalanceType {
        .loaded(balance)
    }

    var balanceTypePublisher: AnyPublisher<TokenBalanceType, Never> {
        Just(balanceType).eraseToAnyPublisher()
    }

    var formattedBalanceType: FormattedTokenBalanceType {
        .loaded("")
    }

    var formattedBalanceTypePublisher: AnyPublisher<FormattedTokenBalanceType, Never> {
        Just(formattedBalanceType).eraseToAnyPublisher()
    }
}
