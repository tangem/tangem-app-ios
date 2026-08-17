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
    /// One-tap approve+swap needs fee estimation with an allowance state override — currently EVM-only.
    var supportsOneTapApprove: Bool { get }

    func allowanceState(request: ExpressManagerSwappingPairRequest, contractAddress: String, spender: String) async throws -> AllowanceState
    func makeApproveData(spender: String, amount: Decimal, policy: ApprovePolicy) async throws -> ApproveTransactionData
}
