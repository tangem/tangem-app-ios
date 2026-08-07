//
//  AddressBookManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

/// Per-wallet facade over the address book. Verifies signatures on load, enforces the uniqueness
/// invariants, and signs (or re-signs) entries on every mutation that changes the signed tuple.
/// Deletes and reads never require a signature.
///
/// Uniqueness rules: within the wallet, both the contact `name` (case-insensitive) and the
/// `(address, networkId)` pair are unique — the same pair may not repeat across contacts of the wallet.
protocol AddressBookManager: AnyObject {
    /// Verified contacts ready for display and the Send Flow. Invalid-signature entries are dropped; a
    /// contact whose every entry is invalid is omitted. Combine with `syncStatePublisher` to build the UI
    /// load state.
    var contactsPublisher: AnyPublisher<[AddressBookContact], Never> { get }
    /// The current verified contacts, read synchronously — the latest value of `contactsPublisher`.
    var contacts: [AddressBookContact] { get }
    var syncStatePublisher: AnyPublisher<AddressBookSyncState, Never> { get }

    func configure(with userWalletModel: UserWalletModel)

    func load(silent: Bool) async

    @discardableResult
    func createContact(name: AddressBookContactName, appearance: AddressBookContactAppearance, entries: AddressBookContactDraftEntries) async throws -> AddressBookContactID

    /// Re-signs an existing contact into this book under the wallet's key, keeping its `id` — used to move a
    /// contact in from another wallet's book without minting a new one; the caller removes the original from
    /// the source book. Fails if the name collides with another contact already in this book.
    func reSignContact(id: AddressBookContactID, name: AddressBookContactName, appearance: AddressBookContactAppearance, entries: AddressBookContactDraftEntries) async throws

    /// Atomically replaces a contact's name, icon color and full entry set in a single signed save. The
    /// new state is exactly `entries`; entries unchanged since load keep their signature, a rename re-signs
    /// all of them (the name is part of the signed tuple), and dropped entries simply disappear.
    func updateContact(id: AddressBookContactID, name: AddressBookContactName, appearance: AddressBookContactAppearance, entries: AddressBookContactDraftEntries) async throws

    func deleteContact(id: AddressBookContactID) async throws
}

extension AddressBookManager {
    func load() async {
        await load(silent: false)
    }
}
