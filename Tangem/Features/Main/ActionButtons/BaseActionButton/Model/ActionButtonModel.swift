//
//  ActionButtonModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemAssets
import TangemLocalization
import TangemAccessibilityIdentifiers

enum ActionButtonModel: Hashable {
    case buy
    case swap
    case sell

    var title: String {
        switch self {
        case .buy:
            Localization.commonBuy
        case .swap:
            Localization.commonSwap
        case .sell:
            Localization.commonSell
        }
    }

    var icon: ImageType {
        switch self {
        case .buy:
            Assets.plusMini
        case .swap:
            Assets.exchangeMini
        case .sell:
            Assets.dollarMini
        }
    }

    var accessibilityIdentifier: String {
        switch self {
        case .buy:
            MainAccessibilityIdentifiers.buyTitle
        case .swap:
            MainAccessibilityIdentifiers.exchangeTitle
        case .sell:
            MainAccessibilityIdentifiers.sellTitle
        }
    }
}

enum ActionButtonState: Equatable {
    case initial
    case loading
    case idle
    case restricted(reason: String)
    case disabled
    case unavailable
}
