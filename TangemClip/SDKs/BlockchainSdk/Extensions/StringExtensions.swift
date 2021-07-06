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
}

extension String: Error, LocalizedError {
    public var errorDescription: String? {
        return self
    }
}
