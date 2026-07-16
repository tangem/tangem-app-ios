//
//  ActionButtonModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import TangemAssets
import TangemAccessibilityIdentifiers
import TangemLocalization

enum ActionButtonModel: Hashable {
    case buy
    case swap
    /// The `.sell` case now semantically represents "Transfer" — see `title`. Not renamed to avoid a wider refactor.
    case sell

    var title: String {
        switch self {
        case .buy:
            return Localization.actionbuttonAddfundsTitle
        case .swap:
            return Localization.commonSwap
        case .sell:
            return Localization.actionbuttonTransferTitle
        }
    }

    var icon: ImageType {
        switch self {
        case .buy:
            return Assets.DesignSystem.arrowDown
        case .swap:
            return Assets.DesignSystem.exchange
        case .sell:
            return Assets.DesignSystem.arrowUp
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
