//
//  PassphraseValidatorTests.swift
//  TangemMobileWalletSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
import Foundation
@testable import TangemMobileWalletSdk

struct PassphraseValidatorTests {
    private let tooLong = PassphraseValidator.ValidationError.tooLong(maxByteCount: PassphraseValidator.maxByteCount)

    @Test
    func acceptsPassphraseAtTheByteLimit() throws {
        try PassphraseValidator.validate(passphrase: String(repeating: "a", count: PassphraseValidator.maxByteCount))
    }

    @Test
    func acceptsEmptyPassphrase() throws {
        try PassphraseValidator.validate(passphrase: "")
    }

    @Test
    func rejectsPassphraseOverTheByteLimit() {
        #expect(throws: tooLong) {
            try PassphraseValidator.validate(passphrase: String(repeating: "a", count: PassphraseValidator.maxByteCount + 1))
        }
    }

    /// The BIP-39 salt is built from the normalized passphrase, so the limit has to be measured after NFKD grows it.
    @Test
    func rejectsPassphraseThatExceedsTheLimitOnlyAfterNormalization() {
        // Each Hangul syllable takes three bytes as typed and six once NFKD splits it into jamo.
        let passphrase = String(repeating: "\u{BC14}", count: 45)

        #expect(passphrase.utf8.count <= PassphraseValidator.maxByteCount)
        #expect(throws: tooLong) {
            try PassphraseValidator.validate(passphrase: passphrase)
        }
    }

    @Test
    func importRejectsPassphraseOverTheByteLimit() {
        let sdk = makeSdk()

        #expect(throws: tooLong) {
            try sdk.importWallet(
                entropy: entropy,
                passphrase: String(repeating: "a", count: PassphraseValidator.maxByteCount + 1)
            )
        }
    }
}
