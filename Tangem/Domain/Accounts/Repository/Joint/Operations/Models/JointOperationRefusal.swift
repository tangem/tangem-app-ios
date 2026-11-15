//
//  JointOperationRefusal.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum JointOperationRefusal: Hashable {
    case unsupportedChain
    case nonceMismatch
    case invalidBaseGas
    case gasPriceTooLow
    case gasPriceTooHigh
    case gasTokenNotAllowed
    case invalidRefundReceiver
    case invalidSafeOperation
    case invalidSafeAddress
    case unknown(String)
}

// MARK: - Reason code

extension JointOperationRefusal {
    init(reasonCode: String) {
        switch reasonCode {
        case "UNSUPPORTED_CHAIN": self = .unsupportedChain
        case "NONCE_MISMATCH": self = .nonceMismatch
        case "INVALID_BASE_GAS": self = .invalidBaseGas
        case "GAS_PRICE_TOO_LOW": self = .gasPriceTooLow
        case "GAS_PRICE_TOO_HIGH": self = .gasPriceTooHigh
        case "GAS_TOKEN_NOT_ALLOWED": self = .gasTokenNotAllowed
        case "INVALID_REFUND_RECEIVER": self = .invalidRefundReceiver
        case "INVALID_SAFE_OPERATION": self = .invalidSafeOperation
        case "INVALID_SAFE_ADDRESS": self = .invalidSafeAddress
        default: self = .unknown(reasonCode)
        }
    }

    var reasonCode: String {
        switch self {
        case .unsupportedChain: "UNSUPPORTED_CHAIN"
        case .nonceMismatch: "NONCE_MISMATCH"
        case .invalidBaseGas: "INVALID_BASE_GAS"
        case .gasPriceTooLow: "GAS_PRICE_TOO_LOW"
        case .gasPriceTooHigh: "GAS_PRICE_TOO_HIGH"
        case .gasTokenNotAllowed: "GAS_TOKEN_NOT_ALLOWED"
        case .invalidRefundReceiver: "INVALID_REFUND_RECEIVER"
        case .invalidSafeOperation: "INVALID_SAFE_OPERATION"
        case .invalidSafeAddress: "INVALID_SAFE_ADDRESS"
        case .unknown(let reasonCode): reasonCode
        }
    }
}
