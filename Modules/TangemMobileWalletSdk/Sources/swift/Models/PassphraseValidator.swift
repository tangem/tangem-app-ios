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
        case containsNullCharacter

        public var errorDescription: String? {
            switch self {
            case .tooLong(let maxByteCount):
                "The seed phrase passphrase must be at most \(maxByteCount) bytes long."
            case .containsNullCharacter:
                "The seed phrase passphrase must not contain a null character."
            }
        }
    }

    /// trezor-crypto copies at most this many passphrase bytes into the BIP-39 salt (`mnemonic_to_seed`), while the
    /// card path hands PBKDF2 the whole string, so a longer passphrase makes the two derive different keys.
    static let maxByteCount = 256

    /// The mobile wallet derivation hands the passphrase to C as a null-terminated string, so a null character silently
    /// cuts it short while the card path keeps the whole string. The salt is built from the normalized passphrase, so
    /// the limit applies to its NFKD form.
    public static func validate(passphrase: String) throws {
        guard !passphrase.unicodeScalars.contains("\u{0}") else {
            throw ValidationError.containsNullCharacter
        }

        guard passphrase.decomposedStringWithCompatibilityMapping.utf8.count <= maxByteCount else {
            throw ValidationError.tooLong(maxByteCount: maxByteCount)
        }
    }
}
