//
//  AddressBooksProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

protocol AddressBooksProvider {
    var addressBooks: [AddressBookWallet] { get }
}

struct AddressBookWallet {
    let wallet: UserWalletInfo
    let addressBookManager: AddressBookManager

    var addressBookPublisher: AnyPublisher<AddressBook, Never> {
        addressBookManager.addressBookPublisher
    }
}

// MARK: - Implementations

extension AddressBooksProvider where Self == CommonAddressBooksProvider {
    static func common() -> Self { .init() }
}
