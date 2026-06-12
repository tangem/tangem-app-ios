//
//  AddressBookManagerTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
import TangemSdk
import BlockchainSdk
import TangemFoundation
@testable import Tangem

@Suite("AddressBookManager")
struct AddressBookManagerTests {
    @Test("create then verify-on-load surfaces a valid contact")
    func createAndVerify() async throws {
        let env = try TestEnvironment()

        try await env.manager.createContact(
            name: ContactName(validating: "Binance"),
            entries: [AddressBookEntryDraft(address: "0xabc", networkId: AddressBookNetworkID("ethereum"), memo: nil)]
        )

        let contacts = await env.currentContacts()
        #expect(contacts.count == 1)

        guard case .valid(let contact) = contacts.first else {
            Issue.record("Expected a valid contact")
            return
        }

        #expect(contact.name.value == "Binance")
        #expect(contact.entries.count == 1)
        #expect(contact.entries.head.address == "0xabc")
    }

    @Test("duplicate name (case-insensitive) is rejected")
    func duplicateName() async throws {
        let env = try TestEnvironment()
        try await env.manager.createContact(name: ContactName(validating: "Binance"), entries: [env.draftA])

        await #expect(throws: AddressBookValidationError.self) {
            try await env.manager.createContact(name: ContactName(validating: "binance"), entries: [env.draftB])
        }
    }

    @Test("duplicate (address, network) within one contact is rejected")
    func duplicatePairWithinContact() async throws {
        let env = try TestEnvironment()

        await #expect(throws: AddressBookValidationError.self) {
            try await env.manager.createContact(name: ContactName(validating: "Dup"), entries: [env.draftA, env.draftA])
        }
    }

    @Test("rename re-signs entries and keeps them valid")
    func renameKeepsEntriesValid() async throws {
        let env = try TestEnvironment()
        try await env.manager.createContact(name: ContactName(validating: "Old"), entries: [env.draftA])

        guard case .valid(let created) = await env.currentContacts().first else {
            Issue.record("Expected a valid contact")
            return
        }

        try await env.manager.renameContact(id: created.id, to: ContactName(validating: "New"))

        guard case .valid(let renamed) = await env.currentContacts().first else {
            Issue.record("Expected a valid contact after rename")
            return
        }

        #expect(renamed.name.value == "New")
        #expect(renamed.entries.count == 1)
    }

    @Test("deleting the last entry removes the whole contact")
    func deleteLastEntry() async throws {
        let env = try TestEnvironment()
        try await env.manager.createContact(name: ContactName(validating: "Solo"), entries: [env.draftA])

        guard case .valid(let contact) = await env.currentContacts().first else {
            Issue.record("Expected a valid contact")
            return
        }

        try await env.manager.deleteEntry(id: contact.entries.head.id, fromContactWith: contact.id)

        #expect(await env.currentContacts().isEmpty)
    }

    @Test("entries signed by a different key surface as all-invalid")
    func mismatchedSignatureKey() async throws {
        let env = try TestEnvironment(useMismatchedVerifierKey: true)

        try await env.manager.createContact(name: ContactName(validating: "Tampered"), entries: [env.draftA])

        let contacts = await env.currentContacts()
        #expect(contacts.count == 1)

        if case .allEntriesInvalid = contacts.first {
            // expected
        } else {
            Issue.record("Expected an all-invalid contact")
        }
    }
}

// MARK: - Test environment & doubles

private struct TestEnvironment {
    let manager: CommonAddressBookManager
    let draftA = AddressBookEntryDraft(address: "0xabc", networkId: AddressBookNetworkID("ethereum"), memo: nil)
    let draftB = AddressBookEntryDraft(address: "0xdef", networkId: AddressBookNetworkID("polygon"), memo: nil)

    init(useMismatchedVerifierKey: Bool = false) throws {
        let utils = Secp256k1Utils()
        let signingKeyPair = try utils.generateKeyPair()
        let verifyPublicKey = useMismatchedVerifierKey ? try utils.generateKeyPair().publicKey : signingKeyPair.publicKey
        let walletId = UserWalletId(value: Data(repeating: 1, count: 32))

        let repository = CommonAddressBookRepository(
            walletId: walletId,
            walletPublicKeySeed: signingKeyPair.publicKey,
            networkService: StubAddressBookNetworkService(),
            eTagStorage: InMemoryAddressBookETagStorage(),
            persistentStorage: InMemoryAddressBookPersistentStorage(),
            encryptionService: CommonAddressBookEncryptionService(),
            keyProvider: CommonAddressBookEncryptionKeyProvider()
        )

        manager = CommonAddressBookManager(
            walletId: walletId,
            walletPublicKey: verifyPublicKey,
            repository: repository,
            signer: TestKeyPairSigner(privateKey: signingKeyPair.privateKey),
            verifier: TestKeyPairVerifier()
        )
    }

    func currentContacts() async -> [ContactReadModel] {
        for await value in manager.contactsPublisher.values {
            return value
        }

        return []
    }
}

/// Signs each digest with a known secp256k1 key. `Secp256k1Utils.sign` applies SHA-256 internally, so
/// it is paired with `TestKeyPairVerifier`, which verifies against the same re-hashed value.
private struct TestKeyPairSigner: AddressBookSigning {
    let privateKey: Data

    func sign(digests: [Data], walletPublicKey: Wallet.PublicKey) async throws -> [Data] {
        let utils = Secp256k1Utils()
        return try digests.map { try utils.sign($0, with: privateKey) }
    }
}

private struct TestKeyPairVerifier: AddressBookSignatureVerifying {
    func isSignatureValid(_ signature: Data, of digest: Data, walletPublicKey: Data) -> Bool {
        (try? Secp256k1Signature(with: signature).verify(with: walletPublicKey, hash: digest.getSHA256())) ?? false
    }
}

private final class InMemoryAddressBookETagStorage: AddressBookETagStorage {
    private let storage = OSAllocatedUnfairLock(initialState: [String: String]())

    func initialize() {}

    func loadETag(for userWalletId: UserWalletId) -> String? {
        storage.withLock { $0[userWalletId.stringValue] }
    }

    func saveETag(_ eTag: String, for userWalletId: UserWalletId) {
        storage.withLock { $0[userWalletId.stringValue] = eTag }
    }

    func clearETag(for userWalletId: UserWalletId) {
        storage.withLock { $0[userWalletId.stringValue] = nil }
    }
}

private final class InMemoryAddressBookPersistentStorage: AddressBookPersistentStorage {
    private let storage = OSAllocatedUnfairLock(initialState: [String: AddressBookEnvelopeDTO]())

    func loadEnvelope(for walletId: UserWalletId) -> AddressBookEnvelopeDTO? {
        storage.withLock { $0[walletId.stringValue] }
    }

    func saveEnvelope(_ envelope: AddressBookEnvelopeDTO, for walletId: UserWalletId) throws {
        storage.withLock { $0[walletId.stringValue] = envelope }
    }

    func clear(for walletId: UserWalletId) {
        storage.withLock { $0[walletId.stringValue] = nil }
    }
}
