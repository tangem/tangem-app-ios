//
//  CommonAddressBookManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemFoundation

@MainActor
final class CommonAddressBookManager {
    private let walletId: UserWalletId
    private let walletPublicKey: Data
    private let repository: AddressBookRepository
    private let signer: AddressBookSigning
    private let verifier: AddressBookSignatureVerifying
    private let normalizeAddress: (String, AddressBookNetworkID) -> String

    private var decodedContacts: [DecodedContact] = []
    private let contactsSubject = CurrentValueSubject<[ContactReadModel], Never>([])
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
    }

    private func bind() {
        repository.contactsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] decoded in
                self?.handle(decoded: decoded)
            }
            .store(in: &bag)
    }

    private func handle(decoded: [DecodedContact]) {
        decodedContacts = decoded
        contactsSubject.send(decoded.map(verify(_:)))
    }

    // MARK: - Verification

    private func verify(_ contact: DecodedContact) -> ContactReadModel {
        let verified = contact.addresses.compactMap { entry in
            VerifiedAddressEntry.make(
                verifying: entry,
                contactId: contact.id,
                contactName: contact.name,
                walletPublicKey: walletPublicKey,
                verifier: verifier
            )
        }

        guard let entries = NonEmptyArray(verified) else {
            return .allEntriesInvalid(id: contact.id, name: contact.name, walletId: walletId)
        }

        return .valid(Contact(id: contact.id, walletId: walletId, name: contact.name, entries: entries))
    }

    // MARK: - Signing

    private struct EntryToSign {
        let id: AddressEntryID
        let address: String
        let networkId: AddressBookNetworkID
        let memo: String?
    }

    private var signingPublicKey: Wallet.PublicKey {
        Wallet.PublicKey(seedKey: walletPublicKey, derivationType: nil)
    }

    private func sign(_ entries: [EntryToSign], contactId: ContactID, name: ContactName) async throws -> [DecodedAddressEntry] {
        let payloads = entries.map {
            SignedTuplePayload(address: $0.address, networkId: $0.networkId, memo: $0.memo, contactId: contactId, name: name)
        }

        let signatures = try await signer.sign(digests: payloads.map(\.digest), walletPublicKey: signingPublicKey)

        return zip(entries, signatures).map { entry, signature in
            DecodedAddressEntry(id: entry.id, address: entry.address, networkId: entry.networkId, memo: entry.memo, signature: signature)
        }
    }

    // MARK: - Validation helpers

    private func dedupKey(_ address: String, _ networkId: AddressBookNetworkID) -> String {
        "\(normalizeAddress(address, networkId))|\(networkId.rawValue)"
    }

    private func ensureNameUnique(_ name: ContactName, excluding contactId: ContactID?) throws {
        let duplicate = decodedContacts.contains { contact in
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

    private func replacing(contactWith id: ContactID, by contact: DecodedContact) -> [DecodedContact] {
        decodedContacts.map { $0.id == id ? contact : $0 }
    }

    private func contact(with id: ContactID) throws -> DecodedContact {
        guard let contact = decodedContacts.first(where: { $0.id == id }) else {
            throw AddressBookManagerError.contactNotFound
        }

        return contact
    }
}

// MARK: - AddressBookManager protocol conformance

extension CommonAddressBookManager: AddressBookManager {
    var contactsPublisher: AnyPublisher<[ContactReadModel], Never> {
        contactsSubject.eraseToAnyPublisher()
    }

    var syncStatePublisher: AnyPublisher<AddressBookSyncState, Never> {
        repository.syncStatePublisher
    }

    func load() async {
        await repository.load()
    }

    func createContact(name: ContactName, entries drafts: [AddressBookEntryDraft]) async throws {
        guard !drafts.isEmpty else {
            throw AddressBookValidationError.noEntries
        }

        guard drafts.count <= Contact.maxEntries else {
            throw AddressBookValidationError.tooManyEntries
        }

        try ensureNameUnique(name, excluding: nil)
        try ensureNoDuplicatePairs(existing: [], adding: drafts)

        let contactId = ContactID()
        let toSign = drafts.map { EntryToSign(id: AddressEntryID(), address: $0.address, networkId: $0.networkId, memo: $0.memo) }
        let entries = try await sign(toSign, contactId: contactId, name: name)
        let contact = DecodedContact(id: contactId, name: name, addresses: entries)

        try await repository.save(contacts: decodedContacts + [contact])
    }

    func renameContact(id: ContactID, to name: ContactName) async throws {
        let contact = try contact(with: id)
        try ensureNameUnique(name, excluding: id)

        // `name` is part of the signed tuple, so every entry of the contact is re-signed.
        let toSign = contact.addresses.map { EntryToSign(id: $0.id, address: $0.address, networkId: $0.networkId, memo: $0.memo) }
        let entries = try await sign(toSign, contactId: id, name: name)
        let updated = DecodedContact(id: id, name: name, addresses: entries)

        try await repository.save(contacts: replacing(contactWith: id, by: updated))
    }

    func addEntries(_ drafts: [AddressBookEntryDraft], toContactWith id: ContactID) async throws {
        let contact = try contact(with: id)

        guard contact.addresses.count + drafts.count <= Contact.maxEntries else {
            throw AddressBookValidationError.tooManyEntries
        }

        try ensureNoDuplicatePairs(existing: contact.addresses.map { ($0.address, $0.networkId) }, adding: drafts)

        let toSign = drafts.map { EntryToSign(id: AddressEntryID(), address: $0.address, networkId: $0.networkId, memo: $0.memo) }
        let signed = try await sign(toSign, contactId: id, name: contact.name)
        let updated = DecodedContact(id: id, name: contact.name, addresses: contact.addresses + signed)

        try await repository.save(contacts: replacing(contactWith: id, by: updated))
    }

    func updateEntry(id entryId: AddressEntryID, inContactWith contactId: ContactID, to draft: AddressBookEntryDraft) async throws {
        let contact = try contact(with: contactId)

        guard contact.addresses.contains(where: { $0.id == entryId }) else {
            throw AddressBookManagerError.entryNotFound
        }

        let others = contact.addresses.filter { $0.id != entryId }
        try ensureNoDuplicatePairs(existing: others.map { ($0.address, $0.networkId) }, adding: [draft])

        let signed = try await sign(
            [EntryToSign(id: entryId, address: draft.address, networkId: draft.networkId, memo: draft.memo)],
            contactId: contactId,
            name: contact.name
        )

        let addresses = contact.addresses.map { $0.id == entryId ? signed[0] : $0 }
        let updated = DecodedContact(id: contactId, name: contact.name, addresses: addresses)

        try await repository.save(contacts: replacing(contactWith: contactId, by: updated))
    }

    func deleteEntry(id entryId: AddressEntryID, fromContactWith contactId: ContactID) async throws {
        let contact = try contact(with: contactId)
        let remaining = contact.addresses.filter { $0.id != entryId }

        // Deleting the last entry deletes the whole contact.
        guard !remaining.isEmpty else {
            try await repository.save(contacts: decodedContacts.filter { $0.id != contactId })
            return
        }

        let updated = DecodedContact(id: contactId, name: contact.name, addresses: remaining)
        try await repository.save(contacts: replacing(contactWith: contactId, by: updated))
    }

    func deleteContact(id: ContactID) async throws {
        try await repository.save(contacts: decodedContacts.filter { $0.id != id })
    }
}
