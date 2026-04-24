//
//  SolanaError+.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SolanaSwift

extension SolanaSwift.SolanaError: @retroactive LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Solana request is unauthorized."

        case .notFoundProgramAddress:
            return "Solana program address was not found."

        case .invalidRequest(let reason):
            if let reason {
                return "Invalid Solana request. \(reason)."
            }
            return "Invalid Solana request."

        case .invalidResponse(let responseError):
            return responseError.sanitizedDescription()

        case .socket(let error):
            return "Solana socket error. \(error.localizedDescription)."

        case .couldNotRetriveAccountInfo:
            return "Could not retrieve Solana account info."

        case .other(let reason):
            return reason

        case .nullValue:
            return "Solana response contains an empty value."

        case .couldNotRetriveBalance:
            return "Could not retrieve Solana balance."

        case .blockHashNotFound:
            return "Solana blockhash was not found. Please try again."

        case .invalidPublicKey:
            return "Invalid Solana public key."

        case .invalidMNemonic:
            return "Invalid Solana mnemonic."
        }
    }
}

private extension SolanaSwift.ResponseError {
    func sanitizedDescription() -> String? {
        @inline(__always)
        func fallbackErrorDescription() -> String? {
            let errorCode = code.map(String.init) ?? "unknown code"
            let errorMessage = message ?? "Unknown error."

            return "RPC code: " + errorCode + " . " + errorMessage
        }

        guard
            message?.contains("Transaction simulation failed") == true,
            let logs = data?.logs
        else {
            return fallbackErrorDescription()
        }

        if logs.contains { $0.caseInsensitiveContains("insufficient funds") } {
            return "The transaction couldn’t be completed."
                + " Your account has insufficient tokens for this transfer."
                + " Please top up your balance and try again."
        }

        if logs.contains { $0.caseInsensitiveContains("insufficient lamports") } {
            return "The transaction couldn’t be completed."
                + " Your account has insufficient SOL for this transfer."
                + " Please top up your balance and try again."
        }

        return fallbackErrorDescription()
    }
}
