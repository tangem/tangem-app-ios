//
//  MarketsTokenSearchRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

@MainActor
protocol MarketsTokenSearchRoutable: AnyObject {
    func openMarketsTokenDetails(for tokenInfo: MarketsTokenModel)

    func openPortfolioTokenDetails(
        userWalletModel: UserWalletModel,
        accountModel: any CryptoAccountModel,
        walletModel: any WalletModel
    )

    func openPortfolioTokenList(
        walletModels: [any WalletModel],
        onSelect: @escaping (any WalletModel) -> Void
    )
}
