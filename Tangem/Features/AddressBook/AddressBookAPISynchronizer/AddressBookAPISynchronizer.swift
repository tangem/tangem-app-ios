//
//  AddressBookAPISynchronizer.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol AddressBookAPISynchronizer {
    var synchronizerState: AddressBookSynchronizerState { get }

    func sync(contacts: [AddressBookContact]) async
}
