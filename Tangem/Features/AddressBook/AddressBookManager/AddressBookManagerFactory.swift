//
//  AddressBookManagerFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct AddressBookManagerFactory {
    func makeAddressBookManager() -> AddressBookManager {
        CommonAddressBookManager(
            cryptographer: CommonAddressBookСryptographer(),
            synchronizer: CommonAddressBookAPISynchronizer(),
            storage: CommonAddressBookPersistentStorage()
        )
    }
}
