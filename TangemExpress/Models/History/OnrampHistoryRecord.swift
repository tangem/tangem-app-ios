//
//  OnrampHistoryRecord.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct OnrampHistoryRecord: Hashable {
    public let txId: String
    public let status: OnrampTransactionStatus
    public let provider: ExpressHistoryProvider
    public let from: OnrampHistoryFiatAsset
    public let to: OnrampHistoryAsset
    public let payoutHash: String?
    public let externalTxId: String?
    public let externalTxUrl: String?
    public let refund: ExpressHistoryRefund?
    public let rate: OnrampHistoryRate?
    public let failReason: String?
    public let createdAt: Date
    public let updatedAt: Date

    public init(
        txId: String,
        status: OnrampTransactionStatus,
        provider: ExpressHistoryProvider,
        from: OnrampHistoryFiatAsset,
        to: OnrampHistoryAsset,
        payoutHash: String?,
        externalTxId: String?,
        externalTxUrl: String?,
        refund: ExpressHistoryRefund?,
        rate: OnrampHistoryRate?,
        failReason: String?,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.txId = txId
        self.status = status
        self.provider = provider
        self.from = from
        self.to = to
        self.payoutHash = payoutHash
        self.externalTxId = externalTxId
        self.externalTxUrl = externalTxUrl
        self.refund = refund
        self.rate = rate
        self.failReason = failReason
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
