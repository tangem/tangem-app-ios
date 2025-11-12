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

    var formattedAmount: String? {
        switch type {
        case .approve, .vote, .withdraw:
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
             .tangemPayTransfer,
             .yieldSupply:
            return amount
        }
    }

    var amountColor: Color {
        switch (status, type) {
        case (.failed, _):
            return Colors.Text.warning

        case (_, .tangemPay(_, _, let isDeclined)) where isDeclined:
            return Colors.Text.warning

        case (_, .tangemPayTransfer) where !isOutgoing:
            return Colors.Text.accent

        default:
            return Colors.Text.primary1
        }
    }
}
