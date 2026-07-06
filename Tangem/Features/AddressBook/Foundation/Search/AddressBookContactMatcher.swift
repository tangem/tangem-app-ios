//
//  AddressBookContactMatcher.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

struct AddressBookContactMatcher {
    func filter(_ contacts: [AddressBookContact], query: String) -> [AddressBookContact] {
        let raw = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !raw.isEmpty else {
            return contacts
        }

        return contacts.filter { matches($0, raw: raw) }
    }

    func matches(_ contact: AddressBookContact, query: String) -> Bool {
        let raw = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return raw.isEmpty || matches(contact, raw: raw)
    }

    private func matches(_ contact: AddressBookContact, raw: String) -> Bool {
        if contact.name.value.caseInsensitiveContains(raw) {
            return true
        }

        return contact.entries.raw.contains { entry in
            if entry.networkId.rawValue.caseInsensitiveContains(raw) || entry.blockchain.displayName.caseInsensitiveContains(raw) {
                return true
            }

            return entry.blockchain.isEvm
                ? entry.address.caseInsensitiveContains(raw)
                : entry.address.range(of: raw) != nil
        }
    }
}
