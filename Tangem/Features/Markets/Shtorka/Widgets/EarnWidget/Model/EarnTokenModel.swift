//
//  EarnTokenModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - EarnTokenModel

struct EarnTokenModel: Identifiable, Hashable {
    let id: String
    let name: String
    let symbol: String
    let imageUrl: URL?
    let networkName: String
    let networkImageUrl: URL?
    let rateValue: Decimal
    let rateType: RateType
    let earnType: EarnType
}

// MARK: - RateType

enum RateType: String, Hashable {
    case apy = "APY"
    case apr = "APR"
}

// MARK: - EarnType

enum EarnType: String, Hashable {
    case staking = "Staking"
    case yieldMode = "Yield mode"
}
