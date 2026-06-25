//
//  OnrampTransaction.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

public struct OnrampTransaction: TransactionHistoryRecord, Hashable, @unchecked Sendable {
    public let txId: String
    public let providerId: ExpressProvider.Id
    public let status: OnrampTransactionStatus
    public let failReason: String?
    public let externalTx: ExternalTxInfo?
    public let payOut: PayOutInfo
    public let from: OnrampHistoryFiatAsset
    public let to: OnrampHistoryCryptoAsset
    public let paymentMethod: String
    public let countryCode: String
    public let createdAt: Date
    public let updatedAt: Date

    public init(
        txId: String,
        providerId: ExpressProvider.Id,
        status: OnrampTransactionStatus,
        failReason: String?,
        externalTx: ExternalTxInfo?,
        payOut: PayOutInfo,
        from: OnrampHistoryFiatAsset,
        to: OnrampHistoryCryptoAsset,
        paymentMethod: String,
        countryCode: String,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.txId = txId
        self.providerId = providerId
        self.status = status
        self.failReason = failReason
        self.externalTx = externalTx
        self.payOut = payOut
        self.from = from
        self.to = to
        self.paymentMethod = paymentMethod
        self.countryCode = countryCode
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
