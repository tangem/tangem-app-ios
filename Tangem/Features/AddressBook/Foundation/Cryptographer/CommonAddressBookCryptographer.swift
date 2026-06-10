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
    func encode(addressBook: AddressBook) throws -> Data {
        let data = try encoder.encode(addressBook)
        return data
    }

    func decode(addressBook data: Data) throws -> AddressBook {
        return try decoder.decode(AddressBook.self, from: data)
    }
}
