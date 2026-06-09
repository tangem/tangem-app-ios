//
//  CommonAddressBookCryptographer.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct CommonAddressBookCryptographer {
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
}

// MARK: - AddressBookCryptographer protocol conformance

extension CommonAddressBookCryptographer: AddressBookCryptographer {
    func encode(contact: AddressBookContact) throws -> String {
        let data = try encoder.encode(contact)
        return String(decoding: data, as: UTF8.self)
    }

    func decode(contact: String) throws -> AddressBookContact {
        let data = Data(contact.utf8)
        return try decoder.decode(AddressBookContact.self, from: data)
    }
}
