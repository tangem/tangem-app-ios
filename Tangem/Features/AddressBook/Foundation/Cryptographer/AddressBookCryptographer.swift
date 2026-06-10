//
//  AddressBookCryptographer.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol AddressBookCryptographer {
    func encode(addressBook: AddressBook) throws -> Data
    func decode(addressBook: Data) throws -> AddressBook
}
