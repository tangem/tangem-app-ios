//
//  WalletBackupJSONCodec.swift
//  TangemMobileWalletBackup
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Serializes backup schemas to and from JSON. Centralizing the JSON configuration here keeps
/// the wire format in one place: binary fields are written as lowercase hex strings — the
/// cross-platform contract of the backup file — instead of the base64 a plain `JSONEncoder` emits.
enum WalletBackupJSONCodec {
    /// Encodes any backup schema: the file and the payload sealed inside it.
    ///
    /// Output is pretty-printed with sorted keys for the sake of the backup file, which the user
    /// sees in iCloud Drive; the payload rides along with the same formatting — it is encrypted,
    /// so its layout is nobody's contract.
    static func encode(_ value: some Encodable) throws -> Data {
        try encoder.encode(value)
    }

    /// Decodes any backup schema: the file, the payload and the bare `version` probe.
    /// A malformed hex field fails right here, and the thrown `DecodingError` carries
    /// the coding path of the offending field.
    static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        try decoder.decode(type, from: data)
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]

        encoder.dataEncodingStrategy = .custom { data, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(data.lowercasedHexString)
        }

        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()

        decoder.dataDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let hexString = try container.decode(String.self)

            let data = Data(hexString: hexString)
            guard !data.isEmpty else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Not a valid hex string"
                )
            }

            return data
        }

        return decoder
    }()
}
