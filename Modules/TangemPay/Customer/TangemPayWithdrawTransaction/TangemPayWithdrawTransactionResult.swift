//
//  TangemPayWithdrawTransactionResult.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public struct TangemPayWithdrawTransactionResult {
    public let orderID: String
    public let host: String

    public init(orderID: String, host: String) {
        self.orderID = orderID
        self.host = host
    }
}
