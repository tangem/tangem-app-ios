//
//  TransactionHistoryDustFilter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct TransactionHistoryDustFilter {
    private let usdRate: Decimal?

    init(usdRate: Decimal?) {
        self.usdRate = usdRate
    }

    func isDust(amount: Decimal, isOutgoing: Bool, transactionType: TransactionViewModel.TransactionType) -> Bool {
        guard let usdRate, usdRate > 0, isFilterable(transactionType, isOutgoing: isOutgoing) else {
            return false
        }

        return abs(amount) * usdRate < Constants.thresholdUSD
    }

    private func isFilterable(
        _ transactionType: TransactionViewModel.TransactionType,
        isOutgoing: Bool
    ) -> Bool {
        switch transactionType {
        case .transfer,
             .gaslessTransfer:
            return true
        case .stake,
             .unstake,
             .withdraw,
             .claimRewards,
             .yieldEnter,
             .yieldEnterCoin,
             .yieldTopup,
             .yieldWithdraw,
             .yieldWithdrawCoin,
             .yieldSend:
            return !isOutgoing
        case .yieldDeploy,
             .yieldInit,
             .yieldReactivate,
             .approve,
             .swap,
             .onramp,
             .vote,
             .restake,
             .unknownOperation,
             .operation,
             .gaslessTransactionFee,
             .tangemPay:
            return false
        }
    }
}

// MARK: - Constants

private extension TransactionHistoryDustFilter {
    enum Constants {
        static let thresholdUSD = Decimal(stringValue: "0.01")!
    }
}
