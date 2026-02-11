//
//  String+.swift
//  TangemFoundation
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

private let hexPrefix = "0x"

public extension String {
    func trim(toLength length: Int) -> String {
        String(prefix(length))
    }

    func contains(_ string: String, ignoreCase: Bool = true) -> Bool {
        return range(of: string, options: ignoreCase ? .caseInsensitive : []) != nil
    }

    func hasHexPrefix() -> Bool {
        return lowercased().hasPrefix(hexPrefix)
    }

    func hasHexPrefixStrictCheck() -> Bool {
        return hasPrefix(hexPrefix)
    }

    func removeHexPrefix() -> String {
        if hasHexPrefix() {
            return String(dropFirst(2))
        }

        return self
    }

    func addHexPrefix() -> String {
        if lowercased().hasPrefix(hexPrefix) {
            return self
        }

        return hexPrefix.appending(self)
    }

    func stripLeadingZeroes() -> String {
        replacingOccurrences(of: "^0+", with: "", options: .regularExpression)
    }

    func removeBchPrefix() -> String {
        if let index = firstIndex(where: { $0 == ":" }) {
            let startIndex = self.index(index, offsetBy: 1)
            return String(suffix(from: startIndex))
        }

        return self
    }

    func leftPadding(toLength: Int, withPad character: Character) -> String {
        let stringLength = count
        if stringLength < toLength {
            return String(repeatElement(character, count: toLength - stringLength)) + self
        } else {
            return String(suffix(toLength))
        }
    }

    var toUInt8: [UInt8] {
        let v = utf8CString.map { UInt8($0) }
        return Array(v[0 ..< (v.count - 1)])
    }

    var isValidHex: Bool {
        let regex = try! NSRegularExpression(pattern: "^[0-9a-f]*$", options: .caseInsensitive)

        let found = regex.firstMatch(in: self, options: [], range: NSRange(location: 0, length: count))

        if found == nil || found?.range.location == NSNotFound || count % 2 != 0 {
            return false
        }

        return true
    }

    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }

    mutating func capitalizeFirstLetter() {
        self = capitalizingFirstLetter()
    }

    subscript(bounds: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start ..< end])
    }

    static var unknown: String {
        "Unknown"
    }

    func base64URLToBase64() -> String {
        var base64 = replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        if base64.count % 4 != 0 {
            base64.append(String(repeating: "=", count: 4 - base64.count % 4))
        }
        return base64
    }

    /// Decodes a Base64 URL-safe encoded string to Data
    func base64URLDecodedData() -> Data? {
        let base64 = base64URLToBase64()
        return Data(base64Encoded: base64)
    }
}

extension String: @retroactive LocalizedError {
    public var errorDescription: String? {
        return self
    }
}
