//
//  RecoveryKeyEncryptionError.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum RecoveryKeyEncryptionError: Error, LocalizedError {
    case unsupportedAlgorithm(String)
    case invalidPublicKey
    case encryptionFailed(code: Int?)

    var errorDescription: String? {
        switch self {
        case .unsupportedAlgorithm(let algorithm):
            "The recovery public key algorithm is not supported: \(algorithm)"
        case .invalidPublicKey:
            "The recovery public key is invalid"
        case .encryptionFailed(let code):
            "Failed to encrypt the recovery key (code: \(code.map(String.init) ?? "unknown"))"
        }
    }
}
