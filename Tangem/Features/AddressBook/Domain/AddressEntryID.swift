//
//  AddressEntryID.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Immutable, client-generated identity of an `AddressEntry`.
///
/// Serialized as a lowercase UUID string, mirroring `ContactID`.
struct AddressEntryID: Hashable {
    let rawValue: UUID

    init(rawValue: UUID = UUID()) {
        self.rawValue = rawValue
    }

    var stringValue: String {
        rawValue.uuidString.lowercased()
    }
}

extension AddressEntryID: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)

        guard let uuid = UUID(uuidString: raw) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid address entry UUID: \(raw)")
        }

        rawValue = uuid
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(stringValue)
    }
}
