//
//  Data+.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit

extension Data {
    public func toHexString() -> String {
        return self.map { return String(format: "%02X", $0) }.joined()
    }
    
    public func toUtf8String() -> String? {
        return String(bytes: self, encoding: .utf8)?.remove("\0")
    }
    
    public func toInt() -> Int? {
        return Int(lengthValue: self)
    }
    
    public func toDateString() -> String {
        let hexYear = self[0].toHex() + self[1].toHex()
        
        //Hex -> Int16
        let year = UInt16(hexYear.withCString {strtoul($0, nil, 16)})
        var mm = ""
        var dd = ""
        
        if (self[2] < 10) {
            mm = "0" + "\(self[2])"
        } else {
            mm = "\(self[2])"
        }
        
        if (self[3] < 10) {
            dd = "0" + "\(self[3])"
        } else {
            dd = "\(self[3])"
        }
        
        let components = DateComponents(year: Int(year), month: Int(self[2]), day: Int(self[3]))
        let calendar = Calendar(identifier: .gregorian)
        let date = calendar.date(from: components)
        
        let manFormatter = DateFormatter()
        manFormatter.dateStyle = DateFormatter.Style.medium
        if let date = date {
            let dateString = manFormatter.string(from: date)
            return dateString
        }
        
        return "\(year)" + "." + mm + "." + dd
    }
    
    public init(hex: String) {
        self = Data()
        reserveCapacity(hex.unicodeScalars.lazy.underestimatedCount)

        var buffer: UInt8?
        var skip = hex.hasPrefix("0x") ? 2 : 0
        for char in hex.unicodeScalars.lazy {
            guard skip == 0 else {
                skip -= 1
                continue
            }
            guard char.value >= 48 && char.value <= 102 else {
                removeAll()
                return
            }
            let v: UInt8
            let c: UInt8 = UInt8(char.value)
            switch c {
            case let c where c <= 57:
                v = c - 48
            case let c where c >= 65 && c <= 70:
                v = c - 55
            case let c where c >= 97:
                v = c - 87
            default:
                removeAll()
                return
            }
            if let b = buffer {
                append(b << 4 | v)
                buffer = nil
            } else {
                buffer = v
            }
        }
        if let b = buffer {
            append(b)
        }
    }
    
    @available(iOS 13.0, *)
    func sha256() -> Data {
        let digest = SHA256.hash(data: self)
        return Data(digest)
    }
    
    @available(iOS 13.0, *)
    func sha512() -> Data {
        let digest = SHA512.hash(data: self)
        return Data(digest)
    }
    
    var bytes: [Byte] {
        return Array(self)
    }
}
