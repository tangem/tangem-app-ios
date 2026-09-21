//
//  AddressBookContactFinderTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
import TangemFoundation
@testable import Tangem

@Suite("AddressBookContactFinder")
struct AddressBookContactFinderTests {
    private let ownWalletId = UserWalletId(value: Data(repeating: 0xA1, count: 32))
    private let otherWalletId = UserWalletId(value: Data(repeating: 0xC3, count: 32))
    private let walletPublicKey = Data(repeating: 0xB2, count: 33)
    private let evm: BSDKBlockchain = .ethereum(testnet: false)
    private let nonEvm: BSDKBlockchain = .bitcoin(testnet: false)
    private let baseDate = Date(timeIntervalSince1970: 0)
    /// `AddressComparator` applies its EVM rule only to strings that pass `isEvmAddress`, so the fixture has to
    /// be a real 20-byte address rather than a short stand-in.
    private static let evmAddress = "0x5aaeb6053f3e94c9b9a09f33669435e7ef1beaed"

    // MARK: - Matching

    @Test
    func matchesSavedAddressOnItsNetwork() throws {
        let alice = try makeContact(name: "Alice", address: "0xfeedface", blockchain: evm, walletId: ownWalletId)
        let finder = makeFinder(contacts: [alice])

        #expect(finder.contact(address: "0xfeedface", networkId: networkId(evm))?.name.value == "Alice")
    }

    @Test
    func matchesEvmAddressIgnoringCase() throws {
        let alice = try makeContact(name: "Alice", address: Self.evmAddress, blockchain: evm, walletId: ownWalletId)
        let finder = makeFinder(contacts: [alice])

        #expect(finder.contact(address: Self.evmAddress.uppercased(), networkId: networkId(evm))?.name.value == "Alice")
    }

    /// Off EVM the case is part of the address, so a differently-cased string is a different address and must
    /// not borrow the contact's name.
    @Test
    func doesNotMatchANonEvmAddressWithDifferentCase() throws {
        let bob = try makeContact(name: "Bob", address: "DBob1Address", blockchain: nonEvm, walletId: ownWalletId)
        let finder = makeFinder(contacts: [bob])

        #expect(finder.contact(address: "DBob1Address", networkId: networkId(nonEvm))?.name.value == "Bob")
        #expect(finder.contact(address: "dbob1address", networkId: networkId(nonEvm)) == nil)
    }

    @Test
    func matchesAcrossAllNetworksWhenNoneIsGiven() throws {
        let alice = try makeContact(name: "Alice", address: "0xfeedface", blockchain: evm, walletId: ownWalletId)
        let finder = makeFinder(contacts: [alice])

        #expect(finder.contact(address: "0xfeedface", networkId: nil)?.name.value == "Alice")
    }

    @Test
    func doesNotMatchAnUnsavedAddress() throws {
        let alice = try makeContact(name: "Alice", address: "0xfeedface", blockchain: evm, walletId: ownWalletId)
        let finder = makeFinder(contacts: [alice])

        #expect(finder.contact(address: "0xdeadbeef", networkId: networkId(evm)) == nil)
    }

    /// The same address saved on another chain names a different person, and the "add contact" action stays
    /// network-scoped too — so a cross-network match would contradict it.
    @Test
    func doesNotMatchTheSameAddressOnAnotherNetwork() throws {
        let alice = try makeContact(name: "Alice", address: "0xfeedface", blockchain: evm, walletId: ownWalletId)
        let finder = makeFinder(contacts: [alice])

        #expect(finder.contact(address: "0xfeedface", networkId: networkId(.polygon(testnet: false))) == nil)
    }

    @Test
    func emptyBooksResolveToNothing() {
        #expect(makeFinder(contacts: []).contact(address: "0xfeedface", networkId: networkId(evm)) == nil)
    }

    // MARK: - Conflict resolution

    @Test
    func contactFromTheTransactionWalletWinsOverAnotherWallet() throws {
        let mine = try makeContact(name: "Alice", address: "0xfeedface", blockchain: evm, walletId: ownWalletId, createdAt: .distantPast)
        let theirs = try makeContact(name: "Bob", address: "0xfeedface", blockchain: evm, walletId: otherWalletId, createdAt: .distantFuture)
        let finder = makeFinder(contacts: [theirs, mine])

        #expect(finder.contact(address: "0xfeedface", networkId: networkId(evm))?.name.value == "Alice")
    }

    @Test
    func contactFromAnotherWalletIsUsedWhenTheTransactionWalletHasNone() throws {
        let theirs = try makeContact(name: "Bob", address: "0xfeedface", blockchain: evm, walletId: otherWalletId)
        let finder = makeFinder(contacts: [theirs])

        #expect(finder.contact(address: "0xfeedface", networkId: networkId(evm))?.name.value == "Bob")
    }

    @Test
    func mostRecentlyCreatedWinsAmongOtherWallets() throws {
        let thirdWalletId = UserWalletId(value: Data(repeating: 0xD4, count: 32))
        let older = try makeContact(name: "Bob", address: "0xfeedface", blockchain: evm, walletId: otherWalletId, createdAt: baseDate)
        let newer = try makeContact(name: "Carol", address: "0xfeedface", blockchain: evm, walletId: thirdWalletId, createdAt: baseDate.addingTimeInterval(1))
        let finder = makeFinder(contacts: [older, newer])

        #expect(finder.contact(address: "0xfeedface", networkId: networkId(evm))?.name.value == "Carol")
    }

    @Test
    func mostRecentlyCreatedWinsWithinTheTransactionWallet() throws {
        let older = try makeContact(name: "Bob", address: "bc1qbob", blockchain: nonEvm, walletId: ownWalletId, createdAt: baseDate)
        let newer = try makeContact(name: "Carol", address: "bc1qbob", blockchain: nonEvm, walletId: ownWalletId, createdAt: baseDate.addingTimeInterval(1))
        let finder = makeFinder(contacts: [newer, older])

        #expect(finder.contact(address: "bc1qbob", networkId: networkId(nonEvm))?.name.value == "Carol")
    }

    // MARK: - Fixtures

    private func makeFinder(contacts: [AddressBookContact]) -> AddressBookContactFinder {
        AddressBookContactFinder(contacts: contacts, walletId: ownWalletId)
    }

    private func networkId(_ blockchain: BSDKBlockchain) -> AddressBookNetworkID {
        AddressBookNetworkID(blockchain.networkId)
    }

    private func makeContact(
        name value: String,
        address: String,
        blockchain: BSDKBlockchain,
        walletId: UserWalletId,
        createdAt: Date = Date()
    ) throws -> AddressBookContact {
        let contactId = AddressBookContactID()
        let contactName = try AddressBookContactNameValidator().validate(value)
        let decoded = AddressBookDecodedAddressEntry(
            id: AddressBookAddressEntryID(),
            address: address,
            networkId: AddressBookNetworkID(blockchain.networkId),
            memo: nil,
            signature: Data([0x01])
        )

        let entry = try #require(
            AddressBookVerifiedAddressEntryBuilder(supportedBlockchains: [blockchain]).make(
                verifying: decoded,
                contactId: contactId,
                contactName: contactName,
                walletPublicKey: walletPublicKey,
                verifier: AcceptingAddressBookSignatureVerifier()
            )
        )

        return AddressBookContact(
            id: contactId,
            walletId: walletId,
            name: contactName,
            appearance: AddressBookContactAppearance(rawColor: "MexicanPink"),
            createdAt: createdAt,
            entries: try #require(AddressBookContactVerifiedEntries([entry]))
        )
    }
}
