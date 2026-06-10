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
        let storageIdentifier = userWalletId.stringValue

        let repository = CommonAddressBookRepository(
            userWalletId: userWalletId,
            cryptographer: CommonAddressBookCryptographer(),
            storage: makeStorage(storageIdentifier: storageIdentifier),
            eTagStorage: CommonAddressBookETagStorage()
        )

        return CommonAddressBookManager(repository: repository)
    }

    private func makeStorage(storageIdentifier: String) -> AddressBookPersistentStorage {
        #if DEBUG
        MockAddressBookPersistentStorage()
        #else
        CommonAddressBookPersistentStorage(storageIdentifier: storageIdentifier)
        #endif
    }
}
