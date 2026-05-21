//
//  ExchangeHistoryRecord.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct ExchangeHistoryRecord: Hashable {
    public let txId: String
    public let status: ExpressTransactionStatus
    public let provider: ExpressHistoryProvider
    public let from: ExchangeHistoryAsset
    public let to: ExchangeHistoryAsset
    public let payinHash: String?
    public let payoutHash: String?
    public let externalTxId: String?
    public let externalTxUrl: String?
    public let refund: ExpressHistoryRefund?
    public let rateType: ExpressProviderRateType
    public let createdAt: Date
    public let updatedAt: Date

    public init(
        txId: String,
        status: ExpressTransactionStatus,
        provider: ExpressHistoryProvider,
        from: ExchangeHistoryAsset,
        to: ExchangeHistoryAsset,
        payinHash: String?,
        payoutHash: String?,
        externalTxId: String?,
        externalTxUrl: String?,
        refund: ExpressHistoryRefund?,
        rateType: ExpressProviderRateType,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.txId = txId
        self.status = status
        self.provider = provider
        self.from = from
        self.to = to
        self.payinHash = payinHash
        self.payoutHash = payoutHash
        self.externalTxId = externalTxId
        self.externalTxUrl = externalTxUrl
        self.refund = refund
        self.rateType = rateType
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
