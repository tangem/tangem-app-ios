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
        guard let entries = AddressBookContactEntries(verified) else {
            return nil
        }

        return AddressBookContact(id: contact.id, walletId: walletId, name: contact.name, entries: entries)
    }

    // MARK: - Signing

    private func sign(_ drafts: [AddressBookEntryDraft], contactId: AddressBookContactID, name: AddressBookContactName) async throws -> [AddressBookDecodedAddressEntry] {
        let payloads = drafts.map {
            AddressBookSignedTuplePayload(address: $0.address, networkId: $0.networkId, memo: $0.memo, contactId: contactId, name: name)
        }

        let signatures = try await signer.sign(digests: payloads.map(\.digest), walletPublicKey: walletPublicKey)

        return zip(drafts, signatures).map { draft, signature in
            AddressBookDecodedAddressEntry(id: draft.id, address: draft.address, networkId: draft.networkId, memo: draft.memo, signature: signature)
        }
    }

    /// The signed entries that replace a contact's address list. A rename re-signs every entry — the name
    /// is part of the signed tuple; otherwise an entry identical to the one loaded keeps its signature and
    /// only added or edited entries are signed, so a delete-only edit needs no card tap (spec 2.1.1 / 3.4).
    private func signedEntries(for drafts: [AddressBookEntryDraft], replacing contact: AddressBookDecodedContact, name: AddressBookContactName) async throws -> [AddressBookDecodedAddressEntry] {
        if name != contact.name {
            return try await sign(drafts, contactId: contact.id, name: name)
        }

        let existingById = Dictionary(contact.addresses.map { ($0.id, $0) }, uniquingKeysWith: { current, _ in current })

        func reusable(_ draft: AddressBookEntryDraft) -> AddressBookDecodedAddressEntry? {
            guard let previous = existingById[draft.id],
                  previous.address == draft.address, previous.networkId == draft.networkId, previous.memo == draft.memo else {
                return nil
            }
            return previous
        }

        let toSign = drafts.filter { reusable($0) == nil }
        let signed = toSign.isEmpty ? [] : try await sign(toSign, contactId: contact.id, name: name)
        let signedById = Dictionary(signed.map { ($0.id, $0) }, uniquingKeysWith: { current, _ in current })

        return drafts.compactMap { signedById[$0.id] ?? reusable($0) }
    }

    // MARK: - Validation helpers

    private func dedupKey(_ address: String, _ networkId: AddressBookNetworkID) -> String {
        "\(normalizeAddress(address, networkId))|\(networkId.rawValue)"
    }

    private func ensureNameUnique(_ name: AddressBookContactName, excluding contactId: AddressBookContactID?) throws {
        // Only visible (verified) contacts constrain the name: a fully-unverifiable contact is hidden
        // from the user (spec 2.1.3), so it must not block a name whose owner the user cannot see or delete.
        let duplicate = contactsSubject.value.contains { contact in
            contact.id != contactId && contact.name.value.caseInsensitiveCompare(name.value) == .orderedSame
        }

        if duplicate {
            throw AddressBookValidationError.nameNotUnique
        }
    }

    /// `(address, networkId)` must be unique *within a contact*. The same pair may repeat across
    /// different contacts of the same wallet (per the create API rule).
    private func ensureNoDuplicatePairs(_ drafts: [AddressBookEntryDraft]) throws {
        var keys = Set<String>()

        for draft in drafts {
            guard keys.insert(dedupKey(draft.address, draft.networkId)).inserted else {
                throw AddressBookValidationError.duplicateAddressNetworkPair
            }
        }
    }

    private func ensureAddressesNonEmpty(_ drafts: [AddressBookEntryDraft]) throws {
        let hasEmptyAddress = drafts.contains { $0.address.trimmed().isEmpty }

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
    private func touched(_ contact: AddressBookDecodedContact, name: AddressBookContactName? = nil, addresses: [AddressBookDecodedAddressEntry]) -> AddressBookDecodedContact {
        AddressBookDecodedContact(
            id: contact.id,
            walletId: contact.walletId,
            name: name ?? contact.name,
            createdAt: contact.createdAt,
            updatedAt: Date(),
            addresses: addresses
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

    func createContact(name: AddressBookContactName, entries: AddressBookContactDraftEntries) async throws {
        let drafts = entries.raw

        guard entries.addressCount <= AddressBookContactDraftEntries.maxAddressCount else {
            throw AddressBookValidationError.tooManyAddresses
        }

        try ensureAddressesNonEmpty(drafts)

        let contacts = snapshot
        try ensureNameUnique(name, excluding: nil)
        try ensureNoDuplicatePairs(drafts)

        let contactId = AddressBookContactID()
        let entries = try await sign(drafts, contactId: contactId, name: name)
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

    func updateContact(id: AddressBookContactID, name: AddressBookContactName, entries: AddressBookContactDraftEntries) async throws {
        guard entries.addressCount <= AddressBookContactDraftEntries.maxAddressCount else {
            throw AddressBookValidationError.tooManyAddresses
        }

        let drafts = entries.raw
        try ensureAddressesNonEmpty(drafts)

        let contacts = snapshot
        let contact = try contact(with: id, in: contacts)
        try ensureNameUnique(name, excluding: id)
        // The new state is exactly `drafts`, so the pairs must be unique among themselves.
        try ensureNoDuplicatePairs(drafts)

        let addresses = try await signedEntries(for: drafts, replacing: contact, name: name)
        let updated = touched(contact, name: name, addresses: addresses)

        try await repository.save(contacts: replacing(contactWith: id, by: updated, in: contacts))
    }

    func deleteContact(id: AddressBookContactID) async throws {
        try await repository.save(contacts: snapshot.filter { $0.id != id })
    }
}
