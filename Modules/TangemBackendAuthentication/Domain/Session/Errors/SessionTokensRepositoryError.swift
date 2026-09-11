//
//  SessionTokensRepositoryError.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum SessionTokensRepositoryError: Error, Equatable {
    /// Encoding ``SessionTokens`` before writing it to the Keychain failed.
    case encodingFailed

    /// A Keychain item was found, but decoding its bytes back into ``SessionTokens`` failed.
    case decodingFailed

    /// ``KeychainRepository`` operation failed.
    case keychainFailure(KeychainRepositoryError)
}
