//
//  NoopAddressBookManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

/// No-op manager for locked wallets and previews/mocks: a locked or fake wallet contributes no
/// contacts and accepts no mutations.
final class NoopAddressBookManager: AddressBookManager {
    var contactsPublisher: AnyPublisher<[AddressBookContact], Never> {
        Just([]).eraseToAnyPublisher()
    }

    var contacts: [AddressBookContact] { [] }

    var syncStatePublisher: AnyPublisher<AddressBookSyncState, Never> {
        Just(.synced).eraseToAnyPublisher()
    }

    func load(silent: Bool) async {}
    func createContact(name: AddressBookContactName, appearance: AddressBookContactAppearance, entries: AddressBookContactDraftEntries) async throws -> AddressBookContactID { AddressBookContactID() }
    func reSignContact(id: AddressBookContactID, name: AddressBookContactName, appearance: AddressBookContactAppearance, entries: AddressBookContactDraftEntries) async throws {}
    func updateContact(id: AddressBookContactID, name: AddressBookContactName, appearance: AddressBookContactAppearance, entries: AddressBookContactDraftEntries) async throws {}
    func deleteContact(id: AddressBookContactID) async throws {}
}
