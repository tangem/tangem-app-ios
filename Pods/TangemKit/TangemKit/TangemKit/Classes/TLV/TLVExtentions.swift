//
//  TLVExtentions.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation

extension Int {
    func toByteArray() -> [UInt8] {
        var moo = self
        var array = withUnsafePointer(to: &moo) {
            //return Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>($0), count: MemoryLayout<Int>.size))
            return $0.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout<Int>.size) {
                return Array(UnsafeBufferPointer(start: $0, count: MemoryLayout<Int>.size))
            }
        }
        array = array.reversed()

        guard let index = array.index(where: {$0 > 0}) else {
            return Array(array)
        }

        if index != array.endIndex-1 {
            return Array(array[index...array.endIndex-1])
        } else {
            return [array.last!]
        }
    }
}

extension UInt64 {
    func toByteArray() -> [UInt8] {
        var moo = self
        var array = withUnsafePointer(to: &moo) {
            //return Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>($0), count: MemoryLayout<UInt64>.size))
            return $0.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout<UInt64>.size) {
                return Array(UnsafeBufferPointer(start: $0, count: MemoryLayout<UInt64>.size))
            }
        }
        array = array.reversed()

        guard let index = array.index(where: {$0 > 0}) else {
            return Array(array)
        }

        if index != array.endIndex-1 {
            return Array(array[index...array.endIndex-1])
        } else {
            return [array.last!]
        }

    }
}

extension UInt8 {
    public func toAsciiHex() -> String {
        let temp = self
        return String(format: "%02X", temp)
    }

    func isConstructedTag() -> Bool {
        return ((self & 0x20) == 0x20)
    }
}

extension String {

    public func asciiHexToData() -> [UInt8]? {

        var trimmedString = self.trimmingCharacters(in: NSCharacterSet(charactersIn: "<> ") as CharacterSet).replacingOccurrences(of: " ", with: "")
        if trimmedString.count % 2 != 0 {
            trimmedString = "0" + trimmedString
        }

        guard isValidHex(trimmedString) else {
            return nil
        }

        var data = [UInt8]()
        var fromIndex = trimmedString.startIndex
        while let toIndex = trimmedString.index(fromIndex, offsetBy: 2, limitedBy: trimmedString.endIndex) {

            let byteString = String(trimmedString[fromIndex..<toIndex])
            let num = UInt8(byteString.withCString { strtoul($0, nil, 16) })
            data.append(num)

            fromIndex = toIndex
        }

        return data
    }

    func contains(find: String) -> Bool {
        return self.range(of: find) != nil
    }

    func containsIgnoringCase(find: String) -> Bool {
        return self.range(of: find, options: .caseInsensitive) != nil
    }

}

extension Data {

    init?(hexString: String) {
        let len = hexString.count / 2
        var data = Data(capacity: len)
        for i in 0..<len {
            let j = hexString.index(hexString.startIndex, offsetBy: i * 2)
            let k = hexString.index(j, offsetBy: 2)
            let bytes = hexString[j..<k]
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else {
                return nil
            }
        }
        self = data
    }

    init?(fromHexEncodedString string: String) {

        // Convert 0 ... 9, a ... f, A ...F to their decimal value,
        // return nil for all other input characters

        func decodeNibble(u: UInt16) -> UInt8? {
            switch (u) {
            case 0x30 ... 0x39:
                return UInt8(u - 0x30)
            case 0x41 ... 0x46:
                return UInt8(u - 0x41 + 10)
            case 0x61 ... 0x66:
                return UInt8(u - 0x61 + 10)
            default:
                return nil
            }
        }

        self.init(capacity: string.utf16.count/2)
        var even = true
        var byte: UInt8 = 0
        for c in string.utf16 {
            guard let val = decodeNibble(u: c) else { return nil }
            if even {
                byte = val << 4
            } else {
                byte += val
                self.append(byte)
            }
            even = !even
        }
        guard even else { return nil }
    }

    func hexEncodedString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }

    var hex: String {
        var string = ""

        enumerateBytes { pointer, index, _ in
            for i in index..<pointer.count {
                string += String(format: "%02x", pointer[i])
            }
        }

        return string
    }

}
