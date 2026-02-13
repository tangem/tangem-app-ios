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
    func sendApproveTransaction(data: ApproveTransactionData) async throws -> TransactionDispatcherResult
}

// MARK: - ExpressAllowanceProvider

extension AllowanceService {
    func allowanceState(request: ExpressManagerSwappingPairRequest, contractAddress: String, spender: String) async throws -> AllowanceState {
        if contractAddress == ExpressConstants.coinContractAddress {
            return .enoughAllowance
        }

        return try await allowanceState(amount: request.amount, spender: spender, approvePolicy: request.approvePolicy)
    }
}
