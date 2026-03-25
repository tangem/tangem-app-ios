//
//  AllowanceProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk

public typealias ExpressAllowanceProvider = AllowanceProvider

public protocol AllowanceProvider {
    func allowanceState(request: ExpressManagerSwappingPairRequest, contractAddress: String, spender: String) async throws -> AllowanceState
}
