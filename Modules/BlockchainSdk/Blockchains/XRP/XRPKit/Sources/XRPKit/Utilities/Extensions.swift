//
//  Extensions.swift
//  XRPKit
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation

extension Data {
    func sha512Half() -> Data {
        Data(sha512().prefix(through: 31))
    }
}

extension Data {
    init(xrpHex hex: String) {
        var data = Data(capacity: hex.count / 2)

        let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
        regex.enumerateMatches(in: hex, options: [], range: NSMakeRange(0, hex.count)) { match, flags, stop in
            let byteString = (hex as NSString).substring(with: match!.range)
            var num = UInt8(byteString, radix: 16)!
            data.append(&num, count: 1)
        }

        self = data
    }
}

typealias Byte = UInt8
enum Bit: Int {
    case zero
    case one
}

// extension Data {
//    var bytes: [Byte] {
//        var byteArray = [UInt8](repeating: 0, count: self.count)
//        self.copyBytes(to: &byteArray, count: self.count)
//        return byteArray
//    }
// }

extension String {
    // Create `Data` from hexadecimal string representation
    //
    // This creates a `Data` object from hex string. Note, if the string has any spaces or non-hex characters (e.g. starts with '<' and with a '>'), those are ignored and only hex characters are processed.
    //
    // - returns: Data represented by this hexadecimal string.
}

extension Data {
    // Hexadecimal string representation of `Data` object.
}

extension Numeric {
    var data: Data {
        var source = self
        return withUnsafeBytes(of: &source) { Data($0) }
    }
}
