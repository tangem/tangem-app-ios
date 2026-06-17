//
//  AddressBookBlobCodec.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Serializes the address-book plaintext to and from JSON before encryption. Centralizing the JSON
/// configuration here keeps the blob schema in one place. Dates use ISO-8601 with fractional seconds
/// and signature bytes use Base64 — the on-the-wire schema is a cross-platform contract.
struct AddressBookBlobCodec {
    static let supportedVersion = "1.0"

    func encode(_ plaintext: AddressBookPlaintext) throws -> Data {
        try Self.encoder.encode(plaintext)
    }

    func decode(_ data: Data) throws -> AddressBookPlaintext {
        try Self.decoder.decode(AddressBookPlaintext.self, from: data)
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dataEncodingStrategy = .base64
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(addressBookBlobDateFormatter.string(from: date))
        }
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let string = try decoder.singleValueContainer().decode(String.self)

            guard let date = addressBookBlobDateFormatter.date(from: string) else {
                throw DecodingError.dataCorrupted(
                    .init(codingPath: decoder.codingPath, debugDescription: "Invalid ISO-8601 date: \(string)")
                )
            }

            return date
        }
        return decoder
    }()
}

private let addressBookBlobDateFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
}()
