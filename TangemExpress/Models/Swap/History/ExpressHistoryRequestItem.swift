//
//  ExpressHistoryRequestItem.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public struct ExpressHistoryRequestItem {
    public let walletAddress: String

    /// Opaque cursor (hence `Any`) for the next page.
    public let cursor: Any?

    public let limit: Int?

    public init(walletAddress: String, cursor: Any?, limit: Int?) {
        self.walletAddress = walletAddress
        self.cursor = cursor
        self.limit = limit
    }
}
