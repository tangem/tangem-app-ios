//
//  ThenProcessable.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

protocol ThenProcessable {}

extension ThenProcessable where Self: Any {
    func then(_ block: (inout Self) throws -> Void) rethrows -> Self {
        var copy = self
        try block(&copy)

        return copy
    }
}
