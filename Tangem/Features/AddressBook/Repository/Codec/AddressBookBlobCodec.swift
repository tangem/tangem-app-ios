//
//  AddressBookBlobCodec.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Serializes the address-book plaintext to and from JSON before encryption. Centralizing the JSON
/// configuration here keeps the blob schema in one place. Signature bytes use the Base64 default; the
/// exact on-the-wire schema is a cross-platform contract to confirm with the other clients.
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
        return encoder
    }()

    private static let decoder = JSONDecoder()
}
