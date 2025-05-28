//
//  FiatItem.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

struct FiatItem: Hashable {
    let currencyCode: String
    let fractionDigits: Int

    init(currencyCode: String, fractionDigits: Int = 2) {
        self.currencyCode = currencyCode
        self.fractionDigits = fractionDigits
    }
}
