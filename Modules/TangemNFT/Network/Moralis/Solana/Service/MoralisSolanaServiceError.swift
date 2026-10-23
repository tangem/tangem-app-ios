//
//  MoralisSolanaServiceError.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public enum MoralisSolanaServiceError: Error {
    case unsupportedMethod(String)
    case chainFailed(code: String?, message: String?)
}

extension MoralisSolanaServiceError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unsupportedMethod(let message):
            message
        case .chainFailed(let code, let message):
            "Solana chain failed: \(code ?? "unknown code"), \(message ?? "no message")"
        }
    }
}
