//
//  CommonAddressBookSignatureVerifierTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemSdk
@testable import Tangem

@Suite("CommonAddressBookSignatureVerifier")
struct CommonAddressBookSignatureVerifierTests {
    private let verifier = CommonAddressBookSignatureVerifier()
    private let crypto = Secp256k1Utils()

    @Test
    func acceptsARealSecp256k1SignatureOverTheDigest() throws {
        let keyPair = try crypto.generateKeyPair()
        let message = Data("address-book-signed-tuple".utf8)
        let digest = message.getSHA256()
        let signature = try crypto.sign(message, with: keyPair.privateKey)

        #expect(verifier.isSignatureValid(signature, of: digest, walletPublicKey: keyPair.publicKey))
    }

    @Test
    func rejectsAValidSignatureAgainstADifferentDigest() throws {
        let keyPair = try crypto.generateKeyPair()
        let signature = try crypto.sign(Data("original".utf8), with: keyPair.privateKey)
        let tamperedDigest = Data("tampered".utf8).getSHA256()

        #expect(!verifier.isSignatureValid(signature, of: tamperedDigest, walletPublicKey: keyPair.publicKey))
    }

    @Test
    func rejectsAValidSignatureUnderTheWrongPublicKey() throws {
        let message = Data("address-book".utf8)
        let signature = try crypto.sign(message, with: crypto.generateKeyPair().privateKey)
        let unrelatedKey = try crypto.generateKeyPair().publicKey

        #expect(!verifier.isSignatureValid(signature, of: message.getSHA256(), walletPublicKey: unrelatedKey))
    }

    @Test
    func rejectsMalformedSignatureBytes() throws {
        let keyPair = try crypto.generateKeyPair()

        #expect(!verifier.isSignatureValid(Data(repeating: 0x00, count: 64), of: Data(repeating: 0x11, count: 32), walletPublicKey: keyPair.publicKey))
    }
}
