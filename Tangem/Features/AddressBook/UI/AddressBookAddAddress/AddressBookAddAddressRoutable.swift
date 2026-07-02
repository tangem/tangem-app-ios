//
//  AddressBookAddAddressRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol AddressBookAddAddressRoutable: AnyObject, ChooseNetworkRoutable {
    func dismissAddAddress()
    func dismissAddAddressFlow()
    func openQRScanner(completion: @escaping (String) -> Void)
    func presentChooseNetwork(_ viewModel: ChooseNetworkViewModel)
}
