//
//  String+.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
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
}
