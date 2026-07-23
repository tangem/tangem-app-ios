//
//  EarnOpportunitiesMapper+Model.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemUI

extension EarnOpportunitiesMapper {
    struct AccountCandidate: Equatable {
        let id: String
        let name: String
        let icon: AccountModel.CompositeIcon
        let holdings: [HoldingCandidate]

        var potentialReward: Decimal {
            holdings.sum(by: \.potentialReward)
        }
    }

    struct HoldingCandidate: Equatable {
        let id: String
        let assetKey: AssetKey
        let tokenIconInfo: TokenIconInfo
        let currencyName: String
        let networkName: String
        let cryptoBalance: Decimal?
        let fiatBalance: Decimal?
        let apyInfo: EarnApyInfo

        /// Crypto balance, not fiat — a held token may have no rate.
        var isEarnEligible: Bool {
            (cryptoBalance ?? 0) > 0 || apyInfo.isActive
        }

        var potentialReward: Decimal {
            (fiatBalance ?? 0) * apyInfo.apy
        }
    }

    /// Match key: same asset on the same network.
    struct AssetKey: Hashable {
        let currencyId, networkId: String
    }

    /// Fetch outcome; loading and empty render differently.
    enum SuggestionsState: Equatable {
        case loading
        case loaded([EarnTokenModel])
        case failed
    }
}
