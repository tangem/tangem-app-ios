//
//  FeedSearchPortfolioMatcher.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct FeedSearchPortfolioMatcher {
    func matches(query: String, walletModels: [any WalletModel]) -> [any WalletModel] {
        guard query.isNotEmpty else {
            return []
        }

        return walletModels.filter { walletModel in
            let item = walletModel.tokenItem
            return item.name.caseInsensitiveContains(query) || item.currencySymbol.caseInsensitiveContains(query)
        }
    }
}
