//
//  Array+.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation
//extension Array where Element == CardTLV {
//    var bytes: [UInt8] {
//        return self.reduce([], { $0 + $1.bytes })
//    }
//}

extension Array where Element == Int {
    var bytes: [UInt8] {
        return self.map { return $0.byte }
    }
}

extension Array where Element == UInt8 {
    public var hexString: String {
        return self.map { return String(format: "%02X", $0) }.joined()
    }
    
    public var utf8String: String? {
        return String(bytes: self, encoding: .utf8)?.remove("\0")
    }
    
    public var intValue: Int? {
        return Int(from: self)
    }
    
    public var dateString: String {
        let hexYear = self[0].toAsciiHex() + self[1].toAsciiHex()
        
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
}
