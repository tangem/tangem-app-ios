//
//  TangemPayMoneyAccountAddFundsOption.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemAccessibilityIdentifiers
import TangemAssets
import TangemLocalization

enum TangemPayMoneyAccountAddFundsOption: Identifiable {
    case swap
    case receive
    case bankTransfer

    var id: Self { self }

    var title: String {
        switch self {
        case .swap: Localization.tangempayTopupSwapTitle
        case .receive: Localization.tangempayTopupReceiveTitle
        case .bankTransfer: Localization.tangempayTopupBankTransferTitle
        }
    }

    var subtitle: String {
        switch self {
        case .swap: Localization.moneyAccountAddFundsSwapDescription
        case .receive: Localization.moneyAccountAddFundsReceiveDescription
        case .bankTransfer: Localization.moneyAccountAddFundsBankDescription
        }
    }

    var icon: ImageType {
        switch self {
        case .swap: DesignSystem.Icons.ArrowSwapHorizontal.regular20
        case .receive: DesignSystem.Icons.Grid.regular20
        case .bankTransfer: DesignSystem.Icons.Government.regular20
        }
    }

    var accessibilityIdentifier: String {
        switch self {
        case .swap: TangemPayAccessibilityIdentifiers.addFundsSheetSwapOption
        case .receive: TangemPayAccessibilityIdentifiers.addFundsSheetReceiveOption
        case .bankTransfer: TangemPayAccessibilityIdentifiers.addFundsSheetBankTransferOption
        }
    }
}
