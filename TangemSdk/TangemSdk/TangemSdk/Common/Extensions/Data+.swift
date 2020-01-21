//
//  Data+.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit
import CommonCrypto


extension Data {
    public func asHexString() -> String {
        return self.map { return String(format: "%02X", $0) }.joined()
    }
    
    public func toUtf8String() -> String? {
        return String(bytes: self, encoding: .utf8)?.remove("\0")
    }
    
    public func toInt() -> Int {
        return Int(hexData: self)
    }
    
    public func toDate() -> Date? {
        guard self.count >= 4 else { return nil }
        
        let year = Int(hexData: self[0...1])
        let month = Int(self[2])
        let day = Int(self[3])

        let components = DateComponents(year: year, month: month, day: day)
        let calendar = Calendar(identifier: .gregorian)
        return calendar.date(from: components)
    }
    
    public init(hexString: String) {
        self = Data()
        reserveCapacity(hexString.unicodeScalars.lazy.underestimatedCount)
        
        var buffer: UInt8?
        var skip = hexString.hasPrefix("0x") ? 2 : 0
        for char in hexString.unicodeScalars.lazy {
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
    
    public func getSha256() -> Data {
        if #available(iOS 13.0, *) {
            let digest = SHA256.hash(data: self)
            return Data(digest)
        } else {
           return sha256Old()
        }
    }
    
    public func getSha512() -> Data {
        if #available(iOS 13.0, *) {
            let digest = SHA512.hash(data: self)
            return Data(digest)
        } else {
           return sha512Old()
        }
    }
    
    public var toBytes: [Byte] {
        return Array(self)
    }
    
    func sha256Old() -> Data {
        guard let res = NSMutableData(length: Int(CC_SHA256_DIGEST_LENGTH)) else {
            return Data()
        }
        CC_SHA256((self as NSData).bytes, CC_LONG(count), res.mutableBytes.assumingMemoryBound(to: UInt8.self))
        return res as Data
    }
    
    func sha512Old() -> Data {
        guard let res = NSMutableData(length: Int(CC_SHA512_DIGEST_LENGTH)) else {
            return Data()
        }
        CC_SHA512((self as NSData).bytes, CC_LONG(count), res.mutableBytes.assumingMemoryBound(to: UInt8.self))
        return res as Data
    }
    
    func mapTlv<T>(tag: TlvTag) -> T? {
        guard let tlv = Tlv.deserialize(self) else{
            return nil
        }
        
        let mapper = TlvMapper(tlv: tlv)
        return try? mapper.map(tag)
    }
}
