//
//  CommonAddressBookETagStorage.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

final class CommonAddressBookETagStorage {
    /// - Note: Despite the name of the type, this inner storage is not limited to BlockchainSDK. It's just a convenient UserDefaults wrapper.
    private let innerStorage: UserDefaultsBlockchainDataStorage

    init(suiteName: String? = nil) {
        innerStorage = UserDefaultsBlockchainDataStorage(suiteName: suiteName)
    }

    private func makeKey(for userWalletId: UserWalletId) -> String {
        "AddressBookETagStorage_\(userWalletId.stringValue)"
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
