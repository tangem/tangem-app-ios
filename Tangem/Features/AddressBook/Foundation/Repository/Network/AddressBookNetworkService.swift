//
//  AddressBookNetworkService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

protocol AddressBookNetworkService {
    func loadAddressBook(walletId: UserWalletId, knownETag: String?) async throws -> AddressBookFetchResult
    func saveAddressBook(_ envelope: AddressBookEnvelope, walletId: UserWalletId, knownETag: String?) async throws -> AddressBookSaveResult
}

extension InjectedValues {
    var addressBookNetworkService: AddressBookNetworkService {
        get { Self[AddressBookNetworkServiceInjectionKey.self] }
        set { Self[AddressBookNetworkServiceInjectionKey.self] = newValue }
    }
}

// MARK: - Private implementation

private struct AddressBookNetworkServiceInjectionKey: InjectionKey {
    static var currentValue: AddressBookNetworkService = CommonAddressBookNetworkService()
}
