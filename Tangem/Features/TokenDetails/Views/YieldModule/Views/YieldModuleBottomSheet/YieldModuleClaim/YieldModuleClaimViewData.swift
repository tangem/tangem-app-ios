//
//  YieldModuleClaimViewData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI

struct YieldModuleClaimViewData {
    let total: String
    let sections: [Section]
}

extension YieldModuleClaimViewData {
    struct Section: Identifiable {
        let id: String
        let title: String
        let rewards: [Reward]
    }

    struct Reward: Identifiable {
        let id: String
        let iconInfo: TokenIconInfo
        let symbol: String
        let networkName: String
        let amount: String
        /// `nil` for rewards outside the claim total — no USD value is invented for them.
        let fiatAmount: String?
    }
}
