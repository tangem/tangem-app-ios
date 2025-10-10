//
//  WalletConnectDAppPersistenceError.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import protocol Foundation.LocalizedError

enum WalletConnectDAppPersistenceError: LocalizedError {
    case notFound
    case retrievingFailed
    case savingFailed

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "DApp not found."

        case .retrievingFailed:
            return "DApp retrieval operation failed."

        case .savingFailed:
            return "DApp saving operation failed."
        }
    }
}
