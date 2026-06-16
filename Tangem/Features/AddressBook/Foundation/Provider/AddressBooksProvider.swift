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
    let addressBookPublisher: AnyPublisher<[Contact], Never>
}
