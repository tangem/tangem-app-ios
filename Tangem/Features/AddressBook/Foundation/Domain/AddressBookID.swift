//
//  AddressBookID.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

typealias AddressBookContactID = AddressBookID
typealias AddressBookAddressEntryID = AddressBookID

/// Immutable, client-generated UUID identity for address-book entities (contacts and address entries).
///
/// Serialized as a lowercase UUID string both inside the encrypted blob and inside the signed tuple
/// (see `AddressBookSignedTuplePayload`); the lowercase form is part of the cross-platform signature
/// contract and must match other clients byte-for-byte.
struct AddressBookID: Hashable {
    let rawValue: UUID

    init(rawValue: UUID = UUID()) {
        self.rawValue = rawValue
    }

    /// Canonical lowercase string used for serialization and signing.
    var stringValue: String {
        rawValue.uuidString.lowercased()
    }
}

extension AddressBookID: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)

        guard let uuid = UUID(uuidString: raw) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid address book UUID: \(raw)")
        }

        rawValue = uuid
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(stringValue)
    }
}
