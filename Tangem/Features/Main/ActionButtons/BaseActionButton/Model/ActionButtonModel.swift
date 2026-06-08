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
            return isAddFundsStage1Enabled ? Localization.commonTransfer : Localization.commonSell
        }
    }

    var icon: ImageType {
        let isAddFundsStage1Enabled = FeatureProvider.isAvailable(.addFundsStage1)
        let isRedesign = FeatureProvider.isAvailable(.redesign)
        switch self {
        case .buy:
            let stage1Icon: ImageType = isRedesign ? Assets.DesignSystem.arrowDown : Assets.arrowDownMini
            return isAddFundsStage1Enabled ? stage1Icon : Assets.plusMini
        case .swap:
            let stage1Icon: ImageType = isRedesign ? Assets.DesignSystem.exchange : Assets.addfundsSwap
            return isAddFundsStage1Enabled ? stage1Icon : Assets.exchangeMini
        case .sell:
            let stage1Icon: ImageType = isRedesign ? Assets.DesignSystem.arrowUp : Assets.arrowUpMini
            return isAddFundsStage1Enabled ? stage1Icon : Assets.dollarMini
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
