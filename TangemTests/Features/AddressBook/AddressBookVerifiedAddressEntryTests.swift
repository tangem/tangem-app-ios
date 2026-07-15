//
//  AddressBookVerifiedAddressEntryTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
@testable import Tangem

@Suite("AddressBookVerifiedAddressEntryBuilder")
struct AddressBookVerifiedAddressEntryBuilderTests {
    private let contactId = AddressBookContactID()
    private let walletPublicKey = Data(repeating: 0xB2, count: 33)
    private let blockchain: BSDKBlockchain = .bitcoin(testnet: false)

    @Test
    func buildsVerifiedEntryWhenSignatureValidAndNetworkSupported() throws {
        let decoded = makeDecoded()
        let entry = makeBuilder(supporting: [blockchain]).make(
            verifying: decoded,
            contactId: contactId,
            contactName: try name("Alice"),
            walletPublicKey: walletPublicKey,
            verifier: AcceptingVerifier()
        )

        let verified = try #require(entry)
        #expect(verified.id == decoded.id)
        #expect(verified.address == decoded.address)
        #expect(verified.blockchain == blockchain)
        #expect(verified.memo == decoded.memo)
    }

    @Test
    func dropsEntryWhenSignatureInvalid() throws {
        let entry = makeBuilder(supporting: [blockchain]).make(
            verifying: makeDecoded(),
            contactId: contactId,
            contactName: try name("Alice"),
            walletPublicKey: walletPublicKey,
            verifier: RejectingVerifier()
        )

        #expect(entry == nil)
    }

    @Test
    func dropsEntryWhenNetworkUnsupportedEvenWithValidSignature() throws {
        let entry = makeBuilder(supporting: [.ethereum(testnet: false)]).make(
            verifying: makeDecoded(),
            contactId: contactId,
            contactName: try name("Alice"),
            walletPublicKey: walletPublicKey,
            verifier: AcceptingVerifier()
        )

        #expect(entry == nil)
    }

    // MARK: - Fixtures

    private func makeBuilder(supporting blockchains: Set<BSDKBlockchain>) -> AddressBookVerifiedAddressEntryBuilder {
        AddressBookVerifiedAddressEntryBuilder(supportedBlockchains: blockchains)
    }

    private func makeDecoded() -> AddressBookDecodedAddressEntry {
        AddressBookDecodedAddressEntry(
            id: AddressBookAddressEntryID(),
            address: "bc1qtest",
            networkId: AddressBookNetworkID(blockchain.networkId),
            memo: nil,
            signature: Data([0x01])
        )
    }

    private func name(_ value: String) throws -> AddressBookContactName {
        try AddressBookContactNameValidator().validate(value)
    }
}

// MARK: - Test doubles

private struct AcceptingVerifier: AddressBookSignatureVerifying {
    func isSignatureValid(_ signature: Data, of digest: Data, walletPublicKey: Data) -> Bool { true }
}

private struct RejectingVerifier: AddressBookSignatureVerifying {
    func isSignatureValid(_ signature: Data, of digest: Data, walletPublicKey: Data) -> Bool { false }
}
