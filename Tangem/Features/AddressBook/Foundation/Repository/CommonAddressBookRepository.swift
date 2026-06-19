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

final class CommonAddressBookRepository {
    private let walletId: UserWalletId
    private let networkService: AddressBookNetworkService
    private let eTagStorage: AddressBookETagStorage
    private let persistentStorage: AddressBookPersistentStorage
    private let encryptionService: AddressBookEncrypting
    private let encryptionKey: SymmetricKey
    private let blobCodec: AddressBookBlobCodec
    private let mapper = AddressBookNetworkMapper()

    private let contactsSubject = CurrentValueSubject<[AddressBookDecodedContact], Never>([])
    private let syncStateSubject = CurrentValueSubject<AddressBookSyncState, Never>(.synced)

    init(
        walletId: UserWalletId,
        walletPublicKeySeed: Data,
        networkService: AddressBookNetworkService,
        eTagStorage: AddressBookETagStorage,
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

    private func decode(_ remote: RemoteAddressBook) throws -> [AddressBookDecodedContact] {
        guard remote.envelope.version == AddressBookBlobCodec.supportedVersion else {
            throw AddressBookRepositoryError.unsupportedBlobVersion(remote.envelope.version)
        }

        let plaintext = try encryptionService.open(remote.envelope.sealedBox, using: encryptionKey)
        return try blobCodec.decode(plaintext).contacts
    }

    private func loadFromCache() {
        guard let dto = persistentStorage.loadEnvelope(for: walletId) else {
            contactsSubject.send([])
            return
        }

        do {
            let envelope = try mapper.mapToEnvelope(dto)
            let plaintext = try encryptionService.open(envelope.sealedBox, using: encryptionKey)
            contactsSubject.send(try blobCodec.decode(plaintext).contacts)
        } catch {
            contactsSubject.send([])
        }
    }

    private func invalidateCache() {
        persistentStorage.clear(for: walletId)
        eTagStorage.clearETag(for: walletId)
    }
}

// MARK: - AddressBookRepository protocol conformance

extension CommonAddressBookRepository: AddressBookRepository {
    var contactsPublisher: AnyPublisher<[AddressBookDecodedContact], Never> {
        contactsSubject.eraseToAnyPublisher()
    }

    var syncStatePublisher: AnyPublisher<AddressBookSyncState, Never> {
        syncStateSubject.eraseToAnyPublisher()
    }

    func load() async {
        syncStateSubject.send(.syncing)

        let knownETag = eTagStorage.loadETag(for: walletId)
        let result: AddressBookFetchResult

        do {
            result = try await networkService.loadAddressBook(walletId: walletId, knownETag: knownETag)
        } catch {
            // No connectivity: fall back to the local encrypted cache (read-only).
            loadFromCache()
            syncStateSubject.send(.offline)
            return
        }

        switch result {
        case .notModified:
            loadFromCache()
            syncStateSubject.send(.synced)
        case .notFound:
            // No book on the server yet — e.g. the first sync of a wallet that only has a local cache.
            // Serve the cache so an existing book isn't lost; the next save uploads it. An empty cache
            // yields no contacts, the correct "no book yet" result for a fresh wallet.
            loadFromCache()
            syncStateSubject.send(.synced)
        case .fetched(let remote):
            do {
                let contacts = try decode(remote)
                contactsSubject.send(contacts)

                // Cache the fetched envelope and advance the ETag only if the write succeeds, so a write
                // failure refetches next launch instead of serving a stale cache. The decoded contacts
                // are already published, so a cache miss never hides valid data.
                do {
                    try persistentStorage.saveEnvelope(mapper.mapToDTO(remote.envelope), for: walletId)
                    eTagStorage.saveETag(remote.etag, for: walletId)
                } catch {
                    invalidateCache()
                }

                syncStateSubject.send(.synced)
            } catch AddressBookRepositoryError.unsupportedBlobVersion {
                syncStateSubject.send(.failed)
            } catch {
                // Auth-tag mismatch or a corrupt payload: drop the stale cache and etag so the next
                // launch refetches the book unconditionally.
                invalidateCache()
                syncStateSubject.send(.failed)
            }
        }
    }

    func save(contacts: [AddressBookDecodedContact]) async throws {
        do {
            try await performSave(contacts: contacts, conflictRetriesLeft: Constants.conflictRetryLimit)
            syncStateSubject.send(.synced)
        } catch {
            // Single owner of the terminal sync state for a save: any failure (network, encryption,
            // persistence, or an exhausted conflict retry) surfaces as `.failed`, mirroring `load()`.
            syncStateSubject.send(.failed)
            throw error
        }
    }
}

// MARK: - Save

private extension CommonAddressBookRepository {
    func performSave(contacts: [AddressBookDecodedContact], conflictRetriesLeft: Int) async throws {
        let plaintext = try blobCodec.encode(AddressBookPlaintext(contacts: contacts))
        let sealedBox = try encryptionService.seal(plaintext, using: encryptionKey)

        let envelope = AddressBookEnvelope(
            version: AddressBookBlobCodec.supportedVersion,
            walletId: walletId,
            updatedAt: Date(),
            sealedBox: sealedBox
        )

        let knownETag = eTagStorage.loadETag(for: walletId)

        do {
            let result = try await networkService.saveAddressBook(envelope, walletId: walletId, knownETag: knownETag)

            // Mirror the accepted write locally and advance the etag only after the backend confirms it,
            // so the on-device cache and etag never get ahead of the server.
            try persistentStorage.saveEnvelope(mapper.mapToDTO(envelope), for: walletId)
            eTagStorage.saveETag(result.etag, for: walletId)
            contactsSubject.send(contacts)
        } catch AddressBookNetworkServiceError.inconsistentState {
            guard conflictRetriesLeft > 0 else {
                throw AddressBookNetworkServiceError.noRetriesLeft
            }

            // The server holds a newer revision. Refresh the local etag from it, then replay the desired
            // contacts — the client's intended state wins (this is a full-book replace, not a field merge).
            try await refreshETag()
            try await performSave(contacts: contacts, conflictRetriesLeft: conflictRetriesLeft - 1)
        }
    }

    func refreshETag() async throws {
        switch try await networkService.loadAddressBook(walletId: walletId, knownETag: nil) {
        case .fetched(let remote):
            try? persistentStorage.saveEnvelope(mapper.mapToDTO(remote.envelope), for: walletId)
            eTagStorage.saveETag(remote.etag, for: walletId)
        case .notFound:
            // The book was deleted server-side; drop the stale etag so the replay recreates it.
            eTagStorage.clearETag(for: walletId)
        case .notModified:
            break
        }
    }
}

private extension CommonAddressBookRepository {
    enum Constants {
        static let conflictRetryLimit = 1
    }
}
