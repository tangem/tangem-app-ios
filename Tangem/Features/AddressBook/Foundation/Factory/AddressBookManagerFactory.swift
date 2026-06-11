//
//  AddressBookManagerFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation

struct AddressBookManagerFactory {
    func makeAddressBookManager(userWalletId: UserWalletId) -> AddressBookManager {
        let repository = CommonAddressBookRepository(
            userWalletId: userWalletId,
            cryptographer: CommonAddressBookCryptographer(),
            storage: makeStorage(userWalletId: userWalletId),
            eTagStorage: CommonAddressBookETagStorage()
        )

        return CommonAddressBookManager(repository: repository)
    }

    private func makeStorage(userWalletId: UserWalletId) -> AddressBookPersistentStorage {
        #if DEBUG
        MockAddressBookPersistentStorage(userWalletId: userWalletId)
        #else
        CommonAddressBookPersistentStorage(storageIdentifier: userWalletId.stringValue)
        #endif
    }
}
