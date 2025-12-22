//
//  TransactionViewAmountViewData.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

struct TransactionViewAmountViewData: Hashable {
    let amount: String
    let type: TransactionViewModel.TransactionType
    let status: TransactionViewModel.Status
    let isOutgoing: Bool
    let isFromYieldContract: Bool

    var formattedAmount: String? {
        switch type {
        case .yieldSend where isFromYieldContract:
            return nil
        case .yieldWithdrawCoin, .yieldEnterCoin, .yieldReactivate, .yieldDeploy, .yieldSend, .yieldInit:
            return amount
        case .yieldEnter, .yieldWithdraw, .yieldTopup:
            return nil
        case .vote, .withdraw:
            return nil
        case .transfer,
             .swap,
             .operation,
             .unknownOperation,
             .stake,
             .unstake,
             .claimRewards,
             .restake,
             .tangemPay,
             .approve:
            return amount
        }
    }

    var amountColor: Color {
        switch (status, type) {
        case (.failed, _):
            return Colors.Text.warning

        case (_, .tangemPay(.spend(_, _, let isDeclined))) where isDeclined:
            return Colors.Text.warning

        case (_, .tangemPay(.transfer)) where !isOutgoing:
            return Colors.Text.accent

        default:
            return Colors.Text.primary1
        }
    }
}
