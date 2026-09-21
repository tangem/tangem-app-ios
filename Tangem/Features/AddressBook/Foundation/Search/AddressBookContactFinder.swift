//
//  AddressBookContactFinder.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Finds the contact that should name an address.
///
/// Address books are per-wallet, so one address can be saved under different names in several books on the
/// device. The contact from `walletId` — the wallet the address is being shown for — wins; among contacts from
/// other wallets (or among several contacts of the same book) the most recently created one wins. Pass `nil`
/// where no wallet is preferred and only recency decides.
struct AddressBookContactFinder {
    private let byPriority: [AddressBookContact]
    private let byNetwork: [AddressBookNetworkID: [AddressBookContact]]

    init(contacts: [AddressBookContact], walletId: UserWalletId?) {
        let byPriority = contacts.sorted { isHigherPriority($0, than: $1, preferring: walletId) }

        var byNetwork: [AddressBookNetworkID: [AddressBookContact]] = [:]

        for contact in byPriority {
            for networkId in Set(contact.entries.raw.map(\.networkId)) {
                byNetwork[networkId, default: []].append(contact)
            }
        }

        self.byPriority = byPriority
        self.byNetwork = byNetwork
    }

    func contact(address: String, networkId: AddressBookNetworkID?) -> AddressBookContact? {
        let candidates = networkId.map { byNetwork[$0] ?? [] } ?? byPriority

        return candidates.first { $0.entries.contains(address: address, networkId: networkId) }
    }
}

private func isHigherPriority(
    _ lhs: AddressBookContact,
    than rhs: AddressBookContact,
    preferring walletId: UserWalletId?
) -> Bool {
    let isLhsOwnBook = lhs.walletId == walletId
    let isRhsOwnBook = rhs.walletId == walletId

    guard isLhsOwnBook == isRhsOwnBook else {
        return isLhsOwnBook
    }

    return lhs.createdAt > rhs.createdAt
}
