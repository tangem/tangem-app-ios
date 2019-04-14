//
//  PBHex.swift
//  PBKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2017年 pebble8888. All rights reserved.
//
import Foundation

public protocol HexRepresentable {
    func hexDescription() -> String
}

extension UInt8 : HexRepresentable
{
    public func hexDescription() -> String {
        return String(format:"%02x", self)
    }
}

extension Int32 : HexRepresentable
{
    public func hexDescription() -> String
    {
        return String(format:"%08x", self)
    }
}

extension UInt32 : HexRepresentable
{
    public func hexDescription() -> String {
        return String(format:"%08x", self)
    }
}

//extension String {
//    public func unhexlify() -> [UInt8] {
//        var pos = startIndex
//        return (0..<self.count/2).compactMap { _ in
//            defer { pos = index(pos, offsetBy: 2) }
//            return UInt8(self[pos...index(after: pos)], radix: 16)
//        }
//    }
//}

extension Collection where Iterator.Element : HexRepresentable {
    public func hexDescription(separator: String = "") -> String {
        return self.map({ $0.hexDescription() }).joined(separator: separator)
    }
}

extension Collection where Iterator.Element == UInt8 {
    public func utf8Description() -> String {
        guard let s = String(bytes: self, encoding: .utf8) else {
            return ""
        }
        return s
    }
}

extension Array where Element == UInt8 {
    public var description: String {
        return hexDescription()
    }
}

extension Data : HexRepresentable {
    public func hexDescription() -> String {
        return self.map({ String(format:"%02x", $0) }).joined()
    }
}

extension String {
    // hex string to data
    public func hexData() -> Data? {
        var data = Data(capacity: self.count / 2)
        
        let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
        regex.enumerateMatches(in: self, range: NSMakeRange(0, utf16.count)) { match, flags, stop in
            let byteString = (self as NSString).substring(with: match!.range)
            var num = UInt8(byteString, radix: 16)!
            data.append(&num, count: 1)
        }
        
        guard data.count > 0 else { return nil }
        
        return data
    }
    
    public func toUnicodeScalar() -> UnicodeScalar? {
        var u:UnicodeScalar?
        let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,}", options: .caseInsensitive)
        regex.enumerateMatches(in: self, range: NSMakeRange(0, self.utf8.count)){ match, flags, stop in
            let byteString = (self as NSString).substring(with: match!.range)
            let num = UInt32(byteString, radix: 16)!
            u = UnicodeScalar(num)
        }
        return u
    }
    
}
