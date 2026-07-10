//
//  AddressBookWallet.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

struct AddressBookWallet {
    let wallet: UserWalletInfo
    let addressBookManager: AddressBookManager
    let addressBookPublisher: AnyPublisher<[AddressBookContact], Never>
    let syncStatePublisher: AnyPublisher<AddressBookSyncState, Never>
}
