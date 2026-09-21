//
//  CommonMobileWalletSdkImportTests.swift
//  TangemMobileWalletSdkTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
import Foundation
@testable import TangemMobileWalletSdk

struct CommonMobileWalletSdkImportTests {
    @Test
    func walletIdMatchesImportedIdAndWritesNothing() throws {
        let sdk = makeSdk()

        let derivedId = try sdk.walletId(entropy: entropy, passphrase: "pass")
        // Nothing stored yet: `walletId(entropy:passphrase:)` must not touch storage.
        #expect(throws: (any Error).self) { try sdk.validate(auth: .none, for: derivedId) }

        let importedId = try sdk.importWallet(entropy: entropy, passphrase: "pass")
        #expect(importedId == derivedId)
        _ = try sdk.validate(auth: .none, for: importedId)
    }

    @Test
    func importingAnAlreadyStoredWalletDoesNotOverwriteIt() throws {
        let sdk = makeSdk()

        let walletId = try sdk.importWallet(entropy: entropy, passphrase: "")
        let context = try sdk.validate(auth: .none, for: walletId)
        let seedKey = try #require(sdk.deriveMasterKeys(context: context).wallets.first { $0.curve == .secp256k1 }).publicKey
        try sdk.updateAccessCode("123456", enableBiometrics: false, seedKey: seedKey, context: context)

        // Access-code protected now: a plain `.none` unlock must be refused.
        #expect(throws: (any Error).self) { try sdk.validate(auth: .none, for: walletId) }

        // Re-importing the same phrase used to replace the protected key with an unprotected one.
        #expect(throws: MobileWalletError.walletAlreadyExists) {
            try sdk.importWallet(entropy: entropy, passphrase: "")
        }

        // Storage is untouched: still refuses `.none`, still accepts the access code.
        #expect(throws: (any Error).self) { try sdk.validate(auth: .none, for: walletId) }
        _ = try sdk.validate(auth: .accessCode("123456"), for: walletId)
    }
}
