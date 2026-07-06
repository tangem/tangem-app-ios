//
//  AddressBookContactEntries.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import BlockchainSdk

/// Address-book contact entries, generic over the entry kind: `AddressBookEntryDraft` while editing and
/// `AddressBookVerifiedAddressEntry` for the verified read model. The single home for the entry-set
/// logic — validation (max count + (address, networkId) uniqueness) and the flat↔grouped mapping.
///
/// `raw` is the flat list (one entry per address+network), used for signing, serialization and storage.
/// `groupedByAddress` is the UI view (one address with its networks). Always non-empty by construction —
/// `init?` returns nil for an empty list; callers that can legitimately have no entries (the editor in
/// the create flow) model that as an optional `AddressBookContactEntries?`.
struct AddressBookContactEntries<Entry: AddressBookEntry>: Hashable {
    /// Maximum number of distinct addresses a contact may hold (an address may span several networks).
    static var maxAddressCount: Int { 20 }

    let raw: [Entry]

    /// Number of distinct addresses — the user-facing unit the cap applies to, not the flat entry count.
    var addressCount: Int { raw.uniqueProperties(\.address).count }

    init?(_ raw: [Entry]) {
        guard !raw.isEmpty else {
            return nil
        }

        self.raw = raw
    }

    /// One group per distinct address (storage order preserved), each carrying the networks the address
    /// is saved in. The UI renders a contact as a list of addresses, each with its one or more networks.
    var groupedByAddress: [AddressBookContactAddressGroup] {
        var order: [String] = []
        var memoByAddress: [String: String?] = [:]
        var networksByAddress: [String: [AddressBookContactAddressGroup.Network]] = [:]

        for entry in raw {
            if networksByAddress[entry.address] == nil {
                order.append(entry.address)
                memoByAddress[entry.address] = entry.memo
            }

            networksByAddress[entry.address, default: []].append(
                AddressBookContactAddressGroup.Network(id: entry.id, blockchain: entry.blockchain)
            )
        }

        return order.map { address in
            AddressBookContactAddressGroup(
                address: address,
                memo: memoByAddress[address] ?? nil,
                networks: networksByAddress[address] ?? []
            )
        }
    }

    func caseInsensitiveContains(address: String) -> Bool {
        raw.contains { $0.address.caseInsensitiveEquals(to: address) }
    }

    /// Strict mutation-time validation, used by the editor before save: the max-count cap and
    /// (address, networkId) uniqueness within the contact. The manager re-validates authoritatively on save.
    static func validate(adding entries: [Entry], to existing: [Entry]) throws {
        let all = existing + entries

        guard all.uniqueProperties(\.address).count <= maxAddressCount else {
            throw AddressBookValidationError.tooManyAddresses
        }

        let pairs = all.map { pairKey($0) }

        guard pairs.unique().count == pairs.count else {
            throw AddressBookValidationError.duplicateAddressNetworkPair
        }
    }

    private static func pairKey(_ entry: Entry) -> String {
        "\(entry.address)|\(entry.networkId.rawValue)"
    }
}

typealias AddressBookContactDraftEntries = AddressBookContactEntries<AddressBookEntryDraft>
typealias AddressBookContactVerifiedEntries = AddressBookContactEntries<AddressBookVerifiedAddressEntry>

/// A contact address as shown in the UI: a single address with the one or more networks it is saved in.
struct AddressBookContactAddressGroup: Hashable, Identifiable {
    let address: String
    /// memo/destination tag belongs to the address, not to an individual network.
    let memo: String?
    let networks: [Network]

    var id: String { address }

    struct Network: Hashable, Identifiable {
        let id: AddressBookAddressEntryID
        let blockchain: BSDKBlockchain

        var networkId: AddressBookNetworkID { AddressBookNetworkID(blockchain.networkId) }
    }
}
