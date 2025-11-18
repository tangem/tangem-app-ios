//
//  WalletConnectURIParsingError.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import protocol Foundation.LocalizedError

enum WalletConnectURIParsingError: LocalizedError {
    case unsupportedWalletConnectVersion(version: String)
    case expired
    case invalidFormat(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedWalletConnectVersion(let version):
            "WalletConnect version \(version) is not supported by Tangem app."

        case .expired:
            "WalletConnect URI has expired."

        case .invalidFormat(let rawURI):
            "Failed to parse WalletConnect URI from: \(rawURI)"
        }
    }
}
