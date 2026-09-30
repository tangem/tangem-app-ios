//
//  TonConnectSessionCryptoTests.swift
//  TangemModules
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Sodium
import Testing
@testable import TangemTonConnect

@Suite(.tags(.tonConnect))
struct TonConnectSessionCryptoTests {
    private let crypto = TonConnectSessionCrypto()

    @Test
    func generatedKeyPairHas32ByteKeysAndDistinctValues() throws {
        let first = try crypto.generateKeyPair()
        let second = try crypto.generateKeyPair()

        #expect(first.publicKey.count == 32)
        #expect(first.secretKey.count == 32)
        #expect(first.publicKey != second.publicKey)
        #expect(first.clientID.hexString == first.publicKey.tonConnectHexString)
    }

    @Test
    func roundTripsBetweenDAppAndWallet() throws {
        let dApp = try crypto.generateKeyPair()
        let wallet = try crypto.generateKeyPair()
        let plaintext = Data(#"{"method":"sendTransaction","params":["{}"],"id":"1"}"#.utf8)

        let envelope = try crypto.encrypt(plaintext, to: wallet.clientID, using: dApp)
        let opened = try crypto.decrypt(envelope, from: dApp.clientID, using: wallet)

        #expect(opened == plaintext)
    }

    @Test
    func envelopeIsNoncePlusNaclBoxCiphertext() throws {
        let dApp = try crypto.generateKeyPair()
        let wallet = try crypto.generateKeyPair()
        let plaintext = Data("hello".utf8)

        let envelope = try crypto.encrypt(plaintext, to: wallet.clientID, using: dApp)

        // 24-byte nonce ++ 16-byte MAC ++ plaintext
        #expect(envelope.count == TonConnectSessionCrypto.nonceByteCount + 16 + plaintext.count)

        let nonce = Array(envelope.prefix(TonConnectSessionCrypto.nonceByteCount))
        let ciphertext = Array(envelope.dropFirst(TonConnectSessionCrypto.nonceByteCount))
        let opened = Sodium().box.open(
            authenticatedCipherText: ciphertext,
            senderPublicKey: Array(dApp.publicKey),
            recipientSecretKey: Array(wallet.secretKey),
            nonce: nonce
        )
        #expect(opened.map { Data($0) } == plaintext, "layout must be exactly what a reference nacl.box.open expects")
    }

    @Test
    func usesFreshNonceForEveryMessage() throws {
        let dApp = try crypto.generateKeyPair()
        let wallet = try crypto.generateKeyPair()
        let plaintext = Data("same".utf8)

        let first = try crypto.encrypt(plaintext, to: wallet.clientID, using: dApp)
        let second = try crypto.encrypt(plaintext, to: wallet.clientID, using: dApp)

        #expect(first.prefix(24) != second.prefix(24))
        #expect(first != second)
    }

    @Test
    func rejectsTamperedTruncatedAndForeignMessages() throws {
        let dApp = try crypto.generateKeyPair()
        let wallet = try crypto.generateKeyPair()
        let stranger = try crypto.generateKeyPair()
        let envelope = try crypto.encrypt(Data("secret".utf8), to: wallet.clientID, using: dApp)

        var tampered = envelope
        tampered[tampered.count - 1] ^= 0x01
        #expect(throws: TonConnectError.decryptionFailed) {
            try crypto.decrypt(tampered, from: dApp.clientID, using: wallet)
        }

        #expect(throws: TonConnectError.decryptionFailed) {
            try crypto.decrypt(envelope.prefix(30), from: dApp.clientID, using: wallet)
        }

        #expect(throws: TonConnectError.decryptionFailed) {
            try crypto.decrypt(Data(repeating: 0, count: 24), from: dApp.clientID, using: wallet)
        }

        #expect(throws: TonConnectError.decryptionFailed) {
            try crypto.decrypt(envelope, from: stranger.clientID, using: wallet)
        }

        #expect(throws: TonConnectError.decryptionFailed) {
            try crypto.decrypt(envelope, from: dApp.clientID, using: stranger)
        }
    }

    @Test
    func keyPairRejectsWrongLengths() {
        #expect(throws: TonConnectError.cryptoFailure) {
            try TonConnectSessionKeyPair(publicKey: Data(repeating: 1, count: 31), secretKey: Data(repeating: 2, count: 32))
        }
        #expect(throws: TonConnectError.cryptoFailure) {
            try TonConnectSessionKeyPair(publicKey: Data(repeating: 1, count: 32), secretKey: Data())
        }
    }
}
