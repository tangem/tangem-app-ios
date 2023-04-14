//
//  SwappingReferrerAccount.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public struct SwappingReferrerAccount {
    public let address: String
    // Value from 0.0 to 3.0
    public let fee: Decimal

    public init(address: String, fee: Decimal) {
        self.address = address
        self.fee = fee
    }
}
