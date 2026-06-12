//
//  ContactID.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Immutable, client-generated identity of a `Contact`.
///
/// Serialized as a lowercase UUID string both inside the encrypted address-book blob and inside the
/// signed tuple (see `SignedTuplePayload`). The lowercase form is part of the cross-platform
/// signature contract and must match other clients byte-for-byte.
struct ContactID: Hashable {
    let rawValue: UUID

    init(rawValue: UUID = UUID()) {
        self.rawValue = rawValue
    }

    /// Canonical lowercase string used for serialization and signing.
    var stringValue: String {
        rawValue.uuidString.lowercased()
    }
}

extension ContactID: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)

        guard let uuid = UUID(uuidString: raw) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid contact UUID: \(raw)")
        }

        rawValue = uuid
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(stringValue)
    }
}
