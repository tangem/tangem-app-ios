//
//  CommonAddressBookManagerSyncOnSubscriptionTests.swift
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

@Suite("CommonAddressBookManager sync on subscription")
struct CommonAddressBookManagerSyncOnSubscriptionTests {
    private let walletId = UserWalletId(value: Data(repeating: 0xA1, count: 32))
    private let walletPublicKey = Data(repeating: 0xB2, count: 33)

    @Test
    func creatingTheManagerDoesNotLoad() async throws {
        let repository = SpyRepository()
        let manager = makeManager(repository: repository)

        try await Task.sleep(for: .milliseconds(50))

        withExtendedLifetime(manager) {
            #expect(repository.loadCalls.isEmpty)
        }
    }

    @Test
    func firstContactsSubscriberTriggersASilentLoad() async throws {
        let repository = SpyRepository()
        let manager = makeManager(repository: repository)

        let subscription = manager.contactsPublisher.sink { _ in }
        defer { subscription.cancel() }

        try await waitUntil { repository.loadCalls.isNotEmpty }

        #expect(repository.loadCalls == [true])
    }

    @Test
    func firstSyncStateSubscriberTriggersASilentLoad() async throws {
        let repository = SpyRepository()
        let manager = makeManager(repository: repository)

        let subscription = manager.syncStatePublisher.sink { _ in }
        defer { subscription.cancel() }

        try await waitUntil { repository.loadCalls.isNotEmpty }

        #expect(repository.loadCalls == [true])
    }

    @Test
    func subscribersOfOneGenerationShareASingleLoad() async throws {
        let repository = SpyRepository()
        let manager = makeManager(repository: repository)

        let first = manager.contactsPublisher.sink { _ in }
        let second = manager.contactsPublisher.sink { _ in }
        defer {
            first.cancel()
            second.cancel()
        }

        try await waitUntil { repository.loadCalls.isNotEmpty }
        // Give a second load the chance to show up before asserting it never does.
        try await Task.sleep(for: .milliseconds(50))

        #expect(repository.loadCalls.count == 1)
    }

    /// Separate generations, so a screen taking both asks twice; collapsing that into one request is the
    /// repository's single-flight, not this class's job.
    @Test
    func subscribingToBothPublishersAsksEachPublisherOnce() async throws {
        let repository = SpyRepository()
        let manager = makeManager(repository: repository)

        let contacts = manager.contactsPublisher.sink { _ in }
        let syncState = manager.syncStatePublisher.sink { _ in }
        defer {
            contacts.cancel()
            syncState.cancel()
        }

        try await waitUntil { repository.loadCalls.count == 2 }
        try await Task.sleep(for: .milliseconds(50))

        #expect(repository.loadCalls == [true, true])
    }

    @Test
    func newGenerationAfterEveryoneUnsubscribedLoadsAgain() async throws {
        let repository = SpyRepository()
        let manager = makeManager(repository: repository)

        let first = manager.contactsPublisher.sink { _ in }
        try await waitUntil { repository.loadCalls.count == 1 }
        first.cancel()

        let second = manager.contactsPublisher.sink { _ in }
        defer { second.cancel() }
        try await waitUntil { repository.loadCalls.count == 2 }

        #expect(repository.loadCalls == [true, true])
    }

    // MARK: - Mutations

    @Test
    func creatingAContactRefreshesTheRemoteStateFirst() async throws {
        let repository = SpyRepository()
        let manager = makeManager(repository: repository)

        _ = try await manager.createContact(
            name: try AddressBookContactNameValidator().validate("Alice"),
            appearance: AddressBookContactAppearance(rawColor: "MexicanPink"),
            entries: draftEntries()
        )

        #expect(repository.events == [.load(silent: true), .save])
    }

    @Test
    func deletingAContactRefreshesTheRemoteStateFirst() async throws {
        let contact = try decodedContact(name: "Alice")
        let repository = SpyRepository(initial: [contact])
        let manager = makeManager(repository: repository)

        try await manager.deleteContact(id: contact.id)

        #expect(repository.events == [.load(silent: true), .save])
    }

    @Test
    func subscriberStillReceivesTheCurrentValueOnSubscription() throws {
        let repository = SpyRepository(initial: [try decodedContact(name: "Alice")])
        let manager = makeManager(repository: repository)

        var received: [[AddressBookContact]] = []
        let subscription = manager.contactsPublisher.sink { received.append($0) }
        defer { subscription.cancel() }

        #expect(received.count == 1)
        #expect(received.first?.map(\.name.value) == ["Alice"])
    }

    // MARK: - Fixtures

    private func makeManager(repository: AddressBookRepository) -> CommonAddressBookManager {
        CommonAddressBookManager(
            walletId: walletId,
            walletPublicKey: walletPublicKey,
            repository: repository,
            signer: NoopSigner(),
            verifier: AcceptingVerifier(),
            supportedBlockchains: [.bitcoin(testnet: false)]
        )
    }

    private func draftEntries(address: String = "bc1qexample") -> AddressBookContactDraftEntries {
        AddressBookContactDraftEntries([
            AddressBookEntryDraft(address: address, blockchain: .bitcoin(testnet: false), memo: nil),
        ])!
    }

    private func decodedContact(name value: String) throws -> AddressBookDecodedContact {
        AddressBookDecodedContact(
            id: AddressBookContactID(),
            walletId: walletId.stringValue,
            name: try AddressBookContactNameValidator().validate(value),
            icon: "",
            iconColor: "MexicanPink",
            createdAt: Date(),
            updatedAt: Date(),
            addresses: [
                AddressBookDecodedAddressEntry(
                    id: AddressBookAddressEntryID(),
                    address: "bc1qexample",
                    networkId: AddressBookNetworkID("bitcoin"),
                    memo: nil,
                    signature: Data([0x01])
                ),
            ]
        )
    }

    /// Polls until `condition` holds — the load a subscription triggers runs in a detached task.
    private func waitUntil(_ condition: () -> Bool, sourceLocation: SourceLocation = #_sourceLocation) async throws {
        var attempts = 0
        while !condition(), attempts < 200 {
            attempts += 1
            try await Task.sleep(for: .milliseconds(5))
        }

        if !condition() {
            Issue.record("Timed out waiting for the expected state", sourceLocation: sourceLocation)
        }
    }
}

// MARK: - Test doubles

private final class SpyRepository: AddressBookRepository {
    enum Event: Equatable {
        case load(silent: Bool)
        case save
    }

    private let contactsSubject: CurrentValueSubject<[AddressBookDecodedContact], Never>
    private let syncStateSubject = CurrentValueSubject<AddressBookSyncState, Never>(.syncing)
    private let eventsState = OSAllocatedUnfairLock(initialState: [Event]())

    init(initial: [AddressBookDecodedContact] = []) {
        contactsSubject = .init(initial)
    }

    var events: [Event] { eventsState.withLock { $0 } }

    /// The `silent` flag of every `load` call, in order.
    var loadCalls: [Bool] {
        events.compactMap { event in
            guard case .load(let silent) = event else { return nil }
            return silent
        }
    }

    var contactsPublisher: AnyPublisher<[AddressBookDecodedContact], Never> { contactsSubject.eraseToAnyPublisher() }
    var syncStatePublisher: AnyPublisher<AddressBookSyncState, Never> { syncStateSubject.eraseToAnyPublisher() }

    func ensureBookMutable() throws {}

    func load(silent: Bool) async {
        eventsState.withLock { $0.append(.load(silent: silent)) }
    }

    func save(contacts: [AddressBookDecodedContact]) async throws {
        eventsState.withLock { $0.append(.save) }
        contactsSubject.send(contacts)
    }
}

private final class NoopSigner: AddressBookSigning {
    func sign(digests: [Data], walletPublicKey: Data) async throws -> [Data] {
        digests.map { _ in Data([0x01]) }
    }
}

private struct AcceptingVerifier: AddressBookSignatureVerifying {
    func isSignatureValid(_ signature: Data, of digest: Data, walletPublicKey: Data) -> Bool { true }
}
