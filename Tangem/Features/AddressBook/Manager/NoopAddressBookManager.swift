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
    var contactsPublisher: AnyPublisher<[ContactReadModel], Never> {
        Just([]).eraseToAnyPublisher()
    }

    var syncStatePublisher: AnyPublisher<AddressBookSyncState, Never> {
        Just(.synced).eraseToAnyPublisher()
    }

    func load() async {}
    func createContact(name: ContactName, entries: [AddressBookEntryDraft]) async throws {}
    func renameContact(id: ContactID, to name: ContactName) async throws {}
    func addEntries(_ entries: [AddressBookEntryDraft], toContactWith id: ContactID) async throws {}
    func updateEntry(id: AddressEntryID, inContactWith contactId: ContactID, to draft: AddressBookEntryDraft) async throws {}
    func deleteEntry(id: AddressEntryID, fromContactWith contactId: ContactID) async throws {}
    func deleteContact(id: ContactID) async throws {}
}
