//
//  Bech32.swift
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Evolution Group Ltd. All rights reserved.
//
//  Base32 address format for native v0-16 witness outputs implementation
//  https://github.com/bitcoin/bips/blob/master/bip-0173.mediawiki
//  Inspired by Pieter Wuille C++ implementation
//


import Foundation

/// Bech32 checksum implementation
public class Bech32 {
  
    private static let base32Alphabets = "qpzry9x8gf2tvdw0s3jn54khce6mua7l"
    
    public static func encode(_ bytes: Data, prefix: String, seperator: String = ":") -> String {
        let payload = convertTo5bit(data: bytes, pad: true)
        let checksum: Data = createChecksum(prefix: prefix, payload: payload) // Data of [UInt5]
        let combined: Data = payload + checksum // Data of [UInt5]
        var base32 = ""
        for b in combined {
            base32 += String(base32Alphabets[String.Index(utf16Offset: Int(b), in: base32Alphabets)])
        }
        
        return prefix + seperator + base32
    }
    
    // string : "bitcoincash:qql8zpwglr3q5le9jnjxkmypefaku39dkygsx29fzk"
    public static func decode(_ string: String, seperator: String = ":") -> (prefix: String, data: Data)? {
        // We can't have empty string.
        // Bech32 should be uppercase only / lowercase only.
        guard !string.isEmpty && [string.lowercased(), string.uppercased()].contains(string) else {
            return nil
        }
        
        let components = string.components(separatedBy: seperator)
        // We can only handle string contains both scheme and base32
        guard components.count == 2 else {
            return nil
        }
        let (prefix, base32) = (components[0], components[1])
        
        var decodedIn5bit: [UInt8] = [UInt8]()
        for c in base32.lowercased() {
            // We can't have characters other than base32 alphabets.
            guard let baseIndex = base32Alphabets.firstIndex(of: c)?.utf16Offset(in: base32Alphabets) else {
                return nil
            }
            decodedIn5bit.append(UInt8(baseIndex))
        }
        
        // We can't have invalid checksum
        let payload = Data(decodedIn5bit)
        guard verifyChecksum(prefix: prefix, payload: payload) else {
            return nil
        }
        
        // Drop checksum
        guard let bytes = try? convertFrom5bit(data: payload.dropLast(8)) else {
            return nil
        }
        return (prefix, Data(bytes))
    }
    
    private static func verifyChecksum(prefix: String, payload: Data) -> Bool {
        return PolyMod(expand(prefix) + payload) == 0
    }
    
    private static func expand(_ prefix: String) -> Data {
        var ret: Data = Data()
        let buf: [UInt8] = Array(prefix.utf8)
        for b in buf {
            ret += b & 0x1f
        }
        ret += Data(repeating: 0, count: 1)
        return ret
    }
    
    private static func createChecksum(prefix: String, payload: Data) -> Data {
        let enc: Data = expand(prefix) + payload + Data(repeating: 0, count: 8)
        let mod: UInt64 = PolyMod(enc)
        var ret: Data = Data()
        for i in 0..<8 {
            ret += UInt8((mod >> (5 * (7 - i))) & 0x1f)
        }
        return ret
    }
    
    private static func PolyMod(_ data: Data) -> UInt64 {
        var c: UInt64 = 1
        for d in data {
            let c0: UInt8 = UInt8(c >> 35)
            c = ((c & 0x07ffffffff) << 5) ^ UInt64(d)
            if c0 & 0x01 != 0 { c ^= 0x98f2bc8e61 }
            if c0 & 0x02 != 0 { c ^= 0x79b76d99e2 }
            if c0 & 0x04 != 0 { c ^= 0xf33e5fb3c4 }
            if c0 & 0x08 != 0 { c ^= 0xae2eabe2a8 }
            if c0 & 0x10 != 0 { c ^= 0x1e4f43e470 }
        }
        return c ^ 1
    }
    
    private static func convertTo5bit(data: Data, pad: Bool) -> Data {
        var acc = Int()
        var bits = UInt8()
        let maxv: Int = 31 // 31 = 0x1f = 00011111
        var converted: [UInt8] = []
        for d in data {
            acc = (acc << 8) | Int(d)
            bits += 8
            
            while bits >= 5 {
                bits -= 5
                converted.append(UInt8(acc >> Int(bits) & maxv))
            }
        }
        
        let lastBits: UInt8 = UInt8(acc << (5 - bits) & maxv)
        if pad && bits > 0 {
            converted.append(lastBits)
        }
        return Data(converted)
    }
    
    internal static func convertFrom5bit(data: Data) throws -> Data {
        var acc = Int()
        var bits = UInt8()
        let maxv: Int = 255 // 255 = 0xff = 11111111
        var converted: [UInt8] = []
        for d in data {
            guard (d >> 5) == 0 else {
                throw DecodeError.invalidCharacter
            }
            acc = (acc << 5) | Int(d)
            bits += 5
            
            while bits >= 8 {
                bits -= 8
                converted.append(UInt8(acc >> Int(bits) & maxv))
            }
        }
        
        let lastBits: UInt8 = UInt8(acc << (8 - bits) & maxv)
        guard bits < 5 && lastBits == 0  else {
            throw DecodeError.invalidBits
        }
        
        return Data(converted)
    }
    
    private enum DecodeError: Error {
        case invalidCharacter
        case invalidBits
    }
    
    private let gen: [UInt32] = [0x3b6a57b2, 0x26508e6d, 0x1ea119fa, 0x3d4233dd, 0x2a1462b3]
    /// Bech32 checksum delimiter
    private let checksumMarker: String = "1"
    /// Bech32 character set for encoding
    private let encCharset: Data = "qpzry9x8gf2tvdw0s3jn54khce6mua7l".data(using: .utf8)!
    /// Bech32 character set for decoding
    private let decCharset: [Int8] = [
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
        15, -1, 10, 17, 21, 20, 26, 30,  7,  5, -1, -1, -1, -1, -1, -1,
        -1, 29, -1, 24, 13, 25,  9,  8, 23, -1, 18, 22, 31, 27, 19, -1,
        1,  0,  3, 16, 11, 28, 12, 14,  6,  4,  2, -1, -1, -1, -1, -1,
        -1, 29, -1, 24, 13, 25,  9,  8, 23, -1, 18, 22, 31, 27, 19, -1,
        1,  0,  3, 16, 11, 28, 12, 14,  6,  4,  2, -1, -1, -1, -1, -1
    ]
    
    /// Find the polynomial with value coefficients mod the generator as 30-bit.
    private func polymod(_ values: Data) -> UInt32 {
        var chk: UInt32 = 1
        for v in values {
            let top = (chk >> 25)
            chk = (chk & 0x1ffffff) << 5 ^ UInt32(v)
            for i: UInt8 in 0..<5 {
                chk ^= ((top >> i) & 1) == 0 ? 0 : gen[Int(i)]
            }
        }
        return chk
    }
    
    /// Expand a HRP for use in checksum computation.
    private func expandHrp(_ hrp: String) -> Data {
        guard let hrpBytes = hrp.data(using: .utf8) else {
            return Data()
        }
        
        var result = Data(repeating: 0x00, count: hrpBytes.count * 2 + 1)
        for (i, c) in hrpBytes.enumerated() {
            result[i] = c >> 5
            result[i + hrpBytes.count + 1] = c & 0x1f
        }
        result[hrp.count] = 0
        return result
    }
    
    /// Verify checksum
    private func verifyChecksum(hrp: String, checksum: Data) -> Bool {
        var data = expandHrp(hrp)
        data.append(checksum)
        return polymod(data) == 1
    }
    
    /// Create checksum
    private func createChecksum(hrp: String, values: Data) -> Data {
        var enc = expandHrp(hrp)
        enc.append(values)
        enc.append(Data(repeating: 0x00, count: 6))
        let mod: UInt32 = polymod(enc) ^ 1
        var ret: Data = Data(repeating: 0x00, count: 6)
        for i in 0..<6 {
            ret[i] = UInt8((mod >> (5 * (5 - i))) & 31)
        }
        return ret
    }
    
    /// Encode Bech32 string
    public func encode(_ hrp: String, values: Data) -> String {
        guard let convertedValues = try? convertBits(data: values.bytes, fromBits: 8, toBits: 5, pad: true) else {
            assertionFailure()
            return ""
        }

        var combined = Data(convertedValues)
        let checksum = createChecksum(hrp: hrp, values: combined)
        combined.append(checksum)
        guard let hrpBytes = hrp.data(using: .utf8) else { return "" }
        var ret = hrpBytes
        ret.append("1".data(using: .utf8)!)

        for i in combined {
            ret.append(encCharset[Int(i)])
        }
        return String(data: ret, encoding: .utf8) ?? ""
    }
    
    /// Encode Bech32 for BitcoinCore framework string
    public func bitcoinCoreEncode(_ hrp: String, values: Data) -> String {
        let checksum = createChecksum(hrp: hrp, values: values)
        var combined = values
        combined.append(checksum)
        guard let hrpBytes = hrp.data(using: .utf8) else { return "" }
        var ret = hrpBytes
        ret.append("1".data(using: .utf8)!)
        for i in combined {
            ret.append(encCharset[Int(i)])
        }
        return String(data: ret, encoding: .utf8) ?? ""
    }
    
    /// Decode Bech32 string
    public func decode(_ str: String) throws -> (hrp: String, checksum: Data) {
        guard let strBytes = str.data(using: .utf8) else {
            throw DecodingError.nonUTF8String
        }
        guard strBytes.count <= 90 else {
            throw DecodingError.stringLengthExceeded
        }
        var lower: Bool = false
        var upper: Bool = false
        for c in strBytes {
            // printable range
            if c < 33 || c > 126 {
                throw DecodingError.nonPrintableCharacter
            }
            // 'a' to 'z'
            if c >= 97 && c <= 122 {
                lower = true
            }
            // 'A' to 'Z'
            if c >= 65 && c <= 90 {
                upper = true
            }
        }
        if lower && upper {
            throw DecodingError.invalidCase
        }
        guard let pos = str.range(of: checksumMarker, options: .backwards)?.lowerBound else {
            throw DecodingError.noChecksumMarker
        }
        let intPos: Int = str.distance(from: str.startIndex, to: pos)
        guard intPos >= 1 else {
            throw DecodingError.incorrectHrpSize
        }
        guard intPos + 7 <= str.count else {
            throw DecodingError.incorrectChecksumSize
        }
        let vSize: Int = str.count - 1 - intPos
        var values: Data = Data(repeating: 0x00, count: vSize)
        for i in 0..<vSize {
            let c = strBytes[i + intPos + 1]
            let decInt = decCharset[Int(c)]
            if decInt == -1 {
                throw DecodingError.invalidCharacter
            }
            values[i] = UInt8(decInt)
        }
        let hrp = String(str[..<pos]).lowercased()
        guard verifyChecksum(hrp: hrp, checksum: values) else {
            throw DecodingError.checksumMismatch
        }
        return (hrp, Data(values[..<(vSize-6)]))
    }
    
    /// Decode long Bech32 string
        public func decodeLong(_ str: String) throws -> (hrp: String, checksum: Data) {
            guard let strBytes = str.data(using: .utf8) else {
                throw DecodingError.nonUTF8String
            }
    //        guard strBytes.count <= 90 else {
    //            throw DecodingError.stringLengthExceeded
    //        }
            
            var lower: Bool = false
            var upper: Bool = false
            for c in strBytes {
                // printable range
                if c < 33 || c > 126 {
                    throw DecodingError.nonPrintableCharacter
                }
                // 'a' to 'z'
                if c >= 97 && c <= 122 {
                    lower = true
                }
                // 'A' to 'Z'
                if c >= 65 && c <= 90 {
                    upper = true
                }
            }
            if lower && upper {
                throw DecodingError.invalidCase
            }
            guard let pos = str.range(of: checksumMarker, options: .backwards)?.lowerBound else {
                throw DecodingError.noChecksumMarker
            }
            let intPos: Int = str.distance(from: str.startIndex, to: pos)
            guard intPos >= 1 else {
                throw DecodingError.incorrectHrpSize
            }
            guard intPos + 7 <= str.count else {
                throw DecodingError.incorrectChecksumSize
            }
            let vSize: Int = str.count - 1 - intPos
            var values: Data = Data(repeating: 0x00, count: vSize)
            for i in 0..<vSize {
                let c = strBytes[i + intPos + 1]
                let decInt = decCharset[Int(c)]
                if decInt == -1 {
                    throw DecodingError.invalidCharacter
                }
                values[i] = UInt8(decInt)
            }
            let hrp = String(str[..<pos]).lowercased()
            guard verifyChecksum(hrp: hrp, checksum: values) else {
                throw DecodingError.checksumMismatch
            }
            return (hrp, Data(values[..<(vSize-6)]))
        }
    
    func convertBits(data: [UInt8], fromBits: Int, toBits: Int, pad: Bool) throws -> [UInt8] {
        var acc: Int = 0
        var bits: Int = 0
        var out = [UInt8]()
        let maxv = (1 << toBits) - 1
        let maxAcc = Int(1 << (fromBits + toBits - 1)) - 1
        for i in 0..<data.count {
            let value = Int(data[Int(i)] & 0xFF)
            if (value >> fromBits) != 0 {
                assertionFailure()
            }
            acc = ((acc << fromBits) | value) & maxAcc
            bits += fromBits
            while bits >= toBits {
                bits -= toBits
                out.append(UInt8((acc >> bits) & maxv))
            }
        }
        
        let padding = pad && bits > 0 ? [acc << (toBits - Int(bits)) & maxv] : []
        
        if !pad && (bits >= fromBits || ((acc << (toBits - bits)) & maxv) > 0) {
            assertionFailure()
        }
        
        return out + padding.map({ return UInt8($0) })
    }
}

extension Bech32 {
    public enum DecodingError: LocalizedError {
        case nonUTF8String
        case nonPrintableCharacter
        case invalidCase
        case noChecksumMarker
        case incorrectHrpSize
        case incorrectChecksumSize
        case stringLengthExceeded
        
        case invalidCharacter
        case checksumMismatch
        
        public var errorDescription: String? {
            switch self {
            case .checksumMismatch:
                return "Checksum doesn't match"
            case .incorrectChecksumSize:
                return "Checksum size too low"
            case .incorrectHrpSize:
                return "Human-readable-part is too small or empty"
            case .invalidCase:
                return "String contains mixed case characters"
            case .invalidCharacter:
                return "Invalid character met on decoding"
            case .noChecksumMarker:
                return "Checksum delimiter not found"
            case .nonPrintableCharacter:
                return "Non printable character in input string"
            case .nonUTF8String:
                return "String cannot be decoded by utf8 decoder"
            case .stringLengthExceeded:
                return "Input string is too long"
            }
        }
    }
}
