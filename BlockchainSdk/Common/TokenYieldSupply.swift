//
//  TokenYieldSupply.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct TokenYieldSupply: Hashable, Equatable, Codable {
    public let yieldContractAddress: String
    public let isActive: Bool
    public let isInitialized: Bool
    public let allowance: Decimal
}
