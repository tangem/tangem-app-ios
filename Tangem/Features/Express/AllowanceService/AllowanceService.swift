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

public protocol AllowanceService: ExpressAllowanceProvider {
    var isSupportAllowance: Bool { get }

    func allowanceState(amount: Decimal, spender: String, approvePolicy: ApprovePolicy) async throws -> AllowanceState
    func didSendApproveTransaction(for spender: String)
}

// MARK: - ExpressAllowanceProvider

public extension AllowanceService {
    func allowanceState(request: ExpressManagerSwappingPairRequest, spender: String) async throws -> AllowanceState {
        let contractAddress = request.pair.source.currency.contractAddress
        if contractAddress == ExpressConstants.coinContractAddress {
            return .enoughAllowance
        }

        return try await allowanceState(amount: request.amount, spender: spender, approvePolicy: request.approvePolicy)
    }
}
