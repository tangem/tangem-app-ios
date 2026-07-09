//
//  ETagStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

protocol ETagStorage: Initializable {
    func loadETag(for key: ETagStorageKey) -> String?
    func saveETag(_ eTag: String, for key: ETagStorageKey)
    func clearETag(for key: ETagStorageKey)
}

enum ETagStorageKey {
    case accounts(walletId: UserWalletId)
    case addressBook(walletId: UserWalletId)
}

extension InjectedValues {
    var eTagStorage: ETagStorage {
        get { Self[ETagStorageInjectionKey.self] }
        set { Self[ETagStorageInjectionKey.self] = newValue }
    }
}

// MARK: - Private implementation

private struct ETagStorageInjectionKey: InjectionKey {
    static var currentValue: ETagStorage = CommonETagStorage(innerStorage: UserDefaultsBlockchainDataStorage())
}
