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
            // The stub backend is in-memory and empty after a relaunch, so the local encrypted cache
            // is the source of truth until the real backend (T4) lands. An empty cache yields no
            // contacts, which is the correct "no book yet" result for a fresh wallet.
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
                // Auth-tag mismatch or a corrupt payload: drop the stale cache. A subsequent
                // unconditional refetch is handled by the real network service (T4).
                invalidateCache()
                syncStateSubject.send(.failed)
            }
        }
    }

    func save(contacts: [AddressBookDecodedContact]) async throws {
        let plaintext = try blobCodec.encode(AddressBookPlaintext(contacts: contacts))
        let sealedBox = try encryptionService.seal(plaintext, using: encryptionKey)

        let envelope = AddressBookEnvelope(
            version: AddressBookBlobCodec.supportedVersion,
            walletId: walletId,
            updatedAt: Date(),
            sealedBox: sealedBox
        )

        let knownETag = eTagStorage.loadETag(for: walletId)
        let result = try await networkService.saveAddressBook(envelope, walletId: walletId, knownETag: knownETag)

        // The local cache is the durable store until the real backend (T4) lands, so a write failure
        // must surface rather than be silently swallowed.
        try persistentStorage.saveEnvelope(mapper.mapToDTO(envelope), for: walletId)
        eTagStorage.saveETag(result.etag, for: walletId)
        contactsSubject.send(contacts)
        syncStateSubject.send(.synced)
    }
}
