//
//  String+.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

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
