//
//  ApproveSpender.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - Spender

public struct ApproveSpender: Decodable {
    public let address: String
}

// MARK: - Transaction

public struct ApprovedTransactionData: Decodable {
    public let data: String
    public let gasPrice: String
    public let to: String
    public let value: String
}

// MARK: - Allowance

public struct ApprovedAllowance: Decodable {
    public let allowance: String
}
