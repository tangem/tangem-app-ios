//
//  AddressBookCryptoTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import CryptoKit
import TangemSdk
import TangemFoundation
@testable import Tangem

@Suite("AddressBook crypto")
struct AddressBookCryptoTests {
    @Test("AES-256-GCM seal/open round-trips")
    func aesRoundTrip() throws {
        let service = CommonAddressBookEncryptionService()
        let key = SymmetricKey(size: .bits256)
        let plaintext = Data(#"{"contacts":[]}"#.utf8)

        let sealed = try service.seal(plaintext, using: key)

        #expect(sealed.nonce.count == 12)
        #expect(sealed.tag.count == 16)
        #expect(try service.open(sealed, using: key) == plaintext)
    }

    @Test("tampered ciphertext fails authentication")
    func aesTamper() throws {
        let service = CommonAddressBookEncryptionService()
        let key = SymmetricKey(size: .bits256)
        let sealed = try service.seal(Data("payload".utf8), using: key)

        let tampered = AddressBookSealedBox(nonce: sealed.nonce, ciphertext: sealed.ciphertext + Data([0x00]), tag: sealed.tag)

        #expect(throws: AddressBookCryptoError.self) {
            _ = try service.open(tampered, using: key)
        }
    }

    @Test("wrong key fails authentication")
    func aesWrongKey() throws {
        let service = CommonAddressBookEncryptionService()
        let sealed = try service.seal(Data("payload".utf8), using: SymmetricKey(size: .bits256))

        #expect(throws: AddressBookCryptoError.self) {
            _ = try service.open(sealed, using: SymmetricKey(size: .bits256))
        }
    }

    @Test("encryption key is deterministic and matches the token-storage derivation")
    func keyDerivation() {
        let seed = Data(repeating: 7, count: 33)
        let provider = CommonAddressBookEncryptionKeyProvider()

        #expect(provider.encryptionKey(forWalletPublicKeySeed: seed) == provider.encryptionKey(forWalletPublicKeySeed: seed))
        #expect(provider.encryptionKey(forWalletPublicKeySeed: seed) == UserWalletEncryptionKey(userWalletIdSeed: seed).symmetricKey)
    }

    @Test("verifier accepts a signature over the digest and rejects a tampered one")
    func verifier() throws {
        let utils = Secp256k1Utils()
        let keyPair = try utils.generateKeyPair()
        let verifier = AddressBookSignatureVerifier()

        // `Secp256k1Utils.sign` signs SHA-256(input), so verify against that same hash. Passing this
        // proves the verifier uses the `hash:` path with no extra hashing — the `message:` path would
        // hash again and the signature would never verify.
        let preimage = Data("address|ethereum||contact|name".utf8)
        let signature = try utils.sign(preimage, with: keyPair.privateKey)
        let signedHash = preimage.getSHA256()

        #expect(verifier.isSignatureValid(signature, of: signedHash, walletPublicKey: keyPair.publicKey))
        #expect(!verifier.isSignatureValid(signature, of: Data(repeating: 0, count: 32), walletPublicKey: keyPair.publicKey))
    }

    @Test("signed-tuple canonical bytes follow the fixed cross-platform layout")
    func canonicalBytes() throws {
        let id = ContactID(rawValue: UUID(uuidString: "9C1F8A2E-7E35-4B8F-9A1C-5D2E8B6F4A10")!)
        let payload = SignedTuplePayload(
            address: "0xABC",
            networkId: AddressBookNetworkID("ethereum"),
            memo: nil,
            contactId: id,
            name: try ContactName(validating: "Binance")
        )

        let expected = "0xABC" + "ethereum" + "" + "9c1f8a2e-7e35-4b8f-9a1c-5d2e8b6f4a10" + "Binance"

        #expect(payload.canonicalData == Data(expected.utf8))
        #expect(payload.digest == Data(SHA256.hash(data: Data(expected.utf8))))
        #expect(payload.digest.count == 32)
    }

    @Test("memo changes the digest when present")
    func memoInDigest() throws {
        let id = ContactID()
        let name = try ContactName(validating: "Exchange")

        let withMemo = SignedTuplePayload(address: "r1", networkId: AddressBookNetworkID("xrp"), memo: "12345", contactId: id, name: name)
        let withoutMemo = SignedTuplePayload(address: "r1", networkId: AddressBookNetworkID("xrp"), memo: nil, contactId: id, name: name)

        #expect(withMemo.digest != withoutMemo.digest)
    }
}
