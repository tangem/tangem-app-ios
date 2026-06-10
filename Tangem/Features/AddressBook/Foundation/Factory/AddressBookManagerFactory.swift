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
            storage: CommonAddressBookPersistentStorage(storageIdentifier: storageIdentifier),
            eTagStorage: CommonAddressBookETagStorage()
        )

        let networkService = CommonAddressBookNetworkService(userWalletId: userWalletId)

        return CommonAddressBookManager(repository: repository, networkService: networkService)
    }
}
