//
//  ExchangeReferrerAccount.swift
//  TangemExchange
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct ExchangeReferrerAccount {
    public let address: String
    // Value from 0.0 to 3.0
    public let fee: Double

    public init(address: String, fee: Double) {
        self.address = address
        self.fee = fee
    }
}
