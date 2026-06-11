//
//  OnrampHistoryRecord.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct OnrampHistoryRecord: TransactionHistoryRecord, Hashable, @unchecked Sendable {
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
}
