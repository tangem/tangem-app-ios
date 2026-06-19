//
//  CommonAddressBookETagStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

final class CommonAddressBookETagStorage {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    /// - Note: Despite the name of the type, this inner storage is not limited to BlockchainSDK. It's
    /// just a convenient UserDefaults wrapper, used the same way by the crypto-accounts ETag storage.
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
            userWalletIds.forEach(clearETag(for:))
        default:
            break
        }
    }

    private func makeKey(for userWalletId: UserWalletId) -> String {
        "AddressBookETagStorage_\(userWalletId.stringValue)"
    }
}

// MARK: - Initializable protocol conformance

extension CommonAddressBookETagStorage: Initializable {
    func initialize() {
        bind()
    }
}

// MARK: - AddressBookETagStorage protocol conformance

extension CommonAddressBookETagStorage: AddressBookETagStorage {
    func loadETag(for userWalletId: UserWalletId) -> String? {
        innerStorage.get(key: makeKey(for: userWalletId))
    }

    func saveETag(_ eTag: String, for userWalletId: UserWalletId) {
        innerStorage.store(key: makeKey(for: userWalletId), value: eTag)
    }

    func clearETag(for userWalletId: UserWalletId) {
        let value: String? = nil
        innerStorage.store(key: makeKey(for: userWalletId), value: value)
    }
}
