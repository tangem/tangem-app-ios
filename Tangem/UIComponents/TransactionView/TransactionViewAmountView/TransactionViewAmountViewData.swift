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
    /// Same content as `amount`, but with the ticker always after the number — `BalanceFormatter` places it
    /// per locale (`en_US` → `USDT 350.31`), which the redesign never wants — and with the sign the redesign
    /// invents for Supply and Withdraw.
    let amountWithCurrencyCode: String
    /// Numeric portion without currency suffix, used by the redesigned two-line amount layout.
    let value: String?
    /// Currency code shown on the secondary trailing line in the redesigned layout.
    let currencyCode: String
    let type: TransactionViewModel.TransactionType
    let status: TransactionViewModel.Status
    let isOutgoing: Bool
    let isFromYieldContract: Bool

    init(
        amount: String,
        amountWithCurrencyCode: String? = nil,
        value: String?,
        currencyCode: String = "",
        type: TransactionViewModel.TransactionType,
        status: TransactionViewModel.Status,
        isOutgoing: Bool,
        isFromYieldContract: Bool
    ) {
        self.amount = amount
        self.amountWithCurrencyCode = amountWithCurrencyCode ?? amount
        self.value = value
        self.currencyCode = currencyCode
        self.type = type
        self.status = status
        self.isOutgoing = isOutgoing
        self.isFromYieldContract = isFromYieldContract
    }

    var formattedAmount: String? {
        switch type {
        case .yieldSend where isFromYieldContract,
             .yieldEnter, .yieldWithdraw, .yieldTopup,
             .vote, .withdraw:
            return nil
        case .yieldSend,
             .yieldWithdrawCoin,
             .yieldEnterCoin,
             .yieldReactivate,
             .incentiveClaim,
             .incentiveClaimCoin,
             .yieldDeploy,
             .yieldInit,
             .gaslessTransactionFee,
             .networkFee,
             .transfer,
             .gaslessTransfer,
             .swap,
             .onramp,
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

    /// Numeric value for the redesigned row and chip. Deliberately decoupled from `formattedAmount`, which the
    /// legacy row reads: label-only chips carry none, while the legacy row still shows the amount of the
    /// coin-variant enable and disable.
    var displayValue: String? {
        if TransactionDisplayModel.isLabelOnlyChip(transactionType: type, isOutgoing: isOutgoing, isFromYieldContract: isFromYieldContract) {
            return nil
        }

        return value
    }

    var amountColor: Color {
        switch (status, type) {
        case (.failed, _):
            return Colors.Text.warning

        case (_, .tangemPay(.spend(_, _, let isDeclined, _))) where isDeclined:
            return Colors.Text.warning

        case (_, .tangemPay(.spend(_, _, _, let isNegativeAmount))) where isNegativeAmount:
            return Colors.Text.accent

        case (_, .tangemPay(.transfer)) where !isOutgoing, (_, .tangemPay(.cashback)):
            return Colors.Text.accent

        default:
            return Colors.Text.primary1
        }
    }
}
