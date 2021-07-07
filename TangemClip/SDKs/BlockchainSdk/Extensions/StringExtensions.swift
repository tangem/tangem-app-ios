//
//  String+.swift
//  TangemClip
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation

extension String {
    func removeHexPrefix() -> String {
        return String(self[self.index(self.startIndex, offsetBy: 2)...])
    }
    
    func stripHexPrefix() -> String {
        let prefix = "0x"
        
        if self.hasPrefix(prefix) {
            return String(self.dropFirst(prefix.count))
        }
        
        return self
    }
    
    var toUInt8: [UInt8] {
        let v = self.utf8CString.map({ UInt8($0) })
        return Array(v[0 ..< (v.count-1)])
    }
    
    static var unknown: String {
        "Unknown"
    }
}

extension String: Error, LocalizedError {
    public var errorDescription: String? {
        return self
    }
}
