//
//  AddressBookContactEntriesTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
@testable import Tangem

@Suite("AddressBookContactEntries")
struct AddressBookContactEntriesTests {
    private let btc: BSDKBlockchain = .bitcoin(testnet: false)
    private let eth: BSDKBlockchain = .ethereum(testnet: false)

    private static let fixedEntryUUID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    private static let otherEntryUUID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

    // MARK: - Construction

    @Test
    func initReturnsNilForEmptyRawAndAValueOtherwise() {
        #expect(AddressBookContactDraftEntries([]) == nil)
        #expect(AddressBookContactDraftEntries([draft(address: "bc1qa", blockchain: btc)]) != nil)
    }

    // MARK: - Ordering

    @Test
    func rawPreservesInsertionOrder() {
        let entries = makeEntries([
            draft(address: "one", blockchain: btc),
            draft(address: "two", blockchain: btc),
            draft(address: "three", blockchain: btc),
        ])

        #expect(entries.raw.map(\.address) == ["one", "two", "three"])
    }

    // MARK: - Grouping

    @Test
    func groupedByAddressCollapsesAMultiNetworkAddressPreservingFirstSeenOrder() {
        let entries = makeEntries([
            draft(address: "addrA", blockchain: btc),
            draft(address: "addrA", blockchain: eth),
            draft(address: "addrB", blockchain: btc),
        ])

        let groups = entries.groupedByAddress
        #expect(groups.map(\.address) == ["addrA", "addrB"])
        #expect(groups[0].networks.map(\.blockchain) == [btc, eth])
        #expect(groups[1].networks.map(\.blockchain) == [btc])
    }

    @Test
    func groupedByAddressTakesMemoFromTheFirstEntrySeenForThatAddress() throws {
        let entries = makeEntries([
            draft(address: "addrA", blockchain: btc, memo: "first"),
            draft(address: "addrA", blockchain: eth, memo: "second"),
        ])

        let group = try #require(entries.groupedByAddress.first)
        #expect(group.memo == "first")
        #expect(group.networks.count == 2)
    }

    // MARK: - Distinct address count

    @Test
    func addressCountCountsDistinctAddressesNotRawEntries() {
        let entries = makeEntries([
            draft(address: "addrA", blockchain: btc),
            draft(address: "addrA", blockchain: eth),
            draft(address: "addrB", blockchain: btc),
        ])

        #expect(entries.addressCount == 2)
        #expect(entries.raw.count == 3)
    }

    // MARK: - Validation: max address count

    @Test
    func validateAcceptsTwentyDistinctAddresses() throws {
        try AddressBookContactDraftEntries.validate(adding: distinctDrafts(count: 20, on: btc), to: [])
    }

    @Test
    func validateRejectsTheTwentyFirstDistinctAddress() {
        #expect(throws: AddressBookValidationError.tooManyAddresses) {
            try AddressBookContactDraftEntries.validate(adding: distinctDrafts(count: 21, on: btc), to: [])
        }
    }

    @Test
    func validateCapsDistinctAddressesNotEntryCount() throws {
        let onBtc = distinctDrafts(count: 20, on: btc)
        let onEth = distinctDrafts(count: 20, on: eth)
        try AddressBookContactDraftEntries.validate(adding: onBtc + onEth, to: [])
    }

    @Test
    func validateCountsExistingAndAddedTowardTheCap() {
        let existing = distinctDrafts(count: 20, on: btc)
        #expect(throws: AddressBookValidationError.tooManyAddresses) {
            try AddressBookContactDraftEntries.validate(adding: [draft(address: "one-more", blockchain: btc)], to: existing)
        }
    }

    // MARK: - Validation: duplicate (address, networkId) pair

    @Test
    func validateRejectsADuplicateAddressNetworkPair() {
        let entry = draft(address: "bc1qsame", blockchain: btc)
        #expect(throws: AddressBookValidationError.duplicateAddressNetworkPair) {
            try AddressBookContactDraftEntries.validate(adding: [entry, entry], to: [])
        }
    }

    @Test
    func validateAllowsTheSameAddressOnDifferentNetworks() throws {
        let onBtc = draft(address: "shared", blockchain: btc)
        let onEth = draft(address: "shared", blockchain: eth)
        try AddressBookContactDraftEntries.validate(adding: [onBtc, onEth], to: [])
    }

    @Test
    func validateDetectsADuplicatePairAcrossExistingAndAdded() {
        let existing = draft(address: "bc1qdup", blockchain: btc)
        let adding = draft(address: "bc1qdup", blockchain: btc)
        #expect(throws: AddressBookValidationError.duplicateAddressNetworkPair) {
            try AddressBookContactDraftEntries.validate(adding: [adding], to: [existing])
        }
    }

    @Test
    func validatePairKeyIsCaseSensitiveOnTheAddress() throws {
        let lower = draft(address: "0xabc", blockchain: btc)
        let upper = draft(address: "0xABC", blockchain: btc)
        try AddressBookContactDraftEntries.validate(adding: [lower, upper], to: [])
    }

    // MARK: - caseInsensitiveContains

    @Test
    func caseInsensitiveContainsMatchesRegardlessOfCase() {
        let entries = makeEntries([draft(address: "0xAbCdEf", blockchain: btc)])

        #expect(entries.caseInsensitiveContains(address: "0xabcdef"))
        #expect(entries.caseInsensitiveContains(address: "0XABCDEF"))
        #expect(!entries.caseInsensitiveContains(address: "0xdead"))
    }

    // MARK: - Hashable / Equatable

    @Test
    func equalWhenRawEntriesMatchIncludingIds() {
        let id = AddressBookAddressEntryID(rawValue: Self.fixedEntryUUID)
        let lhs = makeEntries([draft(id: id, address: "addr", blockchain: btc, memo: "m")])
        let rhs = makeEntries([draft(id: id, address: "addr", blockchain: btc, memo: "m")])

        #expect(lhs == rhs)
        #expect(lhs.hashValue == rhs.hashValue)
    }

    @Test
    func notEqualWhenAnAddressDiffers() {
        let id = AddressBookAddressEntryID(rawValue: Self.fixedEntryUUID)
        let lhs = makeEntries([draft(id: id, address: "addrA", blockchain: btc)])
        let rhs = makeEntries([draft(id: id, address: "addrB", blockchain: btc)])

        #expect(lhs != rhs)
    }

    @Test
    func notEqualWhenOnlyTheEntryIdDiffers() {
        let lhs = makeEntries([draft(id: AddressBookAddressEntryID(rawValue: Self.fixedEntryUUID), address: "addr", blockchain: btc, memo: "m")])
        let rhs = makeEntries([draft(id: AddressBookAddressEntryID(rawValue: Self.otherEntryUUID), address: "addr", blockchain: btc, memo: "m")])

        #expect(lhs != rhs)
    }

    // MARK: - Fixtures

    private func makeEntries(_ raw: [AddressBookEntryDraft]) -> AddressBookContactDraftEntries {
        AddressBookContactDraftEntries(raw)!
    }

    private func draft(
        id: AddressBookAddressEntryID = AddressBookAddressEntryID(),
        address: String,
        blockchain: BSDKBlockchain,
        memo: String? = nil
    ) -> AddressBookEntryDraft {
        AddressBookEntryDraft(id: id, address: address, blockchain: blockchain, memo: memo)
    }

    private func distinctDrafts(count: Int, on blockchain: BSDKBlockchain) -> [AddressBookEntryDraft] {
        (0 ..< count).map { draft(address: "addr-\($0)", blockchain: blockchain) }
    }
}
