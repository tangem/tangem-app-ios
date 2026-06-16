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

    var addressBookPublisher: AnyPublisher<[AddressBookContact], Never> {
        addressBookManager.contactsPublisher
    }
}
