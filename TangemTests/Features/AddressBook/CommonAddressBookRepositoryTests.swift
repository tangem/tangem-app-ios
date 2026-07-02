//
//  CommonAddressBookRepositoryTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CryptoKit
import Testing
import TangemFoundation
@testable import Tangem

@Suite("CommonAddressBookRepository")
struct CommonAddressBookRepositoryTests {
    private let walletId = UserWalletId(value: Data(repeating: 0xA1, count: 32))
    private let walletPublicKeySeed = Data(repeating: 0xB2, count: 33)
    private let blobCodec = AddressBookBlobCodec()
    private let mapper = AddressBookNetworkMapper()

    private static let contactID = AddressBookContactID(rawValue: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!)
    private static let entryID = AddressBookAddressEntryID(rawValue: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!)

    private static let timestamp = Date(timeIntervalSince1970: 1_700_000_000)
    private static let serverUpdatedAt = Date(timeIntervalSince1970: 1_800_000_000)

    // MARK: - Load

    @Test
    func loadWithNoRemoteBookAndNoCachePublishesSyncedEmpty() async {
        let network = StubNetworkService()
        network.loadResult = .success(.notFound)
        let persistentStorage = SpyPersistentStorage()
        let eTagStorage = SpyETagStorage()
        let repository = makeRepository(network: network, persistentStorage: persistentStorage, eTagStorage: eTagStorage)

        await repository.load(silent: false)

        #expect(isSynced(currentSyncState(repository)))
        #expect(currentContacts(repository).isEmpty)
        #expect(network.lastLoadKnownETag == nil)
        #expect(persistentStorage.clearCallCount == 0)
    }

    @Test
    func loadNotModifiedKeepsCachedContactsAndSendsStoredETag() async throws {
        let contact = try makeContact()
        let network = StubNetworkService()
        network.loadResult = .success(.notModified)
        let persistentStorage = SpyPersistentStorage(stored: try makeStoredDTO(contacts: [contact]))
        let eTagStorage = SpyETagStorage(initialETags: [addressBookETagKey: "cached-etag"])
        let repository = makeRepository(network: network, persistentStorage: persistentStorage, eTagStorage: eTagStorage)

        await repository.load(silent: false)

        #expect(isSynced(currentSyncState(repository)))
        #expect(currentContacts(repository) == [contact])
        #expect(network.lastLoadKnownETag == "cached-etag")
        #expect(persistentStorage.clearCallCount == 0)
    }

    @Test
    func loadOfflineKeepsCacheAndReportsNetworkError() async throws {
        let contact = try makeContact()
        let network = StubNetworkService()
        network.loadResult = .failure(URLError(.notConnectedToInternet))
        let persistentStorage = SpyPersistentStorage(stored: try makeStoredDTO(contacts: [contact]))
        let eTagStorage = SpyETagStorage(initialETags: [addressBookETagKey: "cached-etag"])
        let repository = makeRepository(network: network, persistentStorage: persistentStorage, eTagStorage: eTagStorage)

        await repository.load(silent: false)

        #expect(isNetworkError(currentSyncState(repository)))
        #expect(currentContacts(repository) == [contact])
        #expect(persistentStorage.clearCallCount == 0)
        #expect(persistentStorage.stored != nil)
    }

    @Test
    func loadFetchedDecodesPersistsServerMetadataAndSyncs() async throws {
        let contact = try makeContact()
        let remote = RemoteAddressBook(
            etag: "srv-etag",
            envelope: try makeEnvelope(contacts: [contact], updatedAt: Self.serverUpdatedAt)
        )
        let network = StubNetworkService()
        network.loadResult = .success(.fetched(remote))
        let persistentStorage = SpyPersistentStorage()
        let eTagStorage = SpyETagStorage()
        let repository = makeRepository(network: network, persistentStorage: persistentStorage, eTagStorage: eTagStorage)

        await repository.load(silent: false)

        #expect(isSynced(currentSyncState(repository)))
        #expect(currentContacts(repository) == [contact])

        let persisted = try #require(persistentStorage.savedEnvelopes.last)
        let persistedDate = try #require(AddressBookBlobCodec.date(fromISO8601: persisted.updatedAt))
        #expect(persistedDate == Self.serverUpdatedAt)
        #expect(eTagStorage.savedETags == ["srv-etag"])
    }

    @Test
    func loadWithUnsupportedBlobVersionReportsUpdateRequiredAndKeepsCache() async throws {
        let cached = try makeContact()
        let remote = RemoteAddressBook(
            etag: "srv-etag",
            envelope: try makeEnvelope(contacts: [try makeContact(name: "Newer")], version: "9.9")
        )
        let network = StubNetworkService()
        network.loadResult = .success(.fetched(remote))
        let persistentStorage = SpyPersistentStorage(stored: try makeStoredDTO(contacts: [cached]))
        let eTagStorage = SpyETagStorage(initialETags: [addressBookETagKey: "cached-etag"])
        let repository = makeRepository(network: network, persistentStorage: persistentStorage, eTagStorage: eTagStorage)

        await repository.load(silent: false)

        #expect(isUpdateRequired(currentSyncState(repository)))
        #expect(currentContacts(repository) == [cached])
        #expect(persistentStorage.clearCallCount == 0)
    }

    @Test(.disabled("Corrupt-blob cache invalidation ships with [REDACTED_INFO]; on develop the repository intentionally falls back to the cached book"))
    func loadWithCorruptBlobInvalidatesCacheAndReportsDecodingError() async throws {
        let cached = try makeContact()
        let corrupt = AddressBookEnvelope(
            version: AddressBookBlobCodec.supportedVersion,
            walletId: walletId,
            updatedAt: Self.timestamp,
            sealedBox: AddressBookSealedBox(nonce: zeros(12), ciphertext: Data([0x00, 0x01, 0x02]), tag: zeros(16))
        )
        let network = StubNetworkService()
        network.loadResult = .success(.fetched(RemoteAddressBook(etag: "srv-etag", envelope: corrupt)))
        let persistentStorage = SpyPersistentStorage(stored: try makeStoredDTO(contacts: [cached]))
        let eTagStorage = SpyETagStorage(initialETags: [addressBookETagKey: "cached-etag"])
        let repository = makeRepository(network: network, persistentStorage: persistentStorage, eTagStorage: eTagStorage)

        await repository.load(silent: false)

        #expect(isDecodingError(currentSyncState(repository)))
        #expect(currentContacts(repository).isEmpty)
        #expect(persistentStorage.clearCallCount >= 1)
        #expect(persistentStorage.stored == nil)
        #expect(eTagStorage.clearedKeys.contains(addressBookETagKey))
    }

    // MARK: - Save

    @Test
    func saveIsRemoteFirstAndPersistsServerUpdatedAt() async throws {
        let contact = try makeContact()
        let network = StubNetworkService()
        network.loadResult = .success(.notFound)
        network.saveResult = .success(AddressBookSaveResult(etag: "save-etag", updatedAt: Self.serverUpdatedAt))
        let persistentStorage = SpyPersistentStorage()
        let eTagStorage = SpyETagStorage()
        let repository = makeRepository(network: network, persistentStorage: persistentStorage, eTagStorage: eTagStorage)

        await repository.load(silent: false)
        try await repository.save(contacts: [contact])

        #expect(network.saveCallCount == 1)

        let sent = try #require(network.savedEnvelopes.last)
        #expect(try blobCodec.decode(sent.sealedBox.ciphertext).contacts == [contact])

        let persisted = try #require(persistentStorage.savedEnvelopes.last)
        let persistedDate = try #require(AddressBookBlobCodec.date(fromISO8601: persisted.updatedAt))
        #expect(persistedDate == Self.serverUpdatedAt)
        #expect(eTagStorage.savedETags == ["save-etag"])

        #expect(isSynced(currentSyncState(repository)))
        #expect(currentContacts(repository) == [contact])
    }

    @Test
    func saveOnInconsistentStateReloadsSilentlyAndRethrows() async throws {
        let contact = try makeContact()
        let network = StubNetworkService()
        network.loadResult = .success(.notFound)
        network.saveResult = .failure(AddressBookNetworkServiceError.inconsistentState)
        let persistentStorage = SpyPersistentStorage()
        let eTagStorage = SpyETagStorage()
        let repository = makeRepository(network: network, persistentStorage: persistentStorage, eTagStorage: eTagStorage)

        await repository.load(silent: false)
        let loadsBeforeSave = network.loadCallCount

        var thrown: Error?
        do {
            try await repository.save(contacts: [contact])
        } catch {
            thrown = error
        }

        #expect(isInconsistentState(thrown))
        #expect(network.loadCallCount == loadsBeforeSave + 1)
        #expect(persistentStorage.savedEnvelopes.isEmpty)
        #expect(eTagStorage.savedETags.isEmpty)
    }

    @Test
    func savePersistFailureInvalidatesCacheButStillPublishesSynced() async throws {
        let contact = try makeContact()
        let network = StubNetworkService()
        network.loadResult = .success(.notFound)
        network.saveResult = .success(AddressBookSaveResult(etag: "save-etag", updatedAt: Self.serverUpdatedAt))
        let persistentStorage = SpyPersistentStorage()
        persistentStorage.saveError = TestError()
        let eTagStorage = SpyETagStorage()
        let repository = makeRepository(network: network, persistentStorage: persistentStorage, eTagStorage: eTagStorage)

        await repository.load(silent: false)
        try await repository.save(contacts: [contact])

        #expect(persistentStorage.clearCallCount >= 1)
        #expect(eTagStorage.savedETags.isEmpty)
        #expect(eTagStorage.clearedKeys.contains(addressBookETagKey))
        #expect(isSynced(currentSyncState(repository)))
        #expect(currentContacts(repository) == [contact])
    }

    @Test
    func saveOnUnsyncedBookThrowsBookUnavailableWithoutHittingNetwork() async throws {
        let contact = try makeContact()
        let network = StubNetworkService()
        let persistentStorage = SpyPersistentStorage()
        let eTagStorage = SpyETagStorage()
        let repository = makeRepository(network: network, persistentStorage: persistentStorage, eTagStorage: eTagStorage)

        await #expect(throws: AddressBookRepositoryError.self) {
            try await repository.save(contacts: [contact])
        }
        #expect(network.saveCallCount == 0)
    }

    // MARK: - Fixtures

    private func makeRepository(
        network: AddressBookNetworkService,
        persistentStorage: AddressBookPersistentStorage,
        eTagStorage: ETagStorage
    ) -> CommonAddressBookRepository {
        CommonAddressBookRepository(
            walletId: walletId,
            walletPublicKeySeed: walletPublicKeySeed,
            networkService: network,
            eTagStorage: eTagStorage,
            persistentStorage: persistentStorage,
            encryptionService: PassthroughEncryptionService(),
            keyProvider: StubKeyProvider(),
            blobCodec: blobCodec
        )
    }

    private var addressBookETagKey: String {
        makeETagStorageKey(for: .addressBook(walletId: walletId))
    }

    private func zeros(_ count: Int) -> Data { Data(repeating: 0, count: count) }

    private func makeContact(name value: String = "Alice", address: String = "0xabc", memo: String? = nil) throws -> AddressBookDecodedContact {
        AddressBookDecodedContact(
            id: Self.contactID,
            walletId: walletId.stringValue,
            name: try AddressBookContactNameValidator().validate(value),
            icon: "",
            iconColor: "MexicanPink",
            createdAt: Self.timestamp,
            updatedAt: Self.timestamp,
            addresses: [
                AddressBookDecodedAddressEntry(
                    id: Self.entryID,
                    address: address,
                    networkId: AddressBookNetworkID("ethereum"),
                    memo: memo,
                    signature: Data([0x01, 0x02, 0x03])
                ),
            ]
        )
    }

    private func makeEnvelope(
        contacts: [AddressBookDecodedContact],
        version: String = AddressBookBlobCodec.supportedVersion,
        updatedAt: Date = CommonAddressBookRepositoryTests.timestamp
    ) throws -> AddressBookEnvelope {
        let blob = try blobCodec.encode(AddressBookPlaintext(contacts: contacts))
        return AddressBookEnvelope(
            version: version,
            walletId: walletId,
            updatedAt: updatedAt,
            sealedBox: AddressBookSealedBox(nonce: zeros(12), ciphertext: blob, tag: zeros(16))
        )
    }

    private func makeStoredDTO(contacts: [AddressBookDecodedContact]) throws -> AddressBookDTO.Envelope {
        mapper.mapToDTO(try makeEnvelope(contacts: contacts))
    }

    // MARK: - State inspection

    private func currentContacts(_ repository: CommonAddressBookRepository) -> [AddressBookDecodedContact] {
        var value: [AddressBookDecodedContact] = []
        let cancellable = repository.contactsPublisher.sink { value = $0 }
        cancellable.cancel()
        return value
    }

    private func currentSyncState(_ repository: CommonAddressBookRepository) -> AddressBookSyncState? {
        var value: AddressBookSyncState?
        let cancellable = repository.syncStatePublisher.sink { value = $0 }
        cancellable.cancel()
        return value
    }

    private func isSynced(_ state: AddressBookSyncState?) -> Bool {
        if case .synced? = state { return true }
        return false
    }

    private func isNetworkError(_ state: AddressBookSyncState?) -> Bool {
        if case .failure(.networkError)? = state { return true }
        return false
    }

    private func isDecodingError(_ state: AddressBookSyncState?) -> Bool {
        if case .failure(.decodingError)? = state { return true }
        return false
    }

    private func isUpdateRequired(_ state: AddressBookSyncState?) -> Bool {
        if case .failure(.updateRequired)? = state { return true }
        return false
    }

    private func isInconsistentState(_ error: Error?) -> Bool {
        guard let error = error as? AddressBookNetworkServiceError else { return false }
        if case .inconsistentState = error { return true }
        return false
    }
}

// MARK: - Test doubles

private final class StubNetworkService: AddressBookNetworkService {
    var loadResult: Result<AddressBookFetchResult, Error> = .success(.notFound)
    var saveResult: Result<AddressBookSaveResult, Error> = .success(AddressBookSaveResult(etag: "default-etag", updatedAt: Date()))

    private(set) var loadCallCount = 0
    private(set) var saveCallCount = 0
    private(set) var lastLoadKnownETag: String?
    private(set) var lastSaveKnownETag: String?
    private(set) var savedEnvelopes: [AddressBookEnvelope] = []

    func loadAddressBook(walletId: UserWalletId, knownETag: String?) async throws -> AddressBookFetchResult {
        loadCallCount += 1
        lastLoadKnownETag = knownETag
        return try loadResult.get()
    }

    func saveAddressBook(_ envelope: AddressBookEnvelope, walletId: UserWalletId, knownETag: String?) async throws -> AddressBookSaveResult {
        saveCallCount += 1
        lastSaveKnownETag = knownETag
        savedEnvelopes.append(envelope)
        return try saveResult.get()
    }
}

private final class SpyPersistentStorage: AddressBookPersistentStorage {
    private(set) var stored: AddressBookDTO.Envelope?
    var saveError: Error?
    private(set) var savedEnvelopes: [AddressBookDTO.Envelope] = []
    private(set) var clearCallCount = 0

    init(stored: AddressBookDTO.Envelope? = nil) {
        self.stored = stored
    }

    func loadEnvelope(for walletId: UserWalletId) -> AddressBookDTO.Envelope? {
        stored
    }

    func saveEnvelope(_ envelope: AddressBookDTO.Envelope, for walletId: UserWalletId) throws {
        if let saveError {
            throw saveError
        }
        savedEnvelopes.append(envelope)
        stored = envelope
    }

    func clear(for walletId: UserWalletId) {
        clearCallCount += 1
        stored = nil
    }
}

private func makeETagStorageKey(for key: ETagStorageKey) -> String {
    switch key {
    case .accounts(let walletId): "CryptoAccountsETagStorage_\(walletId.stringValue)"
    case .addressBook(let walletId): "AddressBookETagStorage_\(walletId.stringValue)"
    }
}

private final class SpyETagStorage: ETagStorage {
    private(set) var etags: [String: String]
    private(set) var savedETags: [String] = []
    private(set) var clearedKeys: [String] = []

    init(initialETags: [String: String] = [:]) {
        etags = initialETags
    }

    func initialize() {}

    func loadETag(for key: ETagStorageKey) -> String? {
        etags[makeETagStorageKey(for: key)]
    }

    func saveETag(_ eTag: String, for key: ETagStorageKey) {
        savedETags.append(eTag)
        etags[makeETagStorageKey(for: key)] = eTag
    }

    func clearETag(for key: ETagStorageKey) {
        clearedKeys.append(makeETagStorageKey(for: key))
        etags[makeETagStorageKey(for: key)] = nil
    }
}

private struct PassthroughEncryptionService: AddressBookEncrypting {
    func seal(_ plaintext: Data, using key: SymmetricKey) throws -> AddressBookSealedBox {
        AddressBookSealedBox(nonce: Data(repeating: 0, count: 12), ciphertext: plaintext, tag: Data(repeating: 0, count: 16))
    }

    func open(_ sealedBox: AddressBookSealedBox, using key: SymmetricKey) throws -> Data {
        sealedBox.ciphertext
    }
}

private struct StubKeyProvider: AddressBookEncryptionKeyProviding {
    func encryptionKey(forWalletPublicKeySeed seed: Data) -> SymmetricKey {
        SymmetricKey(data: Data(repeating: 0x2A, count: 32))
    }
}

private struct TestError: Error {}
