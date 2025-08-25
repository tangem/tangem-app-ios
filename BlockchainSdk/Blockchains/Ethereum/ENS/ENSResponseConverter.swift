//
//  ENSResponseConverter.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

/// Converts the ENS response string to an Ethereum address.
///
/// - Parameter result: The ENS response string.
/// - Returns: The Ethereum address as a hex string.
///
/// Example input:
/// ```
/// "0x" +
/// "0000000000000000000000000000000000000000000000000000000000000040" +
/// "000000000000000000000000231b0ee14048e9dccd1d247744d114a4eb5e8e63" +
/// "0000000000000000000000000000000000000000000000000000000000000020" +
/// "000000000000000000000000d8da6bf26964af9d7eed9e03e53415d37aa96045"
/// ```
///
/// Example output:
/// ```
/// "0xd8da6bf26964af9d7eed9e03e53415d37aa96045"
/// ```
public enum ENSResponseConverter {
    public static func convert(_ result: String) throws -> String {
        let hexString = result.removeHexPrefix()

        guard hexString.count >= Constants.length else {
            throw ParseError.invalidResult("Input too short")
        }

        guard let offset = hexString.substring(from: 0, length: Constants.length).hexToInt() else {
            throw ParseError.invalidOffset
        }

        let offsetIndex = offset * 2
        guard hexString.count >= offsetIndex + Constants.length else {
            throw ParseError.invalidResult("Data too short at offset")
        }

        guard let length = hexString.substring(from: offsetIndex, length: Constants.length).hexToInt() else {
            throw ParseError.invalidLength
        }

        let dataStart = offsetIndex + Constants.length
        let dataEnd = dataStart + (length * 2)

        guard hexString.count >= dataEnd else {
            throw ParseError.invalidResult("Data segment out of bounds")
        }

        let dataHex = hexString.substring(from: dataStart, to: dataEnd)
        let addressHex = String(dataHex.suffix(Constants.suffix))

        return addressHex.addHexPrefix()
    }
}

extension ENSResponseConverter {
    enum ParseError: Error {
        case invalidResult(String)
        case invalidOffset
        case invalidLength
    }

    enum Constants {
        static let length: Int = 64
        static let suffix: Int = 40
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
