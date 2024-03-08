//
//  WalletConnectServiceError.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

enum WalletConnectServiceError: LocalizedError {
    case failedToConnect
    case signFailed
    case cancelled
    case timeout
    case deallocated
    case failedToFindSigner
    case sessionNotFound
    case txNotFound
    case failedToBuildTx(code: TxErrorCodes)
    case other(Error)
    case noChainId
    case unsupportedNetwork
    case switchChainNotSupported
    case notValidCard
    case networkNotFound(name: String)
    case unsupportedDApp

    var shouldHandle: Bool {
        switch self {
        case .cancelled, .deallocated, .failedToFindSigner: return false
        default: return true
        }
    }
}

extension WalletConnectServiceError {
    enum TxErrorCodes: String {
        case noWalletManager
        case wrongAddress
        case noValue
    }
}
