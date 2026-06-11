//
//  ExchangeHistoryRecord.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct ExchangeHistoryRecord: TransactionHistoryRecord, Hashable, @unchecked Sendable {
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
}
