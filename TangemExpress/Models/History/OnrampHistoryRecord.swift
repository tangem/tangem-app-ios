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
}
