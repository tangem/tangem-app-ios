//
//  CommonAddressBookAPISynchronizer.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct CommonAddressBookAPISynchronizer {
    let synchronizerState: AddressBookSynchronizerState = .idle
}

// MARK: - AddressBookAPISynchronizer protocol conformance

extension CommonAddressBookAPISynchronizer: AddressBookAPISynchronizer {
    func sync(contacts: [AddressBookContact]) async {
        // [REDACTED_TODO_COMMENT]
    }
}
