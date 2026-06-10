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
    public let status: ExpressTransactionStatus
    public let provider: ExpressHistoryProvider
    public let from: ExchangeHistoryAsset
    public let to: ExchangeHistoryAsset
    public let payinHash: String?
    public let payoutHash: String?
    public let externalTxId: String?
    public let externalTxURL: URL?
    public let refund: ExpressHistoryRefund?
    public let rateType: ExpressProviderRateType?
    public let createdAt: Date
    public let updatedAt: Date
}
