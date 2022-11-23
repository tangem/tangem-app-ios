//
//  ApproveTransactionParameters.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public struct ApproveTransactionParameters {
    public enum Amount {
        case infinite
        case specified(value: Int)
    }

    public let tokenAddress: String
    public let amount: Amount

    public init(tokenAddress: String, amount: Amount) {
        self.tokenAddress = tokenAddress
        self.amount = amount
    }

    func parameters() -> [String: Any] {
        var params: [String: Any] = [:]
        switch amount {
        case .infinite:
            break
        case .specified(let value):
            params["amount"] = value
        }
        params["tokenAddress"] = tokenAddress
        return params
    }
}

public struct ApproveAllowanceParameters {
    public let tokenAddress: String
    public let walletAddress: String

    public init(tokenAddress: String, walletAddress: String) {
        self.tokenAddress = tokenAddress
        self.walletAddress = walletAddress
    }

    func parameters() -> [String: Any] {
        var params: [String: Any] = [:]
        params["tokenAddress"] = tokenAddress
        params["walletAddress"] = walletAddress
        return params
    }
}
