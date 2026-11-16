//
//  AllowanceService.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemExpress

protocol AllowanceService: ExpressAllowanceProvider {
    func allowanceState(amount: Decimal, spender: String, approvePolicy: ApprovePolicy) async throws -> AllowanceState

    func markApproveTransactionSent(spender: String) async
}

// MARK: - ExpressAllowanceProvider

extension AllowanceService {
    func allowanceState(amount: Decimal, approvePolicy: ApprovePolicy, contractAddress: String, spender: String) async throws -> AllowanceState {
        if contractAddress == ExpressConstants.coinContractAddress {
            return .enoughAllowance
        }

        return try await allowanceState(amount: amount, spender: spender, approvePolicy: approvePolicy)
    }
}
