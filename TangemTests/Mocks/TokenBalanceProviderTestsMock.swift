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
    let balanceType: TokenBalanceType
    private let formatted: String

    init(balanceType: TokenBalanceType, formatted: String = "") {
        self.balanceType = balanceType
        self.formatted = formatted
    }

    convenience init(balance: Decimal, formatted: String = "") {
        self.init(balanceType: .loaded(balance), formatted: formatted)
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
