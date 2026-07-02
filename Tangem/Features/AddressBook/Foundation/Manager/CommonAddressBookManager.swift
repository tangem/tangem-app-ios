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
import BlockchainSdk

final class CommonAddressBookManager {
    private let walletId: UserWalletId
    private let walletPublicKey: Data
    private let repository: AddressBookRepository
    private let signer: AddressBookSigning
    private let verifier: AddressBookSignatureVerifying
    private let supportedBlockchains: Set<BSDKBlockchain>

    private let decodedContacts = OSAllocatedUnfairLock(initialState: [AddressBookDecodedContact]())
    private let contactsSubject = CurrentValueSubject<[AddressBookContact], Never>([])
    private var bag = Set<AnyCancellable>()

    init(
        walletId: UserWalletId,
        walletPublicKey: Data,
        repository: AddressBookRepository,
        signer: AddressBookSigning,
        verifier: AddressBookSignatureVerifying,
        supportedBlockchains: Set<BSDKBlockchain>
    ) {
        self.walletId = walletId
        self.walletPublicKey = walletPublicKey
        self.repository = repository
        self.signer = signer
        self.verifier = verifier
        self.supportedBlockchains = supportedBlockchains

        bind()
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
        let builder = AddressBookVerifiedAddressEntryBuilder(supportedBlockchains: supportedBlockchains)

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

        return AddressBookContact(
            id: contact.id,
            walletId: walletId,
            name: contact.name,
            appearance: AddressBookContactAppearance(rawColor: contact.iconColor),
            entries: entries
        )
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

        let existingById = contact.addresses.keyedFirst(by: \.id)

        func reusable(_ draft: AddressBookEntryDraft) -> AddressBookDecodedAddressEntry? {
            guard let previous = existingById[draft.id],
                  previous.address == draft.address, previous.networkId == draft.networkId, previous.memo == draft.memo else {
                return nil
            }
            return previous
        }

        let toSign = drafts.filter { reusable($0) == nil }
        let signed = toSign.isEmpty ? [] : try await sign(toSign, contactId: contact.id, name: name)
        let signedById = signed.keyedFirst(by: \.id)

        return drafts.compactMap { signedById[$0.id] ?? reusable($0) }
    }

    // MARK: - Validation helpers

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

    /// Rebuilds a contact preserving its identity, walletId, icon and createdAt while bumping updatedAt.
    private func touched(_ contact: AddressBookDecodedContact, name: AddressBookContactName? = nil, appearance: AddressBookContactAppearance? = nil, addresses: [AddressBookDecodedAddressEntry]) -> AddressBookDecodedContact {
        AddressBookDecodedContact(
            id: contact.id,
            walletId: contact.walletId,
            name: name ?? contact.name,
            icon: contact.icon,
            iconColor: appearance?.rawColor ?? contact.iconColor,
            createdAt: contact.createdAt,
            updatedAt: Date(),
            addresses: addresses
        )
    }

    @discardableResult
    private func insert(id: AddressBookContactID, name: AddressBookContactName, appearance: AddressBookContactAppearance, entries: AddressBookContactDraftEntries) async throws -> AddressBookContactID {
        try repository.ensureBookMutable()

        let drafts = entries.raw

        try ensureAddressesNonEmpty(drafts)
        try AddressBookContactDraftEntries.validate(adding: drafts, to: [])
        try ensureNameUnique(name, excluding: nil)

        let signed = try await sign(drafts, contactId: id, name: name)
        let now = Date()
        let contact = AddressBookDecodedContact(
            id: id,
            walletId: walletId.stringValue,
            name: name,
            icon: "",
            iconColor: appearance.rawColor,
            createdAt: now,
            updatedAt: now,
            addresses: signed
        )

        // Re-read the snapshot after signing so a change that landed during the card tap is not
        // clobbered by a stale pre-await copy.
        try await repository.save(contacts: snapshot + [contact])

        return id
    }
}

// MARK: - AddressBookManager protocol conformance

extension CommonAddressBookManager: AddressBookManager {
    var contactsPublisher: AnyPublisher<[AddressBookContact], Never> {
        contactsSubject.eraseToAnyPublisher()
    }

    var contacts: [AddressBookContact] {
        contactsSubject.value
    }

    var syncStatePublisher: AnyPublisher<AddressBookSyncState, Never> {
        repository.syncStatePublisher
    }

    func load() async {
        await repository.load(silent: false)
    }

    func createContact(name: AddressBookContactName, appearance: AddressBookContactAppearance, entries: AddressBookContactDraftEntries) async throws -> AddressBookContactID {
        try await insert(id: AddressBookContactID(), name: name, appearance: appearance, entries: entries)
    }

    func reSignContact(id: AddressBookContactID, name: AddressBookContactName, appearance: AddressBookContactAppearance, entries: AddressBookContactDraftEntries) async throws {
        try await insert(id: id, name: name, appearance: appearance, entries: entries)
    }

    func updateContact(id: AddressBookContactID, name: AddressBookContactName, appearance: AddressBookContactAppearance, entries: AddressBookContactDraftEntries) async throws {
        // Fail fast before the signing card tap; `repository.save` re-checks this authoritatively.
        try repository.ensureBookMutable()

        let drafts = entries.raw

        try ensureAddressesNonEmpty(drafts)
        // The new state is exactly `drafts`: cap + (address, networkId) uniqueness among themselves.
        try AddressBookContactDraftEntries.validate(adding: drafts, to: [])

        let contact = try contact(with: id, in: snapshot)
        try ensureNameUnique(name, excluding: id)

        let addresses = try await signedEntries(for: drafts, replacing: contact, name: name)
        let updated = touched(contact, name: name, appearance: appearance, addresses: addresses)

        // Re-read the snapshot after signing so a change that landed during the card tap is not
        // clobbered by a stale pre-await copy.
        try await repository.save(contacts: replacing(contactWith: id, by: updated, in: snapshot))
    }

    func deleteContact(id: AddressBookContactID) async throws {
        // No signing here, so no need to pre-check; `repository.save` enforces the synced gate.
        try await repository.save(contacts: snapshot.filter { $0.id != id })
    }
}
