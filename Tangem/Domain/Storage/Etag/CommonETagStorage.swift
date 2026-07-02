//
//  CommonETagStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class CommonETagStorage {
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
            .sink { storage, event in
                storage.handleUserWalletRepositoryEvent(event)
            }
    }

    private func handleUserWalletRepositoryEvent(_ event: UserWalletRepositoryEvent) {
        switch event {
        case .deleted(let userWalletIds, _):
            for userWalletId in userWalletIds {
                clearETag(for: .accounts(walletId: userWalletId))
                clearETag(for: .addressBook(walletId: userWalletId))
            }
        default:
            break
        }
    }
}

// MARK: - Initializable protocol conformance

extension CommonETagStorage: Initializable {
    func initialize() {
        bind()
    }
}

// MARK: - ETagStorage protocol conformance

extension CommonETagStorage: ETagStorage {
    func loadETag(for key: ETagStorageKey) -> String? {
        innerStorage.get(key: key.storageKey)
    }

    func saveETag(_ eTag: String, for key: ETagStorageKey) {
        innerStorage.store(key: key.storageKey, value: eTag)
    }

    func clearETag(for key: ETagStorageKey) {
        let value: String? = nil
        innerStorage.store(key: key.storageKey, value: value)
    }
}

private extension ETagStorageKey {
    var storageKey: String {
        switch self {
        case .accounts(let walletId): "CryptoAccountsETagStorage_\(walletId.stringValue)"
        case .addressBook(let walletId): "AddressBookETagStorage_\(walletId.stringValue)"
        }
    }
}
