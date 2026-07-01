//
//  CommonAddressBookEncryptionServiceTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit
import Testing
import TangemSdk
@testable import Tangem

/// Cross-platform known-answer vectors for `CommonAddressBookEncryptionService`.
///
/// The hex constants below are a contract shared with the Android client: from the same wallet public
/// key both platforms derive the same symmetric key and must produce/consume the exact same
/// AES-256-GCM nonce, ciphertext, tag and plaintext. Anyone can reproduce them with standard
/// primitives — `key = HMAC-SHA256(SHA256(seed), "TokensSymmetricKey")`, then `AES-256-GCM` with the
/// fixed nonce and empty additional data.
@Suite("CommonAddressBookEncryptionService")
struct CommonAddressBookEncryptionServiceTests {
    /// Public test wallet public key — the compressed secp256k1 key for the public test mnemonic
    /// "tiny escape drive pupil flavor endless love walk gadget match filter luxury", already used as
    /// the wallet-id seed across the suite (e.g. `MobileWalletAddressesTests`).
    private static let walletPublicKeySeedHex = "0374d0f81f42ddfe34114d533e95e6ae5fe6ea271c96f1fa505199fdc365ae9720"

    /// `UserWalletEncryptionKey(userWalletIdSeed:)` applied to the seed above.
    private static let expectedKeyHex = "59b85ce53fac0a8493d9d8d9c0d32adb5f586741dd8bbfd9348a3212e493730d"

    private static let sampleWalletPublicKeySeedHex = "021111111111111111111111111111111111111111111111111111111111111111"

    private static let nonceHex = "000102030405060708090a0b"
    private static let ciphertextHex = "f4ee0f404e747b5b5cca730c44baf86ca3d8f6fbdf66ff2fe98d3b8f88cb23df7ff55b52205f32c8ab"
    private static let tagHex = "6c4b71b27958f43afc6633850369a17a"
    private static let expectedPlaintext = "Tangem Address Book cross-platform vector"

    private let service = CommonAddressBookEncryptionService()

    private let seed = Data(hexString: Self.walletPublicKeySeedHex)
    private let sampleSeed = Data(hexString: Self.sampleWalletPublicKeySeedHex)
    private let vectorKey = SymmetricKey(data: Data(hexString: Self.expectedKeyHex))
    private let vectorSealedBox = AddressBookSealedBox(
        nonce: Data(hexString: Self.nonceHex),
        ciphertext: Data(hexString: Self.ciphertextHex),
        tag: Data(hexString: Self.tagHex)
    )

    // MARK: - Key derivation

    @Test
    func derivesSymmetricKeyFromPublicWalletSeed() {
        let key = CommonAddressBookEncryptionKeyProvider().encryptionKey(forWalletPublicKeySeed: seed)
        #expect(key == vectorKey)
    }

    @Test
    func derivesDistinctKeysForDistinctSeeds() {
        let provider = CommonAddressBookEncryptionKeyProvider()
        #expect(
            provider.encryptionKey(forWalletPublicKeySeed: seed)
                != provider.encryptionKey(forWalletPublicKeySeed: sampleSeed)
        )
    }

    @Test
    func derivesKeyMatchingTheDocumentedHmacDerivation() {
        let hmacKey = SymmetricKey(data: Data(SHA256.hash(data: sampleSeed)))
        let message = Data("TokensSymmetricKey".utf8)
        let expected = SymmetricKey(data: Data(HMAC<SHA256>.authenticationCode(for: message, using: hmacKey)))

        let derived = CommonAddressBookEncryptionKeyProvider().encryptionKey(forWalletPublicKeySeed: sampleSeed)
        #expect(derived == expected)
    }

    // MARK: - Decryption (known answer)

    @Test
    func decryptsSharedCrossPlatformVector() throws {
        let plaintext = try service.open(vectorSealedBox, using: vectorKey)
        #expect(plaintext == Data(Self.expectedPlaintext.utf8))
    }

    // MARK: - Round trip

    @Test
    func sealThenOpenRoundTripsPlaintext() throws {
        let plaintext = Data(Self.expectedPlaintext.utf8)
        let sealed = try service.seal(plaintext, using: vectorKey)
        let opened = try service.open(sealed, using: vectorKey)
        #expect(opened == plaintext)
    }

    @Test
    func roundTripsThroughTheProviderDerivedKey() throws {
        let key = CommonAddressBookEncryptionKeyProvider().encryptionKey(forWalletPublicKeySeed: seed)
        let plaintext = Data(Self.expectedPlaintext.utf8)
        let sealed = try service.seal(plaintext, using: key)
        #expect(try service.open(sealed, using: key) == plaintext)
    }

    @Test
    func roundTripsEmptyPlaintext() throws {
        let sealed = try service.seal(Data(), using: vectorKey)
        #expect(sealed.ciphertext.isEmpty)
        #expect(sealed.tag.count == 16)
        #expect(try service.open(sealed, using: vectorKey).isEmpty)
    }

    @Test
    func roundTripsArbitraryBinaryPlaintext() throws {
        let plaintext = Data((0 ... 255).map { UInt8($0) })
        let sealed = try service.seal(plaintext, using: vectorKey)
        #expect(try service.open(sealed, using: vectorKey) == plaintext)
    }

    @Test
    func sealProducesTwelveByteNonceAndSixteenByteTag() throws {
        let sealed = try service.seal(Data(Self.expectedPlaintext.utf8), using: vectorKey)
        #expect(sealed.nonce.count == 12)
        #expect(sealed.tag.count == 16)
    }

    @Test
    func eachSealUsesAFreshNonce() throws {
        let plaintext = Data(Self.expectedPlaintext.utf8)
        let first = try service.seal(plaintext, using: vectorKey)
        let second = try service.seal(plaintext, using: vectorKey)

        // A fresh random nonce per seal means identical plaintext yields a different nonce and ciphertext,
        // yet both still decrypt back to the original.
        #expect(first.nonce != second.nonce)
        #expect(first.ciphertext != second.ciphertext)
        #expect(try service.open(first, using: vectorKey) == plaintext)
        #expect(try service.open(second, using: vectorKey) == plaintext)
    }

    // MARK: - Authentication failures

    @Test
    func openWithWrongKeyThrowsAuthenticationFailed() {
        let wrongKey = SymmetricKey(size: .bits256)
        #expect(throws: AddressBookCryptoError.self) {
            try service.open(vectorSealedBox, using: wrongKey)
        }
    }

    @Test
    func openWithTamperedCiphertextThrowsAuthenticationFailed() {
        var ciphertext = Data(hexString: Self.ciphertextHex)
        ciphertext[ciphertext.startIndex] ^= 0xFF
        let tampered = AddressBookSealedBox(
            nonce: Data(hexString: Self.nonceHex),
            ciphertext: ciphertext,
            tag: Data(hexString: Self.tagHex)
        )
        #expect(throws: AddressBookCryptoError.self) {
            try service.open(tampered, using: vectorKey)
        }
    }

    @Test
    func openWithTamperedTagThrowsAuthenticationFailed() {
        var tag = Data(hexString: Self.tagHex)
        tag[tag.startIndex] ^= 0xFF
        let tampered = AddressBookSealedBox(
            nonce: Data(hexString: Self.nonceHex),
            ciphertext: Data(hexString: Self.ciphertextHex),
            tag: tag
        )
        #expect(throws: AddressBookCryptoError.self) {
            try service.open(tampered, using: vectorKey)
        }
    }
}
