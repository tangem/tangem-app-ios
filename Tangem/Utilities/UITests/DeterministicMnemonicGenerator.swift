//
//  DeterministicMnemonicGenerator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

#if DEBUG
import Foundation
import CryptoKit
import TangemSdk

/// Generates deterministic BIP39 mnemonics from seed strings.
/// Used for UI testing to create reproducible wallet addresses without storing raw mnemonics in code.
///
/// TEST WALLETS ONLY - Never use for real funds.
/// The generated wallets should only be used with mock APIs (WireMock).
enum DeterministicMnemonicGenerator {
    /// Generates a 12-word BIP39 mnemonic from a seed string.
    /// The same seed string will always produce the same mnemonic.
    ///
    /// - Parameter seed: A unique identifier string (e.g., "uitest_wallet_1")
    /// - Returns: A 12-word BIP39 mnemonic phrase
    /// - Throws: If mnemonic generation fails
    static func generateMnemonic(from seed: String) throws -> String {
        // Generate 128-bit entropy from SHA256 hash of the seed string
        // 128 bits = 16 bytes = 12-word mnemonic
        let hash = SHA256.hash(data: Data(seed.utf8))
        let entropy = Data(hash.prefix(16))

        let mnemonic = try Mnemonic(entropyData: entropy, wordList: .en)
        return mnemonic.mnemonicComponents.joined(separator: " ")
    }

    /// Generates a 24-word BIP39 mnemonic from a seed string.
    /// The same seed string will always produce the same mnemonic.
    ///
    /// - Parameter seed: A unique identifier string (e.g., "uitest_wallet_1")
    /// - Returns: A 24-word BIP39 mnemonic phrase
    /// - Throws: If mnemonic generation fails
    static func generateLongMnemonic(from seed: String) throws -> String {
        // Generate 256-bit entropy from SHA256 hash of the seed string
        // 256 bits = 32 bytes = 24-word mnemonic
        let hash = SHA256.hash(data: Data(seed.utf8))
        let entropy = Data(hash)

        let mnemonic = try Mnemonic(entropyData: entropy, wordList: .en)
        return mnemonic.mnemonicComponents.joined(separator: " ")
    }
}
#endif
