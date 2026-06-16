//
//  ExpressProviderError.swift
//  TangemExpress
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

public enum ExpressProviderError: LocalizedError {
    case allowanceProviderNotFound
    case transactionDataNotFound
    case transactionSizeNotSupported
    case transactionTypeMismatch
    case yieldModuleSwapUnavailable(YieldModuleSwapUnavailableReason)

    public var errorDescription: String? {
        switch self {
        case .allowanceProviderNotFound:
            "Allowance provider not found"
        case .transactionDataNotFound:
            "Transaction data not found"
        case .transactionSizeNotSupported:
            "Transaction size is not supported"
        case .transactionTypeMismatch:
            "Transaction type mismatch"
        case .yieldModuleSwapUnavailable(let reason):
            "Yield module swap unavailable: \(reason.rawValue)"
        }
    }
}

public enum YieldModuleSwapUnavailableReason: String {
    case moduleUpgradeUnavailable = "module_upgrade_unavailable"
    case swapExecutionRegistryUnavailable = "swap_execution_registry_unavailable"
    case spenderNotFound = "spender_not_found"
    case transactionDataNotFound = "transaction_data_not_found"
    case spenderNotAllowed = "spender_not_allowed"
    case targetNotAllowed = "target_not_allowed"
    case amountInInvalid = "amount_in_invalid"
}
