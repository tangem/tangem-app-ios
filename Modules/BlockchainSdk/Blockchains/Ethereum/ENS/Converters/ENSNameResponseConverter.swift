//
//  ENSNameResponseConverter.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

/// Converts the ENS Universal Resolver response string to a UTF-8 ENS name string.
///
/// The Universal Resolver returns a bytes blob with the following structure:
/// - 32 bytes: offset to name data
/// - 32 bytes: forward resolver address
/// - 32 bytes: reverse resolver address
/// - 32 bytes: name length
/// - N bytes:  name UTF-8 bytes (padded to 32-byte boundary)
enum ENSNameResponseConverter {
    static func convert(_ result: String) throws -> String {
        let hexString = result.removeHexPrefix()

        guard hexString.count >= Constants.wordHexLength else {
            throw ParseError.invalidResult("Input too short")
        }

        // Get offset to name data
        guard let offset = hexString.substring(from: 0, length: Constants.wordHexLength).hexToInt() else {
            throw ParseError.invalidOffset
        }

        let offsetIndex = offset * 2
        guard hexString.count >= offsetIndex + Constants.wordHexLength else {
            throw ParseError.invalidResult("Data too short at offset")
        }

        // Get name length
        guard let nameLength = hexString.substring(from: offsetIndex, length: Constants.wordHexLength).hexToInt() else {
            throw ParseError.invalidLength
        }

        // Check if name is empty (length = 0)
        guard nameLength > 0 else {
            throw ParseError.invalidResult("No ENS name found for this address")
        }

        let nameDataStart = offsetIndex + Constants.wordHexLength
        let nameDataEnd = nameDataStart + (nameLength * 2)
        guard hexString.count >= nameDataEnd else {
            throw ParseError.invalidResult("Name data segment out of bounds")
        }

        let nameHex = hexString.substring(from: nameDataStart, to: nameDataEnd)
        let nameData = Data(hexString: nameHex)

        guard let nameString = String(data: nameData, encoding: .utf8), !nameString.isEmpty else {
            throw ParseError.invalidResult("Failed to decode UTF-8 string")
        }

        return nameString
    }
}

extension ENSNameResponseConverter {
    enum ParseError: Error {
        case invalidResult(String)
        case invalidOffset
        case invalidLength
    }

    enum Constants {
        static let wordHexLength: Int = 64
    }
}

private extension String {
    func substring(from: Int, length: Int) -> String {
        let start = index(startIndex, offsetBy: from)
        let end = index(start, offsetBy: length)
        return String(self[start ..< end])
    }

    func substring(from: Int, to: Int) -> String {
        let start = index(startIndex, offsetBy: from)
        let end = index(startIndex, offsetBy: to)
        return String(self[start ..< end])
    }

    func hexToInt() -> Int? {
        Int(self, radix: 16)
    }
}
