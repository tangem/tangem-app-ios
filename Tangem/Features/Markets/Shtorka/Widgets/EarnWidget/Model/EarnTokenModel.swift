//
//  EarnTokenModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets
import TangemLocalization

// MARK: - EarnTokenModel

struct EarnTokenModel: Identifiable, Hashable {
    let id: String
    let name: String
    let symbol: String
    let imageUrl: URL?
    let networkId: String
    let networkName: String
    let blockchainIconAsset: ImageType?
    let contractAddress: String?
    let decimalCount: Int?
    let rateValue: Decimal
    let rateType: RateType
    let rateText: String
    let earnType: EarnType
}

// MARK: - RateType

enum RateType: String, Hashable {
    case apy = "APY"
    case apr = "APR"

    /// Localized earn badge ("APY 5.00%"; the label travels with translations, e.g. German spells APR out).
    func earnBadgeText(percentText: String) -> String {
        switch self {
        case .apy: Localization.yieldModuleEarnBadge(percentText)
        case .apr: Localization.stakingAprEarnBadge(percentText)
        }
    }
}

// MARK: - EarnType

enum EarnType: String, Hashable {
    case staking = "Staking"
    case yieldMode = "Yield mode"
}
