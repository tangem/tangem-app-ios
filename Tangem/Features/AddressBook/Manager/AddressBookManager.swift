//
//  AddressBookManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

/// Per-wallet facade over the address book. Verifies signatures on load, enforces the uniqueness
/// invariants, and signs (or re-signs) entries on every mutation that changes the signed tuple.
/// Deletes and reads never require a signature.
///
/// Uniqueness rules: the contact `name` is unique within the wallet (case-insensitive); the
/// `(address, networkId)` pair is unique only *within a contact* — the same pair may repeat across
/// different contacts of the same wallet.
protocol AddressBookManager: AnyObject {
    /// Verified contacts ready for display and the Send Flow. Invalid-signature entries are dropped;
    /// a contact whose every entry is invalid is omitted entirely (spec 2.1.3).
    var contactsPublisher: AnyPublisher<[AddressBookContact], Never> { get }
    var syncStatePublisher: AnyPublisher<AddressBookSyncState, Never> { get }

    func load() async

    func createContact(name: AddressBookContactName, entries: AddressBookContactDraftEntries) async throws
    func renameContact(id: AddressBookContactID, to name: AddressBookContactName) async throws
    func addEntries(_ entries: AddressBookContactDraftEntries, toContactWith id: AddressBookContactID) async throws
    func updateEntry(id: AddressBookAddressEntryID, inContactWith contactId: AddressBookContactID, to draft: AddressBookEntryDraft) async throws
    func deleteEntry(id: AddressBookAddressEntryID, fromContactWith contactId: AddressBookContactID) async throws
    func deleteContact(id: AddressBookContactID) async throws
}
