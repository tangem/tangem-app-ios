//
//  StringExtensions.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Smart Cash AG. All rights reserved.
//

import Foundation

extension String: Error, LocalizedError {
    public var errorDescription: String? {
        return self
    }
}

public extension String {
    var cardFormatted: String {
        var resultString = ""
        for (index, character) in self.enumerated() {
            resultString.append(character)
            if index ==  3 || index == 7 || index == 11 {
                resultString.append(" ")
            }
        }
        return resultString
    }
    
    func trimZeroes() -> String {
        let reversed = self.reversed()
        if let latestNonZero = reversed.firstIndex(where: {$0 != "0"}) {
            let reversedSubstring = reversed[latestNonZero...]
            let normalSubstring = reversedSubstring.reversed()
            return String(normalSubstring)
        } else {
            return self
        }
    }
}
