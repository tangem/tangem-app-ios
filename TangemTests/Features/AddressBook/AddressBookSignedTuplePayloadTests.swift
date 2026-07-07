//
//  AddressBookSignedTuplePayloadTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit
import Testing
import TangemSdk
@testable import Tangem

@Suite("AddressBookSignedTuplePayload")
struct AddressBookSignedTuplePayloadTests {
    private static let address = "0x1111111111111111111111111111111111111111"
    private static let networkId = "ethereum"
    private static let contactId = AddressBookContactID(rawValue: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!)
    private static let contactName = "Alice"

    private static let goldenDigestHex = "96ba546b0ff90129172bff07c96b1c4045347018a5661bf62d195b942e3340ba"

    private let walletPublicKey = Data(repeating: 0xB2, count: 33)

    // MARK: - Canonical layout

    @Test
    func canonicalDataConcatenatesFieldsInDefinedOrderWithoutSeparators() throws {
        let payload = try makePayload(memo: nil)
        let expected = Self.address + Self.networkId + "" + Self.contactId.stringValue + Self.contactName
        #expect(payload.canonicalData == Data(expected.utf8))
    }

    @Test
    func digestIsSha256OverCanonicalDataAndMatchesGoldenVector() throws {
        let payload = try makePayload(memo: nil)
        #expect(payload.digest == Data(SHA256.hash(data: payload.canonicalData)))
        #expect(payload.digest.count == 32)
        #expect(payload.digest == Data(hexString: Self.goldenDigestHex))
    }

    // MARK: - Memo normalization

    @Test
    func nilMemoEqualsEmptyStringMemo() throws {
        let nilMemo = try makePayload(memo: nil)
        let emptyMemo = try makePayload(memo: "")
        #expect(nilMemo.canonicalData == emptyMemo.canonicalData)
        #expect(nilMemo.digest == emptyMemo.digest)
    }

    // MARK: - Determinism & field sensitivity

    @Test
    func digestIsDeterministicForFixedInputs() throws {
        let first = try makePayload(memo: "memo")
        let second = try makePayload(memo: "memo")
        #expect(first.digest == second.digest)
    }

    @Test
    func changingAnyFieldChangesTheDigest() throws {
        let baseline = try makePayload(memo: "memo")
        let otherContactId = AddressBookContactID(rawValue: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!)

        #expect(try makePayload(address: "0x2222222222222222222222222222222222222222", memo: "memo").digest != baseline.digest)
        #expect(try makePayload(networkId: "bitcoin", memo: "memo").digest != baseline.digest)
        #expect(try makePayload(memo: "memo-tampered").digest != baseline.digest)
        #expect(try makePayload(memo: "memo", contactId: otherContactId).digest != baseline.digest)
        #expect(try makePayload(memo: "memo", name: "Bob").digest != baseline.digest)
    }

    // MARK: - Sign / verify round trip

    @Test
    func signThenVerifySucceeds() async throws {
        let payload = try makePayload(memo: "memo")
        let signer = StubSigner()
        let verifier = StubVerifier()

        let signatures = try await signer.sign(digests: [payload.digest], walletPublicKey: walletPublicKey)
        let signature = try #require(signatures.first)

        #expect(verifier.isSignatureValid(signature, of: payload.digest, walletPublicKey: walletPublicKey))
    }

    // MARK: - Fixtures

    private func makePayload(
        address: String = AddressBookSignedTuplePayloadTests.address,
        networkId: String = AddressBookSignedTuplePayloadTests.networkId,
        memo: String? = nil,
        contactId: AddressBookContactID = AddressBookSignedTuplePayloadTests.contactId,
        name: String = AddressBookSignedTuplePayloadTests.contactName
    ) throws -> AddressBookSignedTuplePayload {
        AddressBookSignedTuplePayload(
            address: address,
            networkId: AddressBookNetworkID(networkId),
            memo: memo,
            contactId: contactId,
            name: try AddressBookContactNameValidator().validate(name)
        )
    }
}

// MARK: - Test doubles

private enum StubSignatureScheme {
    static func signature(for digest: Data, walletPublicKey: Data) -> Data {
        var message = digest
        message.append(walletPublicKey)
        return Data(SHA256.hash(data: message))
    }
}

private struct StubSigner: AddressBookSigning {
    func sign(digests: [Data], walletPublicKey: Data) async throws -> [Data] {
        digests.map { StubSignatureScheme.signature(for: $0, walletPublicKey: walletPublicKey) }
    }
}

private struct StubVerifier: AddressBookSignatureVerifying {
    func isSignatureValid(_ signature: Data, of digest: Data, walletPublicKey: Data) -> Bool {
        signature == StubSignatureScheme.signature(for: digest, walletPublicKey: walletPublicKey)
    }
}
