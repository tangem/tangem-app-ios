//
//  PassphraseValidator.swift
//  TangemMobileWalletSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public enum PassphraseValidator {
    public enum ValidationError: LocalizedError, Equatable {
        case tooLong(maxByteCount: Int)

        public var errorDescription: String? {
            switch self {
            case .tooLong(let maxByteCount):
                "The seed phrase passphrase must be at most \(maxByteCount) bytes long."
            }
        }
    }

    /// trezor-crypto copies at most this many passphrase bytes into the BIP-39 salt (`mnemonic_to_seed`), while the
    /// card path hands PBKDF2 the whole string, so a longer passphrase makes the two derive different keys.
    static let maxByteCount = 256

    /// The salt is built from the normalized passphrase, so the limit applies to its NFKD form.
    public static func validate(passphrase: String) throws {
        guard passphrase.decomposedStringWithCompatibilityMapping.utf8.count <= maxByteCount else {
            throw ValidationError.tooLong(maxByteCount: maxByteCount)
        }
    }
}
