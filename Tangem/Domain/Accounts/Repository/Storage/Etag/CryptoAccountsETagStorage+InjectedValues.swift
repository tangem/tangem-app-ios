//
//  CryptoAccountsETagStorage+InjectedValues.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension InjectedValues {
    var cryptoAccountsETagStorage: CryptoAccountsETagStorage {
        get { Self[CryptoAccountsETagStorageKey.self] }
        set { Self[CryptoAccountsETagStorageKey.self] = newValue }
    }
}

// MARK: - Private implementation

private struct CryptoAccountsETagStorageKey: InjectionKey {
    static var currentValue: CryptoAccountsETagStorage = CommonCryptoAccountsETagStorage()
}
