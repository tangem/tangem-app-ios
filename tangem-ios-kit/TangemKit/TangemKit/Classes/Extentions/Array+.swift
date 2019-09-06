//
//  Array+.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Smart Cash AG. All rights reserved.
//

import Foundation
extension Array where Element == CardTLV {
    var bytes: [UInt8] {
        return self.reduce([], { $0 + $1.bytes })
    }
}

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
        return String(bytes: self, encoding: .utf8)
    }
    
    public var intValue: Int? {
         return Int(from: self)
    }
}
