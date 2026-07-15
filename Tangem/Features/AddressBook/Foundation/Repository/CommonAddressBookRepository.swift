//
//  CommonAddressBookRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CryptoKit
import TangemFoundation
import TangemMacro

final class CommonAddressBookRepository {
    private let walletId: UserWalletId
    private let networkService: AddressBookNetworkService
    private let eTagStorage: ETagStorage
    private let persistentStorage: AddressBookPersistentStorage
    private let encryptionService: AddressBookEncrypting
    private let encryptionKey: SymmetricKey
    private let blobCodec: AddressBookBlobCodec
    private let mapper = AddressBookNetworkMapper()

    private let syncStateSubject = CurrentValueSubject<SyncState, Never>(.syncing(cached: nil))

    init(
        walletId: UserWalletId,
        walletPublicKeySeed: Data,
        networkService: AddressBookNetworkService,
        eTagStorage: ETagStorage,
        persistentStorage: AddressBookPersistentStorage,
        encryptionService: AddressBookEncrypting,
        keyProvider: AddressBookEncryptionKeyProviding,
        blobCodec: AddressBookBlobCodec = AddressBookBlobCodec()
    ) {
        self.walletId = walletId
        self.networkService = networkService
        self.eTagStorage = eTagStorage
        self.persistentStorage = persistentStorage
        self.encryptionService = encryptionService
        self.blobCodec = blobCodec

        encryptionKey = keyProvider.encryptionKey(forWalletPublicKeySeed: walletPublicKeySeed)
    }
}

// MARK: - AddressBookRepository protocol conformance

extension CommonAddressBookRepository: AddressBookRepository {
    var contactsPublisher: AnyPublisher<[AddressBookDecodedContact], Never> {
        syncStateSubject.map(\.contacts).removeDuplicates().eraseToAnyPublisher()
    }

    var syncStatePublisher: AnyPublisher<AddressBookSyncState, Never> {
        syncStateSubject.map(\.publicState).eraseToAnyPublisher()
    }

    func ensureBookMutable() throws {
        // [REDACTED_TODO_COMMENT]
        // every mutation is blocked. Decide whether editing a cached-but-unsynced book should be allowed.
        guard syncStateSubject.value.isSynced else {
            throw AddressBookRepositoryError.bookUnavailable
        }
    }

    func load(silent: Bool) async {
        await performLoad(silent: silent)
    }

    func save(contacts: [AddressBookDecodedContact]) async throws {
        try await performSave(contacts: contacts)
    }
}

// MARK: - Load

private extension CommonAddressBookRepository {
    /// Trust state of the local cache, distinct from "no contacts": an unreadable blob must not masquerade
    /// as an empty book, which a later save would then persist over the still-intact on-disk blob.
    @CaseFlagable
    enum LocalAddressBook {
        case absent
        case readable([AddressBookDecodedContact])

        var contacts: [AddressBookDecodedContact]? {
            switch self {
            case .readable(let contacts): contacts
            case .absent: nil
            }
        }
    }

    func performLoad(silent: Bool) async {
        if !silent {
            publish(syncState: .syncing(cached: syncStateSubject.value.contacts))
        }
        let localBook = loadLocalAddressBook()

        do {
            let knownETag = localBook.isReadable ? eTagStorage.loadETag(for: .addressBook(walletId: walletId)) : nil

            let result = try await networkService.loadAddressBook(walletId: walletId, knownETag: knownETag)
            switch result {
            case .notModified, .notFound:
                await apply(local: localBook, syncState: .synced)
            case .fetched(let remote):
                await apply(remote: remote, local: localBook)
            }

        } catch AddressBookNetworkServiceError.malformedResponse(let error) {
            // A malformed/undecodable server response is an upstream fault, not a problem with the local blob
            // (loadLocalAddressBook validated that independently). Keep the cached copy rather than wiping the
            // user's offline data over a transient backend defect.
            ABLogger.error("Malformed sync response for wallet \(redactedWalletId)", error: error)
            await apply(local: localBook, syncState: .failure(.decodingError(error.localizedDescription)))
        } catch let error as AddressBookNetworkServiceError where error.isCancellationError {
            await apply(local: localBook, syncState: .failure(.networkError(error.localizedDescription)))
        } catch {
            ABLogger.error("Load failed for wallet \(redactedWalletId)", error: error)
            await apply(local: localBook, syncState: .failure(.networkError(error.localizedDescription)))
        }
    }

    func apply(local: LocalAddressBook, syncState: AddressBookSyncState) async {
        let cached = local.contacts
        switch syncState {
        case .syncing:
            publish(syncState: .syncing(cached: cached))
        case .synced:
            publish(syncState: .synced(cached ?? []))
        case .failure(let error):
            publish(syncState: .failure(error, cached: cached))
        }
    }

    func apply(remote: RemoteAddressBook, local: LocalAddressBook) async {
        do {
            let contacts = try decode(envelope: remote.envelope)
            save(envelope: remote.envelope, etag: remote.etag)
            publish(syncState: .synced(contacts))
        } catch AddressBookRepositoryError.unsupportedBlobVersion(let version) {
            ABLogger.warning("Unsupported blob version \(version) for wallet \(redactedWalletId)")
            publish(syncState: .failure(.updateRequired, cached: local.contacts))
        } catch {
            // The fetched remote blob failed to decrypt/decode; the separately-loaded local cache is still
            // good, so fall back to it instead of erasing it over a remote-side fault.
            ABLogger.error("Failed to decode fetched blob for wallet \(redactedWalletId)", error: error)
            publish(syncState: .failure(.decodingError(error.localizedDescription), cached: local.contacts))
        }
    }

    func decode(envelope: AddressBookEnvelope) throws -> [AddressBookDecodedContact] {
        guard envelope.version == AddressBookBlobCodec.supportedVersion else {
            throw AddressBookRepositoryError.unsupportedBlobVersion(envelope.version)
        }

        let plaintext = try encryptionService.open(envelope.sealedBox, using: encryptionKey)
        return try blobCodec.decode(plaintext).contacts
    }
}

// MARK: - Save

private extension CommonAddressBookRepository {
    func performSave(contacts: [AddressBookDecodedContact]) async throws {
        try ensureBookMutable()

        let knownETag = eTagStorage.loadETag(for: .addressBook(walletId: walletId))
        let plaintext = try blobCodec.encode(AddressBookPlaintext(contacts: contacts))
        let sealedBox = try encryptionService.seal(plaintext, using: encryptionKey)

        let envelope = AddressBookEnvelope(
            version: AddressBookBlobCodec.supportedVersion,
            walletId: walletId,
            updatedAt: Date(),
            sealedBox: sealedBox
        )

        do {
            let result = try await networkService.saveAddressBook(envelope, walletId: walletId, knownETag: knownETag)

            let savedEnvelope = AddressBookEnvelope(
                version: AddressBookBlobCodec.supportedVersion,
                walletId: walletId,
                updatedAt: result.updatedAt,
                sealedBox: sealedBox
            )
            save(envelope: savedEnvelope, etag: result.etag)

            publish(syncState: .synced(contacts))

        } catch AddressBookNetworkServiceError.inconsistentState {
            ABLogger.info("Save conflict for wallet \(redactedWalletId), refetching")
            await performLoad(silent: true)
            throw AddressBookNetworkServiceError.inconsistentState
        } catch AddressBookNetworkServiceError.malformedResponse(let error) {
            ABLogger.error("Malformed save response for wallet \(redactedWalletId)", error: error)
            await performLoad(silent: true)
            throw AddressBookNetworkServiceError.malformedResponse(error)
        } catch let error as AddressBookNetworkServiceError where error.isCancellationError {
            throw error
        } catch {
            ABLogger.error("Save failed for wallet \(redactedWalletId)", error: error)
            throw error
        }
    }
}

// MARK: - Local Storage

private extension CommonAddressBookRepository {
    func loadLocalAddressBook() -> LocalAddressBook {
        guard let dto = persistentStorage.loadEnvelope(for: walletId) else {
            return .absent
        }

        do {
            let envelope = try mapper.mapToEnvelope(dto)
            let contacts = try decode(envelope: envelope)
            return .readable(contacts)
        } catch {
            ABLogger.error("Corrupt local cache invalidated for wallet \(redactedWalletId)", error: error)
            invalidateCache()
            return .absent
        }
    }

    func save(envelope: AddressBookEnvelope, etag: String) {
        do {
            try persistentStorage.saveEnvelope(mapper.mapToDTO(envelope), for: walletId)
            eTagStorage.saveETag(etag, for: .addressBook(walletId: walletId))
        } catch {
            // The etag must never outlive its blob: a stored etag with no local copy makes the next load echo
            // that etag in the sync request, get back "not modified" (empty items), and have nothing to show.
            // So a failed blob write clears both.
            ABLogger.error("Failed to persist blob for wallet \(redactedWalletId)", error: error)
            invalidateCache()
        }
    }

    func invalidateCache() {
        persistentStorage.clear(for: walletId)
        eTagStorage.clearETag(for: .addressBook(walletId: walletId))
    }
}

// MARK: - Logging

private extension CommonAddressBookRepository {
    var redactedWalletId: String {
        "\(walletId.stringValue.prefix(4))...\(walletId.stringValue.suffix(4))"
    }
}

// MARK: - State publishing

private extension CommonAddressBookRepository {
    func publish(syncState: SyncState) {
        syncStateSubject.send(syncState)
    }
}

// MARK: - SyncState

private extension CommonAddressBookRepository {
    enum SyncState {
        case syncing(cached: [AddressBookDecodedContact]?)
        case synced([AddressBookDecodedContact])
        case failure(AddressBookSyncError, cached: [AddressBookDecodedContact]?)

        var contacts: [AddressBookDecodedContact] {
            switch self {
            case .syncing(let cached): cached ?? []
            case .synced(let contacts): contacts
            case .failure(_, let cached): cached ?? []
            }
        }

        var publicState: AddressBookSyncState {
            switch self {
            case .syncing: .syncing
            case .synced: .synced
            case .failure(let error, _): .failure(error)
            }
        }

        var isSynced: Bool {
            if case .synced = self { return true }
            return false
        }
    }
}
