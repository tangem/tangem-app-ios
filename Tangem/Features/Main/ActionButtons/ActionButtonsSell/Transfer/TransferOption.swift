//
//  TransferOption.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemAccessibilityIdentifiers
import TangemAssets
import TangemLocalization

enum TransferOption: String, Identifiable, CaseIterable {
    case sell
    case swap
    case swapAndSend
    case send

    var id: String { rawValue }

    var viewData: AddFundsOptionView.ViewData {
        AddFundsOptionView.ViewData(
            icon: icon,
            title: title,
            subtitle: subtitle,
            accessibilityIdentifier: accessibilityIdentifier
        )
    }
}

private extension TransferOption {
    var icon: ImageType {
        switch self {
        case .sell: Assets.DesignSystem.dollar
        case .swap: Assets.DesignSystem.exchange
        case .swapAndSend: Assets.DesignSystem.exchange
        case .send: Assets.DesignSystem.arrowUp
        }
    }

    var title: String {
        switch self {
        case .sell: Localization.commonSell
        case .swap: Localization.commonSwap
        case .swapAndSend: Localization.sendWithSwapConfirmTitle
        case .send: Localization.commonSend
        }
    }

    var subtitle: String {
        switch self {
        case .sell: Localization.quickActionSellDescription
        case .swap: Localization.quickActionSwapDescription
        case .swapAndSend: Localization.sendWithSwapTitle
        case .send: Localization.quickActionSendDescription
        }
    }

    var accessibilityIdentifier: String {
        switch self {
        case .sell: ActionButtonsAccessibilityIdentifiers.transferSellRow
        case .swap: ActionButtonsAccessibilityIdentifiers.transferSwapRow
        case .swapAndSend: ActionButtonsAccessibilityIdentifiers.transferSwapAndSendRow
        case .send: ActionButtonsAccessibilityIdentifiers.transferSendRow
        }
    }
}
