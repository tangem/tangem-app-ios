//
//  JSONRPCError+WalletConnect.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct JSONRPC.JSONRPCError

extension JSONRPCError {
    static let userRejected = JSONRPCError(code: 4001, message: "User rejected the request.")
    static let unsupportedMethod = JSONRPCError(code: 4200, message: "The requested method is not supported.")
    static let unrecognizedChain = JSONRPCError(code: 4902, message: "Unrecognized chain ID.")
}

extension WalletConnectTransactionRequestProcessingError {
    var rpcError: JSONRPCError {
        switch self {
        case .invalidPayload:
            .invalidParams
        case .unsupportedBlockchain:
            .unrecognizedChain
        case .unsupportedMethod:
            .unsupportedMethod
        case .blockchainToAddRequiresDAppReconnection, .blockchainToAddIsMissingFromUserWallet:
            .userRejected
        default:
            .internalError
        }
    }
}
