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
    private let formatted: String

    init(balance: Decimal, formatted: String = "") {
        self.balance = balance
        self.formatted = formatted
    }

    var balanceType: TokenBalanceType {
        .loaded(balance)
    }

    var balanceTypePublisher: AnyPublisher<TokenBalanceType, Never> {
        Just(balanceType).eraseToAnyPublisher()
    }

    var formattedBalanceType: FormattedTokenBalanceType {
        .loaded(formatted)
    }

    var formattedBalanceTypePublisher: AnyPublisher<FormattedTokenBalanceType, Never> {
        Just(formattedBalanceType).eraseToAnyPublisher()
    }
}
