//
//  PendingExpressTxStatusBottomSheetViewModel+SharedData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension PendingExpressTxStatusBottomSheetViewModel {
    func buildShareText() -> String {
        let operation: ExpressShareTextBuilder.Operation
        switch pendingTransaction.type {
        case .swap(let source, let destination):
            operation = .swap(
                send: sourceAmountText,
                from: source.address,
                receive: destinationAmountText,
                to: destination.address
            )

        case .onramp(_, _, let destination):
            operation = .onramp(buy: destinationAmountText, to: destination.address)
        }

        let providerInfo = "\(pendingTransaction.provider.name) \(pendingTransaction.provider.type.rawValue.uppercased())"

        return ExpressShareTextBuilder.build(
            operation: operation,
            providerInfo: providerInfo,
            transactionId: pendingTransaction.externalTxId ?? pendingTransaction.expressTransactionId
        )
    }
}
