//
//  String+.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    internal func localized(_ arguments: CVarArg) -> String {
        return String(format: localized, arguments)
    }
    
    func removeLatestSlash() -> String {
        if self.last == "/" {
            return String(self.dropLast())
        }
        
        return self
    }
    
    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }

    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
    
    func remove(contentsOf strings: [String]) -> String {
        strings.reduce(into: self, {
            $0 = $0.remove($1)
        })
    }
    
    func trimmed() -> String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
}

extension StringProtocol {
    var drop0xPrefix: SubSequence { hasPrefix("0x") ? dropFirst(2) : self[...] }
    var hexToInteger: Int? { Int(drop0xPrefix, radix: 16) }
    var integerToHex: String { .init(Int(self) ?? 0, radix: 16) }
}
