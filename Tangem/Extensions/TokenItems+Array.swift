//
//  TokenItems+Array.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

extension Array where Element == TokenItem {
    mutating func remove(_ tokenItem: TokenItem) {
        if let index = firstIndex(where: { $0 == tokenItem }) {
            remove(at: index)
        }
    }
}
