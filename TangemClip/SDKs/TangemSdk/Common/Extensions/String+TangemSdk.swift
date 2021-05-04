//
//  String+.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

public extension String {
    func remove(_ substring: String) -> String {
        return self.replacingOccurrences(of: substring, with: "")
    }
    
    func sha256() -> Data {
        let data = Data(Array(utf8))
        return data.getSha256()
    }
    
    func sha512() -> Data {
        let data = Data(Array(utf8))
        return data.getSha512()
    }
    
    internal func capitalizingFirst() -> String {
        return prefix(1).capitalized + dropFirst()
    }
    
    internal func lowercasingFirst() -> String {
        return prefix(1).lowercased() + dropFirst()
    }
    
    internal var localized: String {
        Localization.getFormat(for: self)
    }
    
    internal func trim() -> String {
        return trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }
}

extension String {
    func contains(_ string: String, ignoreCase: Bool = true) -> Bool {
        return self.range(of: string, options: ignoreCase ? .caseInsensitive : []) != nil
    }
    
    public func stripHexPrefix() -> String {
        let prefix = "0x"

        if self.hasPrefix(prefix) {
            return String(self.dropFirst(prefix.count))
        }

        return self
    }
    
    func removeHexPrefix() -> String {
        return String(self[self.index(self.startIndex, offsetBy: 2)...])
    }
    
    var toUInt8: [UInt8] {
        let v = self.utf8CString.map({ UInt8($0) })
        return Array(v[0 ..< (v.count-1)])
    }
}

extension String: Error, LocalizedError {
    public var errorDescription: String? {
        return self
    }
}

extension DefaultStringInterpolation {
    mutating func appendInterpolation(_ data: Data) {
        appendLiteral(data.asHexString())
    }
    
    mutating func appendInterpolation(_ byte: Byte) {
        appendLiteral(byte.asHexString())
    }
}

extension StringProtocol {
    var drop0xPrefix: SubSequence { hasPrefix("0x") ? dropFirst(2) : self[...] }
    var hexToInteger: Int? { Int(drop0xPrefix, radix: 16) }
    var integerToHex: String { .init(Int(self) ?? 0, radix: 16) }
}
