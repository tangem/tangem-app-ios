//
//  HederaError.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

enum HederaError: LocalizedError {
    case accountDoesNotExist
    case accountBalanceNotFound
    case transactionNotFound
    case multipleAccountsFound
    case failedToCreateAccount
    case unsupportedCurve(curveName: String)
    case fixedFeeInAnotherToken
    case conversionFromConsensusToMirrorFailed(transactionId: String)
    case conversionFromMirrorToConsensusFailed(transactionId: String)

    var errorDescription: String? {
        switch self {
        case .accountDoesNotExist:
            return "Account with the given public key does not exist on the Hedera network and must be created manually."
        case .accountBalanceNotFound:
            return "Account balance for a given account is not found in the response received from the Mirror Node"
        case .transactionNotFound:
            return "Transaction info for a given transaction is not found in the response received from the Mirror Node"
        case .multipleAccountsFound:
            return "There are multiple Hedera accounts on the Hedera network for the given public key"
        case .failedToCreateAccount:
            return "Failed to create a Hedera network account with the given public key"
        case .unsupportedCurve(let curveName):
            return "Hedera supports either ED25519 or ECDSA (secp256k1) curves. Curve '\(curveName)' is not supported"
        case .fixedFeeInAnotherToken:
            return "Fixed fee in another token"
        case .conversionFromConsensusToMirrorFailed(let transactionId):
            return "Failed to convert transaction ID \(transactionId) from Consensus Node to Mirror Node format"
        case .conversionFromMirrorToConsensusFailed(let transactionId):
            return "Failed to convert transaction ID \(transactionId) from Mirror Node to Consensus Node format"
        }
    }
}
