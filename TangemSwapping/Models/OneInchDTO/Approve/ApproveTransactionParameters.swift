//
//  ApproveTransactionParameters.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public struct ApproveTransactionParameters: Encodable {
    public enum Amount {
        case infinite
        case specified(value: Decimal)
    }

    public let tokenAddress: String
    public let amount: Amount

    public init(tokenAddress: String, amount: Amount) {
        self.tokenAddress = tokenAddress
        self.amount = amount
    }

    enum CodingKeys: CodingKey {
        case tokenAddress
        case amount
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(tokenAddress, forKey: .tokenAddress)

        switch amount {
        case .infinite:
            break
        case .specified(let value):
            try container.encode(value, forKey: .amount)
        }
    }
}
