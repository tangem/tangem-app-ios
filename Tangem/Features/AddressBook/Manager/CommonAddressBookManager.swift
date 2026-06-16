//
//  CommonAddressBookManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class CommonAddressBookManager {
    private let walletId: UserWalletId
    private let walletPublicKey: Data
    private let repository: AddressBookRepository
    private let signer: AddressBookSigning
    private let verifier: AddressBookSignatureVerifying
    private let normalizeAddress: (String, AddressBookNetworkID) -> String

    private let decodedContacts = OSAllocatedUnfairLock(initialState: [AddressBookDecodedContact]())
    private let contactsSubject = CurrentValueSubject<[AddressBookContact], Never>([])
    private var bag = Set<AnyCancellable>()

    init(
        walletId: UserWalletId,
        walletPublicKey: Data,
        repository: AddressBookRepository,
        signer: AddressBookSigning,
        verifier: AddressBookSignatureVerifying,
        normalizeAddress: @escaping (String, AddressBookNetworkID) -> String = { address, _ in address }
    ) {
        self.walletId = walletId
        self.walletPublicKey = walletPublicKey
        self.repository = repository
        self.signer = signer
        self.verifier = verifier
        self.normalizeAddress = normalizeAddress

        bind()
        Task { await load() }
    }

    private func bind() {
        repository.contactsPublisher
            .sink { [weak self] decoded in
                self?.handle(decoded: decoded)
            }
            .store(in: &bag)
    }

    private func handle(decoded: [AddressBookDecodedContact]) {
        decodedContacts.withLock { $0 = decoded }
        contactsSubject.send(decoded.compactMap(verify(_:)))
    }

    private var snapshot: [AddressBookDecodedContact] {
        decodedContacts.withLock { $0 }
    }

    // MARK: - Verification

    private func verify(_ contact: AddressBookDecodedContact) -> AddressBookContact? {
        let builder = AddressBookVerifiedAddressEntryBuilder()

        let verified = contact.addresses.compactMap { entry in
            builder.make(
                verifying: entry,
                contactId: contact.id,
                contactName: contact.name,
                walletPublicKey: walletPublicKey,
                verifier: verifier
            )
        }

        // A contact whose entries all fail verification is not shown at all (spec 2.1.3).
        guard let entries = NonEmptyArray(verified) else {
            return nil
        }

        return AddressBookContact(id: contact.id, walletId: walletId, name: contact.name, entries: entries)
    }

    // MARK: - Signing

    private struct EntryToSign {
        let id: AddressBookAddressEntryID
        let address: String
        let networkId: AddressBookNetworkID
        let memo: String?
    }

    private func sign(_ entries: [EntryToSign], contactId: AddressBookContactID, name: AddressBookContactName) async throws -> [AddressBookDecodedAddressEntry] {
        let payloads = entries.map {
            AddressBookSignedTuplePayload(address: $0.address, networkId: $0.networkId, memo: $0.memo, contactId: contactId, name: name)
        }

        let signatures = try await signer.sign(digests: payloads.map(\.digest), walletPublicKey: walletPublicKey)

        return zip(entries, signatures).map { entry, signature in
            AddressBookDecodedAddressEntry(id: entry.id, address: entry.address, networkId: entry.networkId, memo: entry.memo, signature: signature)
        }
    }

    // MARK: - Validation helpers

    private func dedupKey(_ address: String, _ networkId: AddressBookNetworkID) -> String {
        "\(normalizeAddress(address, networkId))|\(networkId.rawValue)"
    }

    private func ensureNameUnique(_ name: AddressBookContactName, excluding contactId: AddressBookContactID?, in contacts: [AddressBookDecodedContact]) throws {
        let duplicate = contacts.contains { contact in
            contact.id != contactId && contact.name.value.caseInsensitiveCompare(name.value) == .orderedSame
        }

        if duplicate {
            throw AddressBookValidationError.nameNotUnique
        }
    }

    /// `(address, networkId)` must be unique *within a contact*. Repetition across different contacts
    /// in the same wallet is allowed (per the create API rule).
    private func ensureNoDuplicatePairs(existing: [(String, AddressBookNetworkID)], adding drafts: [AddressBookEntryDraft]) throws {
        var keys = Set(existing.map { dedupKey($0.0, $0.1) })

        for draft in drafts {
            guard keys.insert(dedupKey(draft.address, draft.networkId)).inserted else {
                throw AddressBookValidationError.duplicateAddressNetworkPair
            }
        }
    }

    private func ensureAddressesNonEmpty(_ drafts: [AddressBookEntryDraft]) throws {
        let hasEmptyAddress = drafts.contains { $0.address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        if hasEmptyAddress {
            throw AddressBookValidationError.addressEmpty
        }
    }

    private func contact(with id: AddressBookContactID, in contacts: [AddressBookDecodedContact]) throws -> AddressBookDecodedContact {
        guard let contact = contacts.first(where: { $0.id == id }) else {
            throw AddressBookManagerError.contactNotFound
        }

        return contact
    }

    private func replacing(contactWith id: AddressBookContactID, by contact: AddressBookDecodedContact, in contacts: [AddressBookDecodedContact]) -> [AddressBookDecodedContact] {
        contacts.map { $0.id == id ? contact : $0 }
    }

    /// Rebuilds a contact preserving its identity, walletId and createdAt while bumping updatedAt.
    private func touched(_ contact: AddressBookDecodedContact, name: AddressBookContactName? = nil, addresses: [AddressBookDecodedAddressEntry]? = nil) -> AddressBookDecodedContact {
        AddressBookDecodedContact(
            id: contact.id,
            walletId: contact.walletId,
            name: name ?? contact.name,
            createdAt: contact.createdAt,
            updatedAt: Date(),
            addresses: addresses ?? contact.addresses
        )
    }
}

// MARK: - AddressBookManager protocol conformance

extension CommonAddressBookManager: AddressBookManager {
    var contactsPublisher: AnyPublisher<[AddressBookContact], Never> {
        contactsSubject.eraseToAnyPublisher()
    }

    var syncStatePublisher: AnyPublisher<AddressBookSyncState, Never> {
        repository.syncStatePublisher
    }

    func load() async {
        await repository.load()
    }

    func createContact(name: AddressBookContactName, entries drafts: [AddressBookEntryDraft]) async throws {
        guard !drafts.isEmpty else {
            throw AddressBookValidationError.noEntries
        }

        guard drafts.count <= AddressBookContact.maxEntries else {
            throw AddressBookValidationError.tooManyEntries
        }

        try ensureAddressesNonEmpty(drafts)

        let contacts = snapshot
        try ensureNameUnique(name, excluding: nil, in: contacts)
        try ensureNoDuplicatePairs(existing: [], adding: drafts)

        let contactId = AddressBookContactID()
        let toSign = drafts.map { EntryToSign(id: $0.id, address: $0.address, networkId: $0.networkId, memo: $0.memo) }
        let entries = try await sign(toSign, contactId: contactId, name: name)
        let now = Date()
        let contact = AddressBookDecodedContact(
            id: contactId,
            walletId: walletId.stringValue,
            name: name,
            createdAt: now,
            updatedAt: now,
            addresses: entries
        )

        try await repository.save(contacts: contacts + [contact])
    }

    func renameContact(id: AddressBookContactID, to name: AddressBookContactName) async throws {
        let contacts = snapshot
        let contact = try contact(with: id, in: contacts)
        try ensureNameUnique(name, excluding: id, in: contacts)

        // `name` is part of the signed tuple, so every entry of the contact is re-signed.
        let toSign = contact.addresses.map { EntryToSign(id: $0.id, address: $0.address, networkId: $0.networkId, memo: $0.memo) }
        let entries = try await sign(toSign, contactId: id, name: name)
        let updated = touched(contact, name: name, addresses: entries)

        try await repository.save(contacts: replacing(contactWith: id, by: updated, in: contacts))
    }

    func addEntries(_ drafts: [AddressBookEntryDraft], toContactWith id: AddressBookContactID) async throws {
        let contacts = snapshot
        let contact = try contact(with: id, in: contacts)

        guard contact.addresses.count + drafts.count <= AddressBookContact.maxEntries else {
            throw AddressBookValidationError.tooManyEntries
        }

        try ensureAddressesNonEmpty(drafts)
        try ensureNoDuplicatePairs(existing: contact.addresses.map { ($0.address, $0.networkId) }, adding: drafts)

        let toSign = drafts.map { EntryToSign(id: $0.id, address: $0.address, networkId: $0.networkId, memo: $0.memo) }
        let signed = try await sign(toSign, contactId: id, name: contact.name)
        let updated = touched(contact, addresses: contact.addresses + signed)

        try await repository.save(contacts: replacing(contactWith: id, by: updated, in: contacts))
    }

    func updateEntry(id entryId: AddressBookAddressEntryID, inContactWith contactId: AddressBookContactID, to draft: AddressBookEntryDraft) async throws {
        let contacts = snapshot
        let contact = try contact(with: contactId, in: contacts)

        guard contact.addresses.contains(where: { $0.id == entryId }) else {
            throw AddressBookManagerError.entryNotFound
        }

        try ensureAddressesNonEmpty([draft])

        let others = contact.addresses.filter { $0.id != entryId }
        try ensureNoDuplicatePairs(existing: others.map { ($0.address, $0.networkId) }, adding: [draft])

        let signed = try await sign(
            [EntryToSign(id: entryId, address: draft.address, networkId: draft.networkId, memo: draft.memo)],
            contactId: contactId,
            name: contact.name
        )

        let addresses = contact.addresses.map { $0.id == entryId ? signed[0] : $0 }
        let updated = touched(contact, addresses: addresses)

        try await repository.save(contacts: replacing(contactWith: contactId, by: updated, in: contacts))
    }

    func deleteEntry(id entryId: AddressBookAddressEntryID, fromContactWith contactId: AddressBookContactID) async throws {
        let contacts = snapshot
        let contact = try contact(with: contactId, in: contacts)
        let remaining = contact.addresses.filter { $0.id != entryId }

        // Deleting the last entry deletes the whole contact.
        guard !remaining.isEmpty else {
            try await repository.save(contacts: contacts.filter { $0.id != contactId })
            return
        }

        let updated = touched(contact, addresses: remaining)
        try await repository.save(contacts: replacing(contactWith: contactId, by: updated, in: contacts))
    }

    func deleteContact(id: AddressBookContactID) async throws {
        try await repository.save(contacts: snapshot.filter { $0.id != id })
    }
}
