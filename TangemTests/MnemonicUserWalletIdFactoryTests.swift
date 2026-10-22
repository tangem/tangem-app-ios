//
//  MnemonicUserWalletIdFactoryTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
import TangemMobileWalletSdk
import TangemSdk
@testable import Tangem

struct MnemonicUserWalletIdFactoryTests {
    private let factory = MnemonicUserWalletIdFactory()

    @Test(arguments: ["", "passphrase"])
    func userWalletIdMatchesTheMobileWalletSdkImport(passphrase: String) throws {
        let mnemonic = try Mnemonic(with: Constants.mnemonic)
        let sdk = CommonMobileWalletSdk()

        let importedWalletId = try sdk.importWallet(entropy: mnemonic.getEntropy(), passphrase: passphrase)
        defer { try? sdk.delete(walletIDs: [importedWalletId]) }

        let userWalletId = try factory.makeUserWalletId(mnemonic: mnemonic, passphrase: passphrase)

        #expect(userWalletId == importedWalletId)
    }

    @Test(arguments: ["\u{0}", "\u{0}suffix", "prefix\u{0}"])
    func rejectsPassphraseWithNullCharacterBeforeDeriving(passphrase: String) throws {
        let mnemonic = try Mnemonic(with: Constants.mnemonic)

        #expect(throws: PassphraseValidator.ValidationError.containsNullCharacter) {
            try factory.makeUserWalletId(mnemonic: mnemonic, passphrase: passphrase)
        }
    }

    @Test
    func rejectsPassphraseOverTheByteLimitBeforeDeriving() throws {
        let mnemonic = try Mnemonic(with: Constants.mnemonic)

        #expect(throws: PassphraseValidator.ValidationError.tooLong(maxByteCount: 256)) {
            try factory.makeUserWalletId(mnemonic: mnemonic, passphrase: String(repeating: "a", count: 257))
        }
    }

    @Test
    func passphraseChangesTheUserWalletId() throws {
        let mnemonic = try Mnemonic(with: Constants.mnemonic)

        let withoutPassphrase = try factory.makeUserWalletId(mnemonic: mnemonic, passphrase: "")
        let withPassphrase = try factory.makeUserWalletId(mnemonic: mnemonic, passphrase: "passphrase")

        #expect(withoutPassphrase != withPassphrase)
    }
}

private extension MnemonicUserWalletIdFactoryTests {
    enum Constants {
        static let mnemonic = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
    }
}
