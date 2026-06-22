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

/// Local-only address book repository: it decrypts/encrypts the blob and persists it in the local
/// encrypted cache. Backend synchronization (network + ETag) is layered on in the API integration.
final class CommonAddressBookRepository {
    private let walletId: UserWalletId
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
        persistentStorage: AddressBookPersistentStorage,
        encryptionService: AddressBookEncrypting,
        keyProvider: AddressBookEncryptionKeyProviding,
        blobCodec: AddressBookBlobCodec = AddressBookBlobCodec()
    ) {
        self.walletId = walletId
        self.persistentStorage = persistentStorage
        self.encryptionService = encryptionService
        self.blobCodec = blobCodec
        encryptionKey = keyProvider.encryptionKey(forWalletPublicKeySeed: walletPublicKeySeed)
    }

    /// Returns `false` when a cached blob is present but cannot be decoded, so `load()` can surface
    /// `.failed` instead of an empty-but-healthy book. It deliberately does not reset `contactsSubject`
    /// on failure: an undecryptable blob must not masquerade as "no contacts", which a later `save`
    /// would then persist over the still-intact-on-disk blob.
    private func loadFromCache() -> Bool {
        guard let dto = persistentStorage.loadEnvelope(for: walletId) else {
            contactsSubject.send([])
            return true
        }

        do {
            let envelope = try mapper.mapToEnvelope(dto)
            let plaintext = try encryptionService.open(envelope.sealedBox, using: encryptionKey)
            contactsSubject.send(try blobCodec.decode(plaintext).contacts)
            return true
        } catch {
            AppLogger.error("Address book: failed to decode the cached blob", error: error)
            return false
        }
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
        let didLoad = loadFromCache()
        syncStateSubject.send(didLoad ? .synced : .failed)
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

        try persistentStorage.saveEnvelope(mapper.mapToDTO(envelope), for: walletId)
        contactsSubject.send(contacts)
        syncStateSubject.send(.synced)
    }
}
