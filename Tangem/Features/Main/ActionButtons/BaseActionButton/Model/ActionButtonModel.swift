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
        let isAddFundsStage1Enabled = FeatureProvider.isAvailable(.addFundsStage1)
        switch self {
        case .buy:
            return isAddFundsStage1Enabled ? Localization.commonAddFunds : Localization.commonBuy
        case .swap:
            return Localization.commonSwap
        case .sell:
            return Localization.commonSell
        }
    }

    var icon: ImageType {
        let isAddFundsStage1Enabled = FeatureProvider.isAvailable(.addFundsStage1)
        switch self {
        case .buy:
            return isAddFundsStage1Enabled ? Assets.arrowDownMini : Assets.plusMini
        case .swap:
            return isAddFundsStage1Enabled ? Assets.addfundsSwap : Assets.exchangeMini
        case .sell:
            return isAddFundsStage1Enabled ? Assets.arrowUpMini : Assets.dollarMini
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
