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
            status: .created,
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
                hash: nil // Unknown at this point because there is no blockchain transaction yet
            ),
            refund: nil, // No refunds for exchange transactions
            from: ExpressHistoryAsset(
                currency: transaction.source.tokenItem.expressCurrency.asCurrency,
                amount: expressTransactionData.fromAmount,
                actualAmount: nil, // Unknown at this point because there is no blockchain transaction yet
                decimals: transaction.source.tokenItem.decimalCount
            ),
            to: ExpressHistoryAsset(
                currency: transaction.receive.tokenItem.expressCurrency.asCurrency,
                amount: expressTransactionData.toAmount,
                actualAmount: nil, // Unknown at this point because there is no blockchain transaction yet
                decimals: transaction.receive.tokenItem.decimalCount
            ),
            createdAt: transaction.date,
            updatedAt: transaction.date,
            payTill: nil,
            averageDuration: nil
        )
    }

    static func mapToOnrampTransaction(_ transaction: SentOnrampTransactionData) -> OnrampTransaction {
        OnrampTransaction(
            txId: transaction.txId,
            providerId: transaction.provider.id,
            status: .created,
            failReason: nil, // Obviously, the transaction has been just sent and cannot fail at this point
            externalTx: mapToExternalTxInfo(id: transaction.externalTxId, url: transaction.externalTxUrl.flatMap(URL.init(string:))),
            payOut: PayOutInfo(
                address: transaction.destinationAddress,
                hash: nil // Unknown at this point because there is no blockchain transaction yet
            ),
            from: OnrampHistoryFiatAsset(
                currencyCode: transaction.fromCurrencyCode,
                amount: transaction.fromAmount
            ),
            to: OnrampHistoryCryptoAsset(
                currency: transaction.destinationTokenItem.expressCurrency.asCurrency,
                amount: transaction.toAmount,
                actualAmount: nil, // Unknown at this point because there is no blockchain transaction yet
                decimals: transaction.destinationTokenItem.decimalCount
            ),
            paymentMethod: transaction.paymentMethod.id,
            countryCode: transaction.countryCode,
            createdAt: transaction.date,
            updatedAt: transaction.date
        )
    }

    private static func mapToExternalTxInfo(id: String?, url: URL?) -> ExternalTxInfo? {
        guard let id else {
            return nil
        }

        return ExternalTxInfo(id: id, url: url)
    }
}
