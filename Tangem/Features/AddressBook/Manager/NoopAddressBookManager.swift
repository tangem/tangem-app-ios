//
//  NoopAddressBookManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// No-op manager for locked wallets and previews/mocks: a locked or fake wallet contributes no
/// contacts and accepts no mutations.
final class NoopAddressBookManager: AddressBookManager {
    var contactsPublisher: AnyPublisher<[AddressBookContact], Never> {
        Just([]).eraseToAnyPublisher()
    }

    var syncStatePublisher: AnyPublisher<AddressBookSyncState, Never> {
        Just(.synced).eraseToAnyPublisher()
    }

    func load() async {}
    func createContact(name: AddressBookContactName, entries: [AddressBookEntryDraft]) async throws {}
    func renameContact(id: AddressBookContactID, to name: AddressBookContactName) async throws {}
    func addEntries(_ entries: [AddressBookEntryDraft], toContactWith id: AddressBookContactID) async throws {}
    func updateEntry(id: AddressBookAddressEntryID, inContactWith contactId: AddressBookContactID, to draft: AddressBookEntryDraft) async throws {}
    func deleteEntry(id: AddressBookAddressEntryID, fromContactWith contactId: AddressBookContactID) async throws {}
    func deleteContact(id: AddressBookContactID) async throws {}
}
