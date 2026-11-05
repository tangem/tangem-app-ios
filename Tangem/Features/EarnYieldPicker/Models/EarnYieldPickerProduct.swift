//
//  EarnYieldPickerProduct.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct EarnYieldPickerProduct: Identifiable, Equatable {
    let id: Kind
    let name: String
    let apy: Decimal
    let incentiveApy: Decimal?
    let performanceFee: Decimal
    let description: String
    let details: EarnProductDetails

    enum Kind: Hashable {
        case pooledStaking
        case lendingOnAave
    }
}
