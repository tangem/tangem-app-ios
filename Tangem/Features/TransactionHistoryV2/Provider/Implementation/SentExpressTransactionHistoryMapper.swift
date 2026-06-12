//
//  SentExpressTransactionHistoryMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import TangemFoundation

enum SentExpressTransactionHistoryMapper {
    static func mapToExchangeTransaction(_ transaction: SentSwapTransactionData) -> ExchangeTransaction {
        let expressTransactionData = transaction.expressTransactionData

        return ExchangeTransaction(
            txId: expressTransactionData.expressTransactionId,
            providerId: transaction.provider.id,
            status: .waiting,
            rateType: nil, // [REDACTED_TODO_COMMENT]
            externalTx: mapToExternalTxInfo(
                id: expressTransactionData.externalTxId,
                url: expressTransactionData.externalTxURL
            ),
            fromAddress: expressTransactionData.sourceAddress ?? transaction.source.defaultAddressString,
            payIn: PayInInfo(
                address: expressTransactionData.destinationAddress,
                extraId: expressTransactionData.extraDestinationId,
                hash: transaction.result.hash
            ),
            payOut: PayOutInfo(
                address: transaction.receive.address ?? .unknown,
                hash: nil // [REDACTED_TODO_COMMENT]
            ),
            refund: nil, // No refunds for exchange transactions
            from: ExpressHistoryAsset(
                currency: transaction.source.tokenItem.expressCurrency.asCurrency,
                amount: expressTransactionData.fromAmount,
                actualAmount: nil, // Unknown at this point
                decimals: transaction.source.tokenItem.decimalCount
            ),
            to: ExpressHistoryAsset(
                currency: transaction.receive.tokenItem.expressCurrency.asCurrency,
                amount: expressTransactionData.toAmount,
                actualAmount: nil, // Unknown at this point
                decimals: transaction.receive.tokenItem.decimalCount
            ),
            createdAt: transaction.date,
            updatedAt: transaction.date,
            payTill: nil,
            averageDuration: nil
        )
    }

    private static func mapToExternalTxInfo(id: String?, url: URL?) -> ExternalTxInfo? {
        guard let id else {
            return nil
        }

        return ExternalTxInfo(id: id, url: url)
    }
}
