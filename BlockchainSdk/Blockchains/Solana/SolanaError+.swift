//
//  SolanaError+.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SolanaSwift

extension SolanaError: @retroactive LocalizedError {
    public var errorDescription: String? {
        // [REDACTED_TODO_COMMENT]
        switch self {
        case .unauthorized:
            return "unauthorized"
        case .notFoundProgramAddress:
            return "notFoundProgramAddress"
        case .invalidRequest(let reason):
            return "invalidRequest (\(reason ?? ""))"
        case .invalidResponse(let error):
            /// This Solana error indicates a lack of funds for the transfer.
            if error.code == -32002, error.message?.contains(Constants.transactionSimulationFailedMessage) ?? false {
                return "The transaction couldn’t be completed. Your account has insufficient SOL for this transfer. Please top up your balance and try again.(Error: -32002 / 0x1)"
            }
            
            return "invalidResponse (\(error.code ?? -1))"
        case .socket:
            return "socket"
        case .couldNotRetriveAccountInfo:
            return "couldNotRetrieveAccountInfo"
        case .other(let reason):
            return "other (\(reason))"
        case .nullValue:
            return "nullValue"
        case .couldNotRetriveBalance:
            return "couldNotRetrieveBalance"
        case .blockHashNotFound:
            return "blockHashNotFound"
        case .invalidPublicKey:
            return "invalidPublicKey"
        case .invalidMNemonic:
            return "invalidMnemonic"
        }
    }
}

fileprivate extension SolanaError {
    enum Constants {
        static let transactionSimulationFailedMessage = "Transaction simulation failed: Transaction results in an account (0) with insufficient funds for rent"
    }
}
