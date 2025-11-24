//
//  KeysRepository.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

protocol KeysRepository: AnyObject, KeysProvider {
    func update(derivations: DerivationResult)
    func update(keys: WalletKeys)
}

protocol KeysProvider {
    var keys: [KeyInfo] { get }
    var keysPublisher: AnyPublisher<[KeyInfo], Never> { get }
}

class CommonKeysRepository {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    private let userWalletDataStorage = UserWalletDataStorage()

    private var _keys: CurrentValueSubject<WalletKeys, Never>
    private let userWalletId: UserWalletId
    private let encryptionKey: UserWalletEncryptionKey

    init(
        userWalletId: UserWalletId,
        encryptionKey: UserWalletEncryptionKey,
        keys: WalletKeys
    ) {
        self.userWalletId = userWalletId
        self.encryptionKey = encryptionKey
        _keys = .init(keys)
    }

    private func saveSensitiveData(sensitiveInfo: StoredUserWallet.SensitiveInfo) {
        userWalletDataStorage.savePrivateData(
            sensitiveInfo: sensitiveInfo,
            userWalletId: userWalletId,
            encryptionKey: encryptionKey
        )
    }
}

extension CommonKeysRepository: KeysRepository {
    var keys: [KeyInfo] {
        _keys.value.asKeyInfo
    }

    var keysPublisher: AnyPublisher<[KeyInfo], Never> {
        _keys
            .map { $0.asKeyInfo }
            .eraseToAnyPublisher()
    }

    func update(derivations: DerivationResult) {
        var existingKeys = _keys.value

        switch existingKeys {
        case .cardWallet(let keys):
            var mutableKeys = keys

            for masterKey in derivations {
                for derivedKey in masterKey.value.keys {
                    mutableKeys[masterKey.key]?.derivedKeys[derivedKey.key] = derivedKey.value
                }
            }

            existingKeys = .cardWallet(keys: mutableKeys)
            saveSensitiveData(sensitiveInfo: .cardWallet(keys: mutableKeys))

        case .mobileWallet(let keys):
            var mutableKeys = keys

            for masterKey in derivations {
                for derivedKey in masterKey.value.keys {
                    mutableKeys[masterKey.key]?.derivedKeys[derivedKey.key] = derivedKey.value
                }
            }

            existingKeys = .mobileWallet(keys: mutableKeys)
            saveSensitiveData(sensitiveInfo: .mobileWallet(keys: mutableKeys))
        }

        _keys.value = existingKeys
    }

    func update(keys: WalletKeys) {
        _keys.value = keys
    }
}

enum WalletKeys {
    case cardWallet(keys: [CardDTO.Wallet])
    case mobileWallet(keys: [KeyInfo])

    var asKeyInfo: [KeyInfo] {
        switch self {
        case .cardWallet(let keys):
            return keys.map { $0.keyInfo }
        case .mobileWallet(let keys):
            return keys
        }
    }
}
