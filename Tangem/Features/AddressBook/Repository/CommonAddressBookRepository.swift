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

    private let contactsSubject = CurrentValueSubject<[DecodedContact], Never>([])
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

    private func decode(_ remote: RemoteAddressBook) throws -> [DecodedContact] {
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
    var contactsPublisher: AnyPublisher<[DecodedContact], Never> {
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
            contactsSubject.send([])
            syncStateSubject.send(.synced)
        case .fetched(let remote):
            do {
                let contacts = try decode(remote)
                try? persistentStorage.saveEnvelope(mapper.mapToDTO(remote.envelope), for: walletId)
                eTagStorage.saveETag(remote.etag, for: walletId)
                contactsSubject.send(contacts)
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

    func save(contacts: [DecodedContact]) async throws {
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

        eTagStorage.saveETag(result.etag, for: walletId)
        try? persistentStorage.saveEnvelope(mapper.mapToDTO(envelope), for: walletId)
        contactsSubject.send(contacts)
        syncStateSubject.send(.synced)
    }
}
