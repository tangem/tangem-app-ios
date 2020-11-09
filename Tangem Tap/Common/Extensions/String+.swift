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
}
