//
//  PortfolioReviewRoutable.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

@MainActor
protocol PortfolioReviewRoutable: AnyObject {
    func openTokenSummary(tokenItem: TokenItem, period: TokenSummaryPeriod)
    func openAddFunds(userWalletModels: [any UserWalletModel], preferredWalletId: UserWalletId?)
}
