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
    /// Numeric portion without currency suffix, used by the redesigned two-line amount layout.
    let value: String
    /// Currency code shown on the secondary trailing line in the redesigned layout.
    let currencyCode: String
    let type: TransactionViewModel.TransactionType
    let status: TransactionViewModel.Status
    let isOutgoing: Bool
    let isFromYieldContract: Bool

    init(
        amount: String,
        value: String? = nil,
        currencyCode: String = "",
        type: TransactionViewModel.TransactionType,
        status: TransactionViewModel.Status,
        isOutgoing: Bool,
        isFromYieldContract: Bool
    ) {
        self.amount = amount
        self.value = value ?? amount
        self.currencyCode = currencyCode
        self.type = type
        self.status = status
        self.isOutgoing = isOutgoing
        self.isFromYieldContract = isFromYieldContract
    }

    var formattedAmount: String? {
        switch type {
        case .yieldSend where isFromYieldContract:
            return nil
        case .yieldWithdrawCoin, .yieldEnterCoin, .yieldReactivate, .yieldDeploy, .yieldSend, .yieldInit, .gaslessTransactionFee:
            return amount
        case .yieldEnter, .yieldWithdraw, .yieldTopup:
            return nil
        case .vote, .withdraw:
            return nil
        case .transfer,
             .gaslessTransfer,
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

        case (_, .tangemPay(.spend(_, _, let isDeclined, _))) where isDeclined:
            return Colors.Text.warning

        case (_, .tangemPay(.spend(_, _, _, let isNegativeAmount))) where isNegativeAmount:
            return Colors.Text.accent

        case (_, .tangemPay(.transfer)) where !isOutgoing:
            return Colors.Text.accent

        default:
            return Colors.Text.primary1
        }
    }
}
