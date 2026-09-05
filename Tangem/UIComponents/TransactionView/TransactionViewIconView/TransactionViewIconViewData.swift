//
//  TransactionViewIconViewData.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemAssets

struct TransactionViewIconViewData: Hashable {
    let type: TransactionViewModel.TransactionType
    let status: TransactionViewModel.Status
    let isOutgoing: Bool

    var icon: Image {
        switch type {
        case .approve:
            return DesignSystem.Icons.Success.regular20.image
        case .swap:
            return DesignSystem.Icons.ArrowSwapHorizontal.regular20.image
        case .onramp:
            return DesignSystem.Icons.Card.regular20.image
        case .transfer, .operation, .unknownOperation, .tangemPay(.transfer), .yieldTopup, .yieldSend, .gaslessTransfer:
            return isOutgoing ? Assets.arrowUpMini.image : Assets.arrowDownMini.image
        case .gaslessTransactionFee:
            return DesignSystem.Icons.Percent.regular20.image
        case .stake, .vote, .restake, .unstake, .withdraw, .claimRewards:
            return DesignSystem.Icons.Stack.regular16.image
        case .tangemPay(.fee):
            return Assets.Visa.feeTransactionPercent.image
        case .tangemPay(.spend):
            return Assets.Visa.otherTransaction.image
        case .yieldEnter, .yieldEnterCoin, .yieldWithdraw, .yieldWithdrawCoin,
             .yieldDeploy, .yieldInit, .yieldReactivate:
            return DesignSystem.Icons.ChartLineVertical.regular20.image
        }
    }

    var iconColor: Color {
        switch status {
        case .inProgress:
            return Colors.Icon.accent
        case .confirmed:
            return Colors.Icon.informative
        case .failed, .undefined:
            return Colors.Icon.warning
        }
    }

    var iconBackgroundColor: Color {
        switch status {
        case .inProgress: return Colors.Icon.accent.opacity(0.1)
        case .confirmed: return Colors.Button.secondary
        case .failed, .undefined: return Colors.Icon.warning.opacity(0.1)
        }
    }
}
