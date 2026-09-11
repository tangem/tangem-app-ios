//
//  TangemPayWithdrawRequest.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct TangemPayWithdrawRequest {
    public let amountInCents: String
    public let destination: String
    public let target: TangemPayWithdrawTarget?

    public init(amountInCents: String, destination: String, target: TangemPayWithdrawTarget?) {
        self.amountInCents = amountInCents
        self.destination = destination
        self.target = target
    }
}
