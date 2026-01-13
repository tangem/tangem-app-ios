//
//  TangemPayWithdrawRequest.swift
//  TangemPay
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct TangemPayWithdrawRequest {
    public let amount: Decimal
    public let amountInCents: String
    public let destination: String

    public init(amount: Decimal, amountInCents: String, destination: String) {
        self.amount = amount
        self.amountInCents = amountInCents
        self.destination = destination
    }
}
