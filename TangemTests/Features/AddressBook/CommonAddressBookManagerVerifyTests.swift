//
//  CommonAddressBookManagerVerifyTests.swift
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

@Suite("CommonAddressBookManager.verify")
struct CommonAddressBookManagerVerifyTests {
    private let walletId = UserWalletId(value: Data(repeating: 0xA1, count: 32))
    private let walletPublicKey = Data(repeating: 0xB2, count: 33)
    private let blockchain: BSDKBlockchain = .bitcoin(testnet: false)

    @Test
    func omitsContactWhenAllEntriesFailVerification() throws {
        let repository = FakeRepository(initial: [try decodedContact(name: "Forged", address: "bc1qforged")])
        let manager = makeManager(repository: repository, verifier: RejectingVerifier())

        #expect(manager.contacts.isEmpty)
    }

    @Test
    func showsContactWhenSignatureValid() throws {
        let contact = try decodedContact(name: "Alice", address: "bc1qalice")
        let repository = FakeRepository(initial: [contact])
        let manager = makeManager(repository: repository, verifier: AcceptingVerifier())

        #expect(manager.contacts.count == 1)
        #expect(manager.contacts.first?.id == contact.id)
    }

    @Test
    func keepsOnlyEntriesThatVerify() throws {
        let contact = try decodedContact(name: "Mixed", addresses: ["bc1qgood", "bc1qbad"])
        let repository = FakeRepository(initial: [contact])
        let manager = makeManager(repository: repository, verifier: FirstEntryOnlyVerifier())

        let shown = try #require(manager.contacts.first)
        #expect(shown.entries.raw.count == 1)
    }

    // MARK: - Fixtures

    private func makeManager(
        repository: AddressBookRepository,
        verifier: AddressBookSignatureVerifying
    ) -> CommonAddressBookManager {
        CommonAddressBookManager(
            walletId: walletId,
            walletPublicKey: walletPublicKey,
            repository: repository,
            signer: NoopSigner(),
            verifier: verifier,
            supportedBlockchains: [blockchain]
        )
    }

    private func name(_ value: String) throws -> AddressBookContactName {
        try AddressBookContactNameValidator().validate(value)
    }

    private func decodedContact(name value: String, address: String) throws -> AddressBookDecodedContact {
        try decodedContact(name: value, addresses: [address])
    }

    private func decodedContact(name value: String, addresses: [String]) throws -> AddressBookDecodedContact {
        AddressBookDecodedContact(
            id: AddressBookContactID(),
            walletId: walletId.stringValue,
            name: try name(value),
            icon: "",
            iconColor: "MexicanPink",
            createdAt: Date(),
            updatedAt: Date(),
            addresses: addresses.map { address in
                AddressBookDecodedAddressEntry(
                    id: AddressBookAddressEntryID(),
                    address: address,
                    networkId: AddressBookNetworkID(blockchain.networkId),
                    memo: nil,
                    signature: Data([0x01])
                )
            }
        )
    }
}

// MARK: - Test doubles

private final class FakeRepository: AddressBookRepository {
    private let contactsSubject: CurrentValueSubject<[AddressBookDecodedContact], Never>
    private let syncStateSubject = CurrentValueSubject<AddressBookSyncState, Never>(.synced)

    init(initial: [AddressBookDecodedContact] = []) {
        contactsSubject = .init(initial)
    }

    var contactsPublisher: AnyPublisher<[AddressBookDecodedContact], Never> { contactsSubject.eraseToAnyPublisher() }
    var syncStatePublisher: AnyPublisher<AddressBookSyncState, Never> { syncStateSubject.eraseToAnyPublisher() }

    func ensureBookMutable() throws {}
    func load(silent: Bool) async {}
    func save(contacts: [AddressBookDecodedContact]) async throws {
        contactsSubject.send(contacts)
    }
}

private final class NoopSigner: AddressBookSigning {
    func sign(digests: [Data], walletPublicKey: Data) async throws -> [Data] { [] }
}

private struct AcceptingVerifier: AddressBookSignatureVerifying {
    func isSignatureValid(_ signature: Data, of digest: Data, walletPublicKey: Data) -> Bool { true }
}

private struct RejectingVerifier: AddressBookSignatureVerifying {
    func isSignatureValid(_ signature: Data, of digest: Data, walletPublicKey: Data) -> Bool { false }
}

private final class FirstEntryOnlyVerifier: AddressBookSignatureVerifying {
    private var callCount = 0

    func isSignatureValid(_ signature: Data, of digest: Data, walletPublicKey: Data) -> Bool {
        defer { callCount += 1 }
        return callCount == 0
    }
}
