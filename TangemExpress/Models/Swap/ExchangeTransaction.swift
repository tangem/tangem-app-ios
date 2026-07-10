//
//  ExchangeTransaction.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct ExchangeTransaction: TransactionHistoryRecord, Hashable, @unchecked Sendable {
    public let txId: String
    public let providerId: ExpressProvider.Id
    public let status: ExpressTransactionStatus
    public let rateType: ExpressProviderRateType?
    public let externalTx: ExternalTxInfo?
    public let fromAddress: String?
    public let payIn: PayInInfo
    public let payOut: PayOutInfo
    public let refund: RefundInfo?
    public let from: ExpressHistoryAsset
    public let to: ExpressHistoryAsset
    public let createdAt: Date
    public let updatedAt: Date
    public let payTill: Date?
    public let averageDuration: TimeInterval?

    public init(
        txId: String,
        providerId: ExpressProvider.Id,
        status: ExpressTransactionStatus,
        rateType: ExpressProviderRateType?,
        externalTx: ExternalTxInfo?,
        fromAddress: String?,
        payIn: PayInInfo,
        payOut: PayOutInfo,
        refund: RefundInfo?,
        from: ExpressHistoryAsset,
        to: ExpressHistoryAsset,
        createdAt: Date,
        updatedAt: Date,
        payTill: Date?,
        averageDuration: TimeInterval?
    ) {
        self.txId = txId
        self.providerId = providerId
        self.status = status
        self.rateType = rateType
        self.externalTx = externalTx
        self.fromAddress = fromAddress
        self.payIn = payIn
        self.payOut = payOut
        self.refund = refund
        self.from = from
        self.to = to
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.payTill = payTill
        self.averageDuration = averageDuration
    }
}
