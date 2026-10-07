//
//  YieldModuleClaimViewData.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI
import TangemAccounts

struct YieldModuleClaimViewData: Equatable {
    let total: String
    let sections: [Section]
}

struct YieldModuleClaimSuccessViewData: Equatable {
    let total: String
}

extension YieldModuleClaimViewData {
    struct Section: Identifiable, Equatable {
        let id: String
        let title: String
        let storage: Storage?
        let rewards: [Reward]
    }

    enum Storage: Equatable {
        case wallet(name: String)
        case account(name: String, icon: AccountIconView.ViewData)

        var name: String {
            switch self {
            case .wallet(let name), .account(let name, _):
                return name
            }
        }
    }

    struct Reward: Identifiable, Equatable {
        let id: String
        let iconInfo: TokenIconInfo
        let symbol: String
        let networkName: String
        let amount: String
        /// `nil` for rewards outside the claim total — no USD value is invented for them.
        let fiatAmount: String?
    }
}
