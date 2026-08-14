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
import TangemSdk

protocol KeysRepository: AnyObject, KeysProvider {
    func update(derivations: DerivationResult)
    func update(keys: WalletKeys)
}

protocol KeysProvider {
    var keys: [KeyInfo] { get }
    var keysPublisher: AnyPublisher<[KeyInfo], Never> { get }
}

extension KeysProvider {
    func masterKey(curve: EllipticCurve) throws -> KeyInfo {
        // Use the last key for the selected curve because there may be multiple `KeyInfo`
        // entries with the same curve. The XPUB public key factories use `reduce(into:)`
        // and keep the last `KeyInfo` for a given curve, so `last(where:)` matches that behavior.
        guard let masterKey = keys.last(where: { $0.curve == curve }) else {
            throw KeysProviderError.masterKeyNotFound
        }

        return masterKey
    }

    /// The master key's own public key, which is what deriving from it is keyed by.
    func masterKeyPublicKey(curve: EllipticCurve) throws -> Data {
        guard let publicKey = try masterKey(curve: curve).publicKey else {
            throw KeysProviderError.masterKeyNotFound
        }

        return publicKey
    }
}

enum KeysProviderError: String, LocalizedError {
    case masterKeyNotFound
}

final class CommonKeysRepository {
    private let _keys: CurrentValueSubject<WalletKeys, Never>

    private weak var userWalletModel: UserWalletModel?

    init(
        keys: WalletKeys
    ) {
        _keys = .init(keys)
    }

    // MARK: - Configuration

    func configure(with userWalletModel: UserWalletModel) {
        self.userWalletModel = userWalletModel
    }

    // MARK: - Helpers

    private func saveSensitiveData(sensitiveInfo: StoredUserWallet.SensitiveInfo) {
        userWalletModel?.update(type: .updateSensitiveInfo(sensitiveInfo: sensitiveInfo))
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
        let existingKeys = _keys.value
        let updatedKeys: WalletKeys

        switch existingKeys {
        case .cardWallet(let keys):
            var mutableKeys = keys

            for masterKey in derivations {
                for derivedKey in masterKey.value.keys {
                    mutableKeys[masterKey.key]?.derivedKeys[derivedKey.key] = derivedKey.value
                }
            }
            updatedKeys = .cardWallet(keys: mutableKeys)
            saveSensitiveData(sensitiveInfo: .cardWallet(keys: mutableKeys))

        case .mobileWallet(let keys):
            var mutableKeys = keys

            for masterKey in derivations {
                for derivedKey in masterKey.value.keys {
                    mutableKeys[masterKey.key]?.derivedKeys[derivedKey.key] = derivedKey.value
                }
            }
            updatedKeys = .mobileWallet(keys: mutableKeys)
            saveSensitiveData(sensitiveInfo: .mobileWallet(keys: mutableKeys))
        }

        _keys.value = updatedKeys
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
