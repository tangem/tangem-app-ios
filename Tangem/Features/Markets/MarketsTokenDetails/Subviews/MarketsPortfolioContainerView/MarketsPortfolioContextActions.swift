//
//  MarketsPortfolioContextActions.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

protocol MarketsPortfolioContextActionsProvider: AnyObject {
    func buildContextActions(tokenItem: TokenItem, walletModelId: WalletModelId, userWalletId: UserWalletId) -> [TokenActionType]
}
