//
//  PolymarketWithdrawSourceWalletsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

struct PolymarketWithdrawSourceWalletsProvider: TokenSelectorWalletsProvider {
    let userWalletInfo: UserWalletInfo
    let source: PolymarketWithdrawSource

    var wallets: [TokenSelectorWallet] {
        [
            TokenSelectorWallet(
                wallet: userWalletInfo,
                accounts: .single(makePolymarketAccountSection())
            ),
        ]
    }
}

// MARK: - The prediction account section

private extension PolymarketWithdrawSourceWalletsProvider {
    func makePolymarketAccountSection() -> TokenSelectorAccount {
        let item = TokenSelectorItem(userWalletInfo: userWalletInfo, kind: .polymarket(source))

        return TokenSelectorAccount(
            account: source.accountModel,
            itemsProvider: StaticTokenSelectorItemsProvider(items: [item]),
            rateProvider: nil
        )
    }
}
