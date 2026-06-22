//
//  AddressBookAddAddressRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol AddressBookAddAddressRoutable: AnyObject {
    func dismissAddAddress()
    func openQRScanner(completion: @escaping (String) -> Void)
}
