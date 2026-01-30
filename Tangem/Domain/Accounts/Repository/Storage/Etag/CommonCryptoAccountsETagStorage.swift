//
//  CommonCryptoAccountsETagStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class CommonCryptoAccountsETagStorage {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    /// - Note: Despite the name of the type, this inner storage is not limited to BlockchainSDK. It's just a convenient UserDefaults wrapper.
    private let innerStorage: UserDefaultsBlockchainDataStorage

    private var eventProviderSubscription: AnyCancellable?

    init(suiteName: String? = nil) {
        innerStorage = UserDefaultsBlockchainDataStorage(suiteName: suiteName)
    }

    private func bind() {
        eventProviderSubscription = userWalletRepository
            .eventProvider
            .withWeakCaptureOf(self)
            .sink { manager, event in
                manager.handleUserWalletRepositoryEvent(event)
            }
    }

    private func handleUserWalletRepositoryEvent(_ event: UserWalletRepositoryEvent) {
        switch event {
        case .deleted(let userWalletIds, _):
            userWalletIds.forEach(clearETag(for:))
        default:
            break
        }
    }

    private func makeKey(for userWalletId: UserWalletId) -> String {
        "CryptoAccountsETagStorage_\(userWalletId.stringValue)"
    }
}

// MARK: - Initializable protocol conformance

extension CommonCryptoAccountsETagStorage: Initializable {
    func initialize() {
        bind()
    }
}

// MARK: - CryptoAccountsETagStorage protocol conformance

extension CommonCryptoAccountsETagStorage: CryptoAccountsETagStorage {
    func loadETag(for userWalletId: UserWalletId) -> String? {
        let key = makeKey(for: userWalletId)

        return innerStorage.get(key: key)
    }

    func saveETag(_ eTag: String, for userWalletId: UserWalletId) {
        let key = makeKey(for: userWalletId)
        innerStorage.store(key: key, value: eTag)
    }

    func clearETag(for userWalletId: UserWalletId) {
        let key = makeKey(for: userWalletId)
        let value: String? = nil
        innerStorage.store(key: key, value: value)
    }
}
