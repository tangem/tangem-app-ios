//
//  TokenSelectorBalanceFilter.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemLocalization
import TangemUI

enum TokenSelectorBalanceFilter: Hashable, CaseIterable {
    case all
    case hideZero
}

extension TokenSelectorBalanceFilter: TangemDropDownTextProvider {
    var text: String {
        switch self {
        case .all: Localization.commonAll
        case .hideZero: Localization.swapTokenSelectorFilterHideZeroBalance
        }
    }
}

enum TokenSelectorEmptyReason: Hashable {
    case filteredOut
    case noTokens
}
