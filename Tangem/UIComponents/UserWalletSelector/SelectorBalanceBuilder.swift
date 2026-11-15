//
//  SelectorBalanceBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemAccounts
import TangemLocalization

enum SelectorBalanceBuilder {
    private static let formatter = BalanceFormatter()

    static func build(state: TotalBalanceState, currencyCode: String) -> SelectorBalance {
        switch state {
        case .empty:
            .loaded(BalanceFormatter.defaultEmptyBalanceString)
        case .loading(.none):
            .loading(cached: nil)
        case .loading(.some(let cached)):
            .loading(cached: formatter.formatFiatBalance(cached, currencyCode: currencyCode))
        case .failed(.none, _):
            .failed(Localization.commonUnreachable)
        case .failed(.some(let cached), _):
            .failed(formatter.formatFiatBalance(cached, currencyCode: currencyCode))
        case .loaded(let balance):
            .loaded(formatter.formatFiatBalance(balance, currencyCode: currencyCode))
        }
    }
}
