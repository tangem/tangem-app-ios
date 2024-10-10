//
//  MarketsPortfolioContextActions.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol MarketsPortfolioContextActionsProvider: AnyObject {
    func buildContextActions(tokenItem: TokenItem, walletModelId: WalletModelId, userWalletId: UserWalletId) -> [TokenActionType]
}

protocol MarketsPortfolioContextActionsDelegate: AnyObject {
    func showContextAction(for viewModel: MarketsPortfolioTokenItemViewModel)
    func didTapContextAction(_ action: TokenActionType, walletModelId: WalletModelId, userWalletId: UserWalletId)
}
