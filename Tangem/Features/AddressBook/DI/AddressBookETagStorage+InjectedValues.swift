//
//  AddressBookETagStorage+InjectedValues.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension InjectedValues {
    var addressBookETagStorage: AddressBookETagStorage {
        get { Self[AddressBookETagStorageKey.self] }
        set { Self[AddressBookETagStorageKey.self] = newValue }
    }
}

// MARK: - Private implementation

private struct AddressBookETagStorageKey: InjectionKey {
    static var currentValue: AddressBookETagStorage = CommonAddressBookETagStorage()
}
