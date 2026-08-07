//
//  CommonAddressBookManagerReSignTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
import BlockchainSdk
import TangemFoundation
@testable import Tangem

/// `reSignContact` is the target side of a cross-wallet move (PR #4730): it re-signs a contact's entries
/// under this wallet's key while keeping the contact's `id`, instead of minting a new contact.
@Suite("CommonAddressBookManager.reSignContact")
struct CommonAddressBookManagerReSignTests {
    private let walletId = UserWalletId(value: Data(repeating: 0xA1, count: 32))
    private let walletPublicKey = Data(repeating: 0xB2, count: 33)
    private let blockchain: BSDKBlockchain = .bitcoin(testnet: false)

    @Test
    func reSignPersistsContactUnderTheGivenId() async throws {
        let repository = FakeRepository()
        let manager = makeManager(repository: repository, signer: RecordingSigner())

        let movedId = AddressBookContactID()
        try await manager.reSignContact(id: movedId, name: name("Alice"), appearance: AddressBookContactAppearance(rawColor: "MexicanPink"), entries: draftEntries())

        #expect(repository.savedContacts.count == 1)
        #expect(repository.savedContacts.first?.id == movedId)
        #expect(repository.savedContacts.first?.walletId == walletId.stringValue)
    }

    @Test
    func createMintsAFreshIdWhileReSignKeepsTheGivenOne() async throws {
        let repository = FakeRepository()
        let manager = makeManager(repository: repository, signer: RecordingSigner())

        let createdId = try await manager.createContact(name: name("Bob"), appearance: AddressBookContactAppearance(rawColor: "MexicanPink"), entries: draftEntries(address: "bc1qbob"))
        #expect(repository.savedContacts.last?.id == createdId)

        let movedId = AddressBookContactID()
        #expect(movedId != createdId)

        try await manager.reSignContact(id: movedId, name: name("Carol"), appearance: AddressBookContactAppearance(rawColor: "MexicanPink"), entries: draftEntries(address: "bc1qcarol"))
        #expect(repository.savedContacts.last?.id == movedId)
    }

    @Test
    func reSignSignsEntriesWithThisWalletsKey() async throws {
        let repository = FakeRepository()
        let signer = RecordingSigner()
        let manager = makeManager(repository: repository, signer: signer)

        try await manager.reSignContact(id: AddressBookContactID(), name: name("Dave"), appearance: AddressBookContactAppearance(rawColor: "MexicanPink"), entries: draftEntries(address: "bc1qdave"))

        #expect(signer.signedWalletPublicKeys == [walletPublicKey])

        let saved = try #require(repository.savedContacts.first)
        let entry = try #require(saved.addresses.first)
        #expect(saved.addresses.count == 1)
        #expect(entry.signature == RecordingSigner.signature)
        #expect(entry.networkId == AddressBookNetworkID(blockchain.networkId))
        #expect(entry.address == "bc1qdave")
    }

    @Test
    func reSignAppendsToTheExistingBook() async throws {
        let existing = try decodedContact(name: "Existing", address: "bc1qexisting")
        let repository = FakeRepository(initial: [existing])
        let manager = makeManager(repository: repository, signer: RecordingSigner())

        let movedId = AddressBookContactID()
        try await manager.reSignContact(id: movedId, name: name("Newcomer"), appearance: AddressBookContactAppearance(rawColor: "MexicanPink"), entries: draftEntries())

        #expect(repository.savedContacts.map(\.id) == [existing.id, movedId])
    }

    @Test
    func reSignRejectsANameAlreadyUsedInTheTargetBook() async throws {
        let existing = try decodedContact(name: "Duplicate", address: "bc1qexisting")
        let repository = FakeRepository(initial: [existing])
        let manager = makeManager(repository: repository, signer: RecordingSigner())
        let duplicateName = try name("Duplicate")
        let entries = draftEntries()

        await #expect(throws: AddressBookValidationError.self) {
            try await manager.reSignContact(id: AddressBookContactID(), name: duplicateName, appearance: AddressBookContactAppearance(rawColor: "MexicanPink"), entries: entries)
        }
        #expect(repository.savedContacts.isEmpty)
    }

    // MARK: - Fixtures

    private func makeManager(
        repository: AddressBookRepository,
        signer: AddressBookSigning,
        verifier: AddressBookSignatureVerifying = AcceptingVerifier()
    ) -> CommonAddressBookManager {
        CommonAddressBookManager(
            walletId: walletId,
            walletPublicKey: walletPublicKey,
            repository: repository,
            signer: signer,
            verifier: verifier,
            supportedBlockchains: [blockchain]
        )
    }

    private func draftEntries(address: String = "bc1qdefault") -> AddressBookContactDraftEntries {
        AddressBookContactDraftEntries([
            AddressBookEntryDraft(address: address, blockchain: blockchain, memo: nil),
        ])!
    }

    private func name(_ value: String) throws -> AddressBookContactName {
        try AddressBookContactNameValidator().validate(value)
    }

    private func decodedContact(name value: String, address: String) throws -> AddressBookDecodedContact {
        AddressBookDecodedContact(
            id: AddressBookContactID(),
            walletId: walletId.stringValue,
            name: try name(value),
            icon: "",
            iconColor: "MexicanPink",
            createdAt: Date(),
            updatedAt: Date(),
            addresses: [
                AddressBookDecodedAddressEntry(
                    id: AddressBookAddressEntryID(),
                    address: address,
                    networkId: AddressBookNetworkID(blockchain.networkId),
                    memo: nil,
                    signature: Data([0x01])
                ),
            ]
        )
    }
}

// MARK: - Test doubles

private final class FakeRepository: AddressBookRepository {
    private(set) var savedContacts: [AddressBookDecodedContact] = []

    private let contactsSubject: CurrentValueSubject<[AddressBookDecodedContact], Never>
    private let syncStateSubject = CurrentValueSubject<AddressBookSyncState, Never>(.synced)

    init(initial: [AddressBookDecodedContact] = []) {
        contactsSubject = .init(initial)
    }

    var contactsPublisher: AnyPublisher<[AddressBookDecodedContact], Never> { contactsSubject.eraseToAnyPublisher() }
    var syncStatePublisher: AnyPublisher<AddressBookSyncState, Never> { syncStateSubject.eraseToAnyPublisher() }

    func ensureBookMutable() throws {
        guard case .synced = syncStateSubject.value else {
            throw AddressBookRepositoryError.bookUnavailable
        }
    }

    func load(silent: Bool) async {}

    func save(contacts: [AddressBookDecodedContact]) async throws {
        savedContacts = contacts
        contactsSubject.send(contacts)
    }
}

private final class RecordingSigner: AddressBookSigning {
    static let signature = Data([0xDE, 0xAD, 0xBE, 0xEF])

    private(set) var signedWalletPublicKeys: [Data] = []

    func sign(digests: [Data], walletPublicKey: Data) async throws -> [Data] {
        signedWalletPublicKeys.append(walletPublicKey)
        return digests.map { _ in Self.signature }
    }
}

private struct AcceptingVerifier: AddressBookSignatureVerifying {
    func isSignatureValid(_ signature: Data, of digest: Data, walletPublicKey: Data) -> Bool { true }
}
