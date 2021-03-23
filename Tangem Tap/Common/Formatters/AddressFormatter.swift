//
//  AddressFormatter.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

struct AddressFormatter {
    let address: String

    init(address: String) {
        self.address = address
    }
    
    func truncated(prefixLimit: Int = 7, suffixLimit: Int = 4, delimiter: String = "...") -> String {
        if address.count <= prefixLimit + suffixLimit + delimiter.count {
            return address
        }
        
        return "\(address.prefix(prefixLimit))\(delimiter)\(address.suffix(suffixLimit))"
    }
    
}
