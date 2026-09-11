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

// MARK: - Convenience init

extension AddressBookWallet {
    init(wallet: UserWalletInfo, addressBookManager: AddressBookManager) {
        self.init(
            wallet: wallet,
            addressBookManager: addressBookManager,
            addressBookPublisher: addressBookManager.contactsPublisher,
            syncStatePublisher: addressBookManager.syncStatePublisher
        )
    }

    init(userWalletModel: UserWalletModel) {
        self.init(wallet: userWalletModel.userWalletInfo, addressBookManager: userWalletModel.addressBookManager)
    }
}
