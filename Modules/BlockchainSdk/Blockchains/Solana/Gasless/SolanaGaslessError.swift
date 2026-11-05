//
//  SolanaGaslessError.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum SolanaGaslessError: LocalizedError, Equatable {
    case invalidFeePayer
    case malformedTransaction
    case transactionAlreadySigned
    case walletIsNotFeePayer
    case feePayerAlreadyPresent
    case accountIndexOverflow
    case missingFeeParameters
    case unsupportedAmountType
    case missingLastValidBlockHeight

    public var errorDescription: String? {
        switch self {
        case .invalidFeePayer: "Invalid Solana gasless fee payer address"
        case .malformedTransaction: "Malformed Solana transaction"
        case .transactionAlreadySigned: "Solana transaction is already signed"
        case .walletIsNotFeePayer: "Wallet is not the fee payer of the Solana transaction"
        case .feePayerAlreadyPresent: "Gasless fee payer is already present in the Solana transaction"
        case .accountIndexOverflow: "Solana transaction has too many accounts to add a fee payer"
        case .missingFeeParameters: "Solana fee parameters not found"
        case .unsupportedAmountType: "Unsupported amount type for a Solana gasless transaction"
        case .missingLastValidBlockHeight: "Solana latest blockhash has no last valid block height"
        }
    }
}
