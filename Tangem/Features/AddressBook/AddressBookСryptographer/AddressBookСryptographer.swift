//
//  AddressBookСryptographer.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol AddressBookСryptographer {
    func encode(contact: AddressBookContact) throws -> String
    func decode(contact: String) throws -> AddressBookContact
}
