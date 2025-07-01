//
//  FiatItem.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct FiatItem: Hashable {
    let iconURL: URL?
    let currencyCode: String
    let fractionDigits: Int

    init(iconURL: URL?, currencyCode: String, fractionDigits: Int = 2) {
        self.iconURL = iconURL
        self.currencyCode = currencyCode
        self.fractionDigits = fractionDigits
    }
}
