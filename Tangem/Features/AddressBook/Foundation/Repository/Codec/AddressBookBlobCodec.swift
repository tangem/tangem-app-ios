//
//  AddressBookBlobCodec.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

/// Serializes the address-book plaintext to and from JSON before encryption. Centralizing the JSON
/// configuration here keeps the blob schema in one place. Dates use ISO-8601 with fractional seconds
/// and signature bytes use hex — matching the envelope fields, the on-the-wire schema is a cross-platform contract.
struct AddressBookBlobCodec {
    static let supportedVersion = "1.0"

    /// Canonical output format shared with `AddressBookNetworkMapper`: contact timestamps and the
    /// envelope header are always *written* as ISO-8601 with fractional seconds.
    static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    /// `ISO8601DateFormatter` with `.withFractionalSeconds` rejects whole-second timestamps, so parsing
    /// falls back to this formatter when a cross-platform peer or a server emits seconds without a
    /// fractional component (mirrors the repo's `iso8601withFractionalSeconds ?? iso8601` convention).
    private static let dateParsingFallbackFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    /// Parses an ISO-8601 timestamp accepting both fractional- and whole-second forms.
    static func date(fromISO8601 string: String) -> Date? {
        dateFormatter.date(from: string) ?? dateParsingFallbackFormatter.date(from: string)
    }

    func encode(_ plaintext: AddressBookPlaintext) throws -> Data {
        try Self.encoder.encode(plaintext)
    }

    func decode(_ data: Data) throws -> AddressBookPlaintext {
        try Self.decoder.decode(AddressBookPlaintext.self, from: data)
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dataEncodingStrategy = .custom { data, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(data.hexString)
        }
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(Self.dateFormatter.string(from: date))
        }
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dataDecodingStrategy = .custom { decoder in
            let string = try decoder.singleValueContainer().decode(String.self)

            guard !string.isEmpty else { return Data() }

            let data = Data(hexString: string)

            guard !data.isEmpty else {
                throw DecodingError.dataCorrupted(
                    .init(codingPath: decoder.codingPath, debugDescription: "Invalid hex data: \(string)")
                )
            }

            return data
        }
        decoder.dateDecodingStrategy = .custom { decoder in
            let string = try decoder.singleValueContainer().decode(String.self)

            guard let date = Self.date(fromISO8601: string) else {
                throw DecodingError.dataCorrupted(
                    .init(codingPath: decoder.codingPath, debugDescription: "Invalid ISO-8601 date: \(string)")
                )
            }

            return date
        }
        return decoder
    }()
}
