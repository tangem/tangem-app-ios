//
//  CommonAddressBookСryptographer.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct CommonAddressBookСryptographer {
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
}

// MARK: - AddressBookСryptographer protocol conformance

extension CommonAddressBookСryptographer: AddressBookСryptographer {
    func encode(contact: AddressBookContact) throws -> String {
        let data = try encoder.encode(contact)
        return String(decoding: data, as: UTF8.self)
    }

    func decode(contact: String) throws -> AddressBookContact {
        let data = Data(contact.utf8)
        return try decoder.decode(AddressBookContact.self, from: data)
    }
}
