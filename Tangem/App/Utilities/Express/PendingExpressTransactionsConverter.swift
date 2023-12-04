//
//  PendingExpressTransactionsConverter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct PendingExpressTransactionsConverter {
    func convertToTokenDetailsPendingTxInfo(_ records: [PendingExpressTransaction], tapAction: @escaping (String) -> Void) -> [PendingExpressTransactionView.Info] {
        let iconBuilder = TokenIconInfoBuilder()
        let balanceFormatter = BalanceFormatter()

        return records.compactMap {
            let record = $0.transactionRecord
            let sourceTokenItem = record.sourceTokenTxInfo.tokenItem
            let destinationTokenItem = record.destinationTokenTxInfo.tokenItem
            let state: PendingExpressTransactionView.State
            switch $0.currentStatus {
            case .done, .refunded:
                return nil
            case .awaitingDeposit, .confirming, .exchanging, .sendingToUser:
                state = .inProgress
            case .failed:
                state = .error
            case .verificationRequired:
                state = .warning
            }

            return .init(
                id: record.expressTransactionId,
                providerName: record.provider.name,
                sourceIconInfo: iconBuilder.build(from: sourceTokenItem, isCustom: record.sourceTokenTxInfo.isCustom),
                sourceAmountText: balanceFormatter.formatCryptoBalance(record.sourceTokenTxInfo.amount, currencyCode: sourceTokenItem.currencySymbol),
                destinationIconInfo: iconBuilder.build(from: destinationTokenItem, isCustom: record.destinationTokenTxInfo.isCustom),
                destinationCurrencySymbol: destinationTokenItem.currencySymbol,
                state: state,
                action: tapAction
            )
        }
    }
}
