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
        loadFromCache()
        syncStateSubject.send(.synced)
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
