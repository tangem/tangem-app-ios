//
//  AllowanceProvider.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public protocol AllowanceProvider {
    func isPermissionRequired(request: ExpressManagerSwappingPairRequest, for spender: String) async throws -> Bool
    func getAllowance(owner: String, to spender: String, contract: String) async throws -> Decimal
    func makeApproveData(spender: String, amount: Decimal) throws -> Data
}

public enum AllowanceProviderError: LocalizedError {
    case ethereumNetworkProviderNotFound
    case ethereumTransactionProcessorNotFound
    case approveTransactionInProgress
}
