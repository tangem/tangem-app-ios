//
//  AddressBookContactMatcherTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
import TangemFoundation
@testable import Tangem

@Suite("AddressBookContactMatcher")
struct AddressBookContactMatcherTests {
    private let matcher = AddressBookContactMatcher()
    private let walletId = UserWalletId(value: Data(repeating: 0xA1, count: 32))
    private let walletPublicKey = Data(repeating: 0xB2, count: 33)
    private let evm: BSDKBlockchain = .ethereum(testnet: false)
    private let nonEvm: BSDKBlockchain = .bitcoin(testnet: false)

    // MARK: - Query normalization

    @Test
    func emptyQueryReturnsAllContacts() throws {
        let contacts = [
            try makeContact(name: "Alice", address: "0xfeedface", blockchain: evm),
            try makeContact(name: "Bob", address: "bc1qbob", blockchain: nonEvm),
        ]
        #expect(matcher.filter(contacts, query: "") == contacts)
    }

    @Test
    func whitespaceOnlyQueryReturnsAllContacts() throws {
        let contacts = [
            try makeContact(name: "Alice", address: "0xfeedface", blockchain: evm),
            try makeContact(name: "Bob", address: "bc1qbob", blockchain: nonEvm),
        ]
        #expect(matcher.filter(contacts, query: "   \n\t ") == contacts)
    }

    @Test
    func trimsSurroundingWhitespaceBeforeMatching() throws {
        let alice = try makeContact(name: "Alice", address: "0xfeedface", blockchain: evm)
        #expect(matcher.filter([alice], query: "  Alice \n").map(\.name.value) == ["Alice"])
    }

    // MARK: - Name matching

    @Test(arguments: ["alice", "ALICE", "Ali", "lic"])
    func matchesByNameCaseInsensitively(_ query: String) throws {
        let alice = try makeContact(name: "Alice", address: "0xfeedface", blockchain: evm)
        let bob = try makeContact(name: "Bob", address: "bc1qbob", blockchain: nonEvm)
        #expect(matcher.filter([alice, bob], query: query).map(\.name.value) == ["Alice"])
    }

    // MARK: - Network matching

    @Test
    func matchesByNetworkId() throws {
        let alice = try makeContact(name: "Alice", address: "0xfeedface", blockchain: evm)
        let bob = try makeContact(name: "Bob", address: "bc1qbob", blockchain: nonEvm)

        #expect(matcher.filter([alice, bob], query: "ethereum").map(\.name.value) == ["Alice"])
        #expect(matcher.filter([alice, bob], query: "bitcoin").map(\.name.value) == ["Bob"])
    }

    @Test
    func matchesByBlockchainDisplayNameEvenWhenAbsentFromNetworkId() throws {
        let contact = try makeContact(name: "Sam", address: "0x1234", blockchain: .bsc(testnet: false))
        #expect(matcher.filter([contact], query: "BNB").map(\.name.value) == ["Sam"])
    }

    // MARK: - Address matching (full match; case sensitivity per network)

    @Test
    func addressMatchesOnFullString() throws {
        let zed = try makeContact(name: "Zed", address: "0xAABBccdd", blockchain: evm)
        let yan = try makeContact(name: "Yan", address: "bc1qABCDxyz", blockchain: nonEvm)

        #expect(matcher.filter([zed, yan], query: "0xAABBccdd").map(\.name.value) == ["Zed"])
        #expect(matcher.filter([zed, yan], query: " bc1qABCDxyz \n").map(\.name.value) == ["Yan"])
        #expect(matcher.matches(zed, query: "0xAABBccdd"))
    }

    @Test
    func evmAddressMatchIsCaseInsensitive() throws {
        let zed = try makeContact(name: "Zed", address: "0xAABBccdd", blockchain: evm)

        #expect(matcher.filter([zed], query: "0xaabbccdd").map(\.name.value) == ["Zed"])
        #expect(matcher.matches(zed, query: "0XAABBCCDD"))
    }

    @Test
    func nonEvmAddressInDifferentCaseDoesNotMatch() throws {
        let yan = try makeContact(name: "Yan", address: "bc1qABCDxyz", blockchain: nonEvm)

        #expect(matcher.filter([yan], query: "bc1qabcdxyz").isEmpty)
        #expect(!matcher.matches(yan, query: "bc1qabcdxyz"))
    }

    @Test
    func partialAddressDoesNotMatch() throws {
        let zed = try makeContact(name: "Zed", address: "0xAABBccdd", blockchain: evm)
        let yan = try makeContact(name: "Yan", address: "bc1qABCDxyz", blockchain: nonEvm)

        #expect(matcher.filter([zed, yan], query: "0xAABB").isEmpty)
        #expect(matcher.filter([zed, yan], query: "0xaabb").isEmpty)
        #expect(matcher.filter([zed, yan], query: "ABCDxyz").isEmpty)
    }

    // MARK: - No match

    @Test
    func noMatchReturnsEmptyArray() throws {
        let contacts = [
            try makeContact(name: "Alice", address: "0xfeedface", blockchain: evm),
            try makeContact(name: "Bob", address: "bc1qbob", blockchain: nonEvm),
        ]
        #expect(matcher.filter(contacts, query: "zzz-nothing").isEmpty)
    }

    // MARK: - Fixtures

    private func makeContact(name value: String, address: String, blockchain: BSDKBlockchain) throws -> AddressBookContact {
        let contactId = AddressBookContactID()
        let contactName = try name(value)
        let entry = makeVerifiedEntry(address: address, blockchain: blockchain, contactId: contactId, contactName: contactName)

        return AddressBookContact(
            id: contactId,
            walletId: walletId,
            name: contactName,
            appearance: AddressBookContactAppearance(rawColor: "MexicanPink"),
            entries: AddressBookContactVerifiedEntries([entry])!
        )
    }

    private func makeVerifiedEntry(
        address: String,
        blockchain: BSDKBlockchain,
        contactId: AddressBookContactID,
        contactName: AddressBookContactName
    ) -> AddressBookVerifiedAddressEntry {
        let decoded = AddressBookDecodedAddressEntry(
            id: AddressBookAddressEntryID(),
            address: address,
            networkId: AddressBookNetworkID(blockchain.networkId),
            memo: nil,
            signature: Data([0x01])
        )

        return AddressBookVerifiedAddressEntryBuilder(supportedBlockchains: [blockchain]).make(
            verifying: decoded,
            contactId: contactId,
            contactName: contactName,
            walletPublicKey: walletPublicKey,
            verifier: AcceptingVerifier()
        )!
    }

    private func name(_ value: String) throws -> AddressBookContactName {
        try AddressBookContactNameValidator().validate(value)
    }
}

// MARK: - Test doubles

private struct AcceptingVerifier: AddressBookSignatureVerifying {
    func isSignatureValid(_ signature: Data, of digest: Data, walletPublicKey: Data) -> Bool { true }
}
